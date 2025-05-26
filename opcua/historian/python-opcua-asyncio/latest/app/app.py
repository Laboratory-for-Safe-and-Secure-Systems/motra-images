import argparse
import asyncio
import aiosqlite
import logging

from asyncua import Client
from asyncua.common.subscription import SubscriptionHandler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# global queue to buffer incoming updates
value_queue = asyncio.Queue()

# custom namespace
DEFAULT_NAMESPACE = 1

# maps node paths to db table
NODE_CONFIGS = [
    ("{0}:Devices/{0}:Sensors/{0}:S001/{0}:Measurement/{0}:FillLevel/{0}:Percent".format(
        DEFAULT_NAMESPACE), "tank_water_level", "pct"),
    ("{0}:Devices/{0}:Valves/{0}:V001/{0}:Output/{0}:D1/{0}:Active".format(
        DEFAULT_NAMESPACE), "chemical_valve_pos", "position"),
    ("{0}:Devices/{0}:Tanks/{0}:T001/{0}:Configuration/{0}:MaxLevelPercent".format(
        DEFAULT_NAMESPACE), "upper_limit", "pct"),
    ("{0}:Devices/{0}:Tanks/{0}:T001/{0}:Configuration/{0}:MinLevelPercent".format(
        DEFAULT_NAMESPACE), "lower_limit", "pct"),
]

# maps node ids to db table after requesting them
nodeid_to_config = {}

# task 1/2 writes to db from queue
async def db_writer_task(database: str):
    async with aiosqlite.connect(database) as db:
        logger.info(f"Connected to database")
        try:
            while True:
                (table, col), value = await value_queue.get()
                await db.execute(f"INSERT INTO {table} ({col}) VALUES (?)", (value,))
                await db.commit()
        except asyncio.TimeoutError as e:
            logger.error(f"Timeout error during write: {e}. Skipping...")

# called when new value is written to server
class SubscriptionHandler:
    def datachange_notification(self, node, value, data):
        if value:
            value_queue.put_nowait((nodeid_to_config[node], value))

# task 2/2 which subscribes to server
async def client_task(server_uri: str):
    # auto-reconnect to server in any case
    while True:
        try:
            logger.info(f"Connecting to {server_uri}")
            async with Client(url=server_uri) as client:
                # Resolve NodeIds from browse paths
                nodes = []
                for path, table, col in NODE_CONFIGS:
                    try:
                        node = await client.nodes.objects.get_child(path)
                        logger.info(f"Resolved {path} -> {node.nodeid}")
                        nodes.append(node)
                        nodeid_to_config[node] = (table, col)
                    except Exception as e:
                        logger.error(f"Failed to resolve {path}: {e}")

                # create subscription
                handler = SubscriptionHandler()
                subscription = await client.create_subscription(1000, handler)
                await subscription.subscribe_data_change(nodes)
                logger.info(f"Subscribed to {len(nodes)} nodes. Monitoring...")

                # do nothing after subscription
                while True:
                    await asyncio.sleep(1)

        except Exception as e:
            logger.warning(f"Connection failed: {e}. Retrying in 2 seconds...")
            await asyncio.sleep(2)

# start both tasks
async def main(server_uri: str, database: str):
    await asyncio.gather(client_task(server_uri), db_writer_task(database))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='OPC UA historian client')
    parser.add_argument('-s', '--suri', type=str,
                        default='opc.tcp://127.0.0.1:4840',
                        help='OPC UA server endpoint URI [default: opc.tcp://127.0.0.1:4840]')
    parser.add_argument('-d', '--database', type=str,
                        default='/db.sqlite3',
                        help='SQLite database [default: /db.sqlite3]')
    args = parser.parse_args()

    asyncio.run(main(args.suri, args.database))
