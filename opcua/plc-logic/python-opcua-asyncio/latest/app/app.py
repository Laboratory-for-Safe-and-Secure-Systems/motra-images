import argparse
import asyncio
import logging

from asyncua import Client
from asyncua.common.subscription import SubscriptionHandler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# global queue to buffer incoming updates
value_queue = asyncio.Queue()

# custom namespace
DEFAULT_NAMESPACE = 1

# node paths on lss
LSS_FILL_LEVEL_PATH = "{0}:Devices/{0}:Sensors/{0}:S001/{0}:Measurement/{0}:FillLevel/{0}:Percent".format(
                      DEFAULT_NAMESPACE)

# node paths on vs
VS_VALVE_POS_PATH = "{0}:Devices/{0}:Valves/{0}:V001/{0}:Output/{0}:D1/{0}:Active".format(
                    DEFAULT_NAMESPACE)

# node paths on ps
PS_UPPER_LIMIT_PATH = "{0}:Devices/{0}:Tanks/{0}:T001/{0}:Configuration/{0}:MaxLevelPercent".format(
        DEFAULT_NAMESPACE)
PS_LOWER_LIMIT_PATH = "{0}:Devices/{0}:Tanks/{0}:T001/{0}:Configuration/{0}:MinLevelPercent".format(
        DEFAULT_NAMESPACE)

PS_FILL_LEVEL_PATH = "{0}:Devices/{0}:Sensors/{0}:S001/{0}:Measurement/{0}:FillLevel/{0}:Percent".format(
                     DEFAULT_NAMESPACE)
PS_VALVE_POS_PATH = "{0}:Devices/{0}:Valves/{0}:V001/{0}:Output/{0}:D1/{0}:Active".format(
                    DEFAULT_NAMESPACE)

# task 1/2 evaluates value changes and contains logic
async def eval_task(vs_uri: str, ps_uri: str):
    # auto-reconnect to servers written to
    while True:
        try:
            logger.info(f"Connecting to {vs_uri} and {ps_uri}")
            async with Client(url=vs_uri) as vs_client, \
                       Client(url=ps_uri) as ps_client:
                # Resolve the NodeIds from browse paths
                vs_valve_pos = await vs_client.nodes.objects.get_child(VS_VALVE_POS_PATH)
                ps_upper_limit = await ps_client.nodes.objects.get_child(PS_UPPER_LIMIT_PATH)
                ps_lower_limit = await ps_client.nodes.objects.get_child(PS_LOWER_LIMIT_PATH)
                ps_fill_level = await ps_client.nodes.objects.get_child(PS_FILL_LEVEL_PATH)
                ps_valve_pos = await ps_client.nodes.objects.get_child(PS_VALVE_POS_PATH)

                # wait for new values pushed to the queue
                while True:
                    new_fill_level = await value_queue.get()

                    # first update the fill level variable on the PLC server
                    await ps_fill_level.write_value(new_fill_level)
        
                    # get latest values needed for calculations from PLC and valve servers
                    upper_limit, lower_limit = await ps_client.read_values([
                        ps_upper_limit,
                        ps_lower_limit])
                    valve_pos = await vs_valve_pos.read_value() # 1: open 0: closed

                    # open valve if it is closed and enough water is in the tank
                    if not valve_pos and new_fill_level >= upper_limit:
                        await ps_valve_pos.write_value(True)
                        await vs_valve_pos.write_value(True)
        
                    # and close valve if it is open and not enough water is left in the tank
                    elif valve_pos and new_fill_level <= lower_limit:
                        await ps_valve_pos.write_value(False)
                        await vs_valve_pos.write_value(False)

        except Exception as e:
            logger.warning(f"Connection failed: {e}. Retrying in 2 seconds...")
            await asyncio.sleep(2)


# called when new value is written to server
class SubscriptionHandler:
    async def datachange_notification(self, node, value, data):
        if value:
            value_queue.put_nowait(value)

# task 2/2 which subscribes to water level changes
async def client_task(lss_uri: str):
    # auto-reconnect to server in any case
    while True:
        try:
            logger.info(f"Connecting to {lss_uri}")
            async with Client(url=lss_uri) as lss_client:
                nodes = []
                # Resolve NodeIds from browse paths
                try:
                    node = await lss_client.nodes.objects.get_child(
                        LSS_FILL_LEVEL_PATH)
                    logger.info(f"Resolved {LSS_FILL_LEVEL_PATH} -> {node.nodeid}")
                    nodes.append(node)
                except Exception as e:
                    logger.error(f"Failed to resolve {LSS_FILL_LEVEL_PATH}: {e}")

                # create subscription
                handler = SubscriptionHandler()
                subscription = await lss_client.create_subscription(1000, handler)
                await subscription.subscribe_data_change(nodes)
                logger.info(f"Subscribed to {len(nodes)} nodes. Monitoring...")

                # do nothing after subscription
                while True:
                    await asyncio.sleep(1)

        except Exception as e:
            logger.warning(f"Connection failed: {e}. Retrying in 2 seconds...")
            await asyncio.sleep(2)

# start both tasks
async def main(lss_uri: str, vs_uri: str, ps_uri: str):
    await asyncio.gather(client_task(lss_uri), eval_task(vs_uri, ps_uri))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='OPC UA historian client')
    parser.add_argument('-l', '--lss', type=str,
                        default='opc.tcp://127.0.0.1:4840',
                        help='OPC UA level sensor server endpoint URI [default: opc.tcp://127.0.0.1:4840]')
    parser.add_argument('-v', '--vs', type=str,
                        default='opc.tcp://127.0.0.1:4840',
                        help='OPC UA valve server endpoint URI [default: opc.tcp://127.0.0.1:4840]')
    parser.add_argument('-p', '--ps', type=str,
                        default='opc.tcp://127.0.0.1:4840',
                        help='OPC UA PLC server endpoint URI [default: opc.tcp://127.0.0.1:4840]')
    args = parser.parse_args()

    asyncio.run(main(args.lss, args.vs, args.ps))
