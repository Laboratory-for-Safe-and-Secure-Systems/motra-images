import argparse
import asyncio
import logging
import threading
from collections import deque

from asyncua import Client
from asyncua.common.subscription import SubscriptionHandler

from bidict import bidict

import dash
from dash import dcc, html
from dash.dependencies import Input, Output, State
import plotly.graph_objs as go

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# queue for buffering setter requests received from dashboard
# contains tuples with (nodeid, value)
setter_queue = asyncio.Queue()

# TODO: add the other nodes
# maps node paths to deques
# the deques buffer a number of maxlen values for the visualization
node_buffers = {
    f"1:TankV001/1:Measurement/1:FillLevel/1:Percent": deque(maxlen=100),
}

# TODO: min max level should belong to tank, but not yet implemented
# TODO: also not writable
# list of setable nodes
settable_nodes = [
    f"1:TankV001/1:Measurement/1:FillLevel/1:Absolute",
]

# maps path to resolved nodeids
path_to_nodeid = bidict()

# called when new value is written to server
class SubscriptionHandler:
    def datachange_notification(self, node, val, data):
        ts = data.monitored_item.Value.SourceTimestamp
        node_buffers[path_to_nodeid.inverse[node]].append((ts, val))

# task which subscribes to server
async def main(server_uri: str):
    # auto-reconnect to server in any case
    while True:
        try:
            logger.info(f"[INFO] Connecting to {server_uri}")
            async with Client(url=server_uri) as client:

                # TODO: enable this and make it configurable
                # set security
                # await client.set_security(
                #     SecurityPolicyBasic256Sha256,
                #     certificate='/pki/cert.der',
                #     private_key='/pki/key.pem',
                #     mode=MessageSecurityMode.SignAndEncrypt)
 
                # Resolve NodeIds from browse paths
                nodes = []
                for path in list(node_buffers) + settable_nodes:
                    try:
                        node = await client.nodes.objects.get_child(path)
                        logger.info(f"[INFO] Resolved {'/'.join(path)} -> {node.nodeid}")
                        # only subscribe if it has a buffer attached
                        if path in node_buffers:
                            nodes.append(node)
                        path_to_nodeid[path] = node
                    except Exception as e:
                        logger.error(f"[ERROR] Failed to resolve {'/'.join(path)}: {e}")

                # create subscription
                handler = SubscriptionHandler()
                subscription = await client.create_subscription(1000, handler)
                await subscription.subscribe_data_change(nodes)
                logger.info(f"[INFO] Subscribed to {len(nodes)} nodes. Monitoring...")

                # wait for set signals and write them
                while True:
                    nodeid, value = await setter_queue.get()
                    await nodeid.write_value(value)

        except Exception as e:
            logger.warning(f"[WARN] Connection failed: {e}. Retrying in 2 seconds...")
            await asyncio.sleep(2)

def start_visualization():
    app = dash.Dash(__name__)
    signal_names = [name for name in node_buffers]

    # define layout of webpage
    app.layout = html.Div([
        html.H2("OPC UA Headunit"),

        # display signals graphically section
        html.Div([
            html.H4("Display signal"),

            html.Label("Select signal"),
            dcc.Dropdown(
                id="signal-dropdown",
                options=[{"label": name, "value": name} for name in signal_names],
                value=signal_names[0]
            ),
        ]),

        dcc.Graph(id="live-graph"),
        dcc.Interval(id="update-interval", interval=1000, n_intervals=0),

        html.Hr(),

        # variable setting section
        html.Div([
            html.H4("Set value"),

            html.Label("Select signal"),
            dcc.Dropdown(
                id="setter-dropdown",
                options=[{"label": name, "value": name} for name in settable_nodes],
                value=settable_nodes[0]
            ),

            dcc.Input(id="set-value-input", type="number", placeholder="Enter new value"),
            html.Button("Set", id="set-button", n_clicks=0),
            html.Div(id="set-output")
        ])
    ])

    # callback for setting new values on the server
    @app.callback(
        Output("set-output", "children"),
        Input("set-button", "n_clicks"),
        State("setter-dropdown", "value"),
        State("set-value-input", "value"),
    )
    def set_value(n_clicks, selected_signal, value):
        if n_clicks > 0 and value is not None:
            # we do the lookup here to keep the main loop as free as possible
            setter_queue.put_nowait((path_to_nodeid[selected_signal], value))
            return f"Requested to set {selected_signal} to {value}"
        return ""

    # callback for updating the temporal progression graph
    @app.callback(
        Output("live-graph", "figure"),     # 
        Input("update-interval", "n_intervals"),
        Input("signal-dropdown", "value")
    )
    def update_graph(n, signal):
        points = list(node_buffers.get(signal, []))
        if not points:
            return dash.no_update

        timestamps, values = zip(*points)
        return {
            "data": [go.Scatter(x=timestamps, y=values, mode="lines+markers")],
            "layout": go.Layout(
                title=f"Live Plot: {signal}",
                xaxis=dict(title="Time", tickformat="%H:%M:%S"),
                yaxis=dict(title="Value", range=[0, 100]))
        }

    app.run(host="0.0.0.0", debug=False, use_reloader=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='OPC UA headunit')
    parser.add_argument('-s', '--suri', type=str,
                        default='opc.tcp://127.0.0.1:4840',
                        help='OPC UA server endpoint URI [default: opc.tcp://127.0.0.1:4840]')
    args = parser.parse_args()

    dash_thread = threading.Thread(target=start_visualization, daemon=True)
    dash_thread.start()

    asyncio.run(main(args.suri))
