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

# TODO: add the other nodes
# maps node paths to db table
NODE_CONFIGS = [
    (f"2:TankV001/2:Measurement/2:FillLevel/2:Percent", "tank_water_level"),
]

# maps node ids to db table after requesting them
nodeid_to_table = {}

# called when new value is written to server
class SubscriptionHandler:
    def datachange_notification(self, node, val, data):
        # probably not necessary if insert ts == handler ts
        # ts = data.monitored_item.Value.SourceTimestamp
        # TODO: use this line instead of the current one
        # TODO: current server request return None value which is forbidden
        # value_queue.put_nowait((nodeid_to_table[node], val))
        value_queue.put_nowait((nodeid_to_table[node], 7))

# task 1/2 writes to db from queue
async def db_writer_task(database: str):
    async with aiosqlite.connect(database) as db:
        logger.info(f"[INFO] Connected to database")
        try:
            while True:
                table, value = await value_queue.get()
                logger.info(f"[INFO]: Insert {value} into {table}")
                await db.execute(f"INSERT INTO {table} (pct) VALUES (?)", (value,))
                await db.commit()
        except asyncio.TimeoutError as e:
            logger.error(f"[ERROR] Timeout error during write: {e}. Skipping...")

# task 2/2 which subscribes to server
async def client_task(server_uri: str):
    # auto-reconnect to server in any case
    while True:
        try:
            logger.info(f"[INFO] Connecting to {server_uri}")
            async with Client(url=server_uri) as client:
                # Resolve NodeIds from browse paths
                nodes = []
                for path, table in NODE_CONFIGS:
                    try:
                        node = await client.nodes.objects.get_child(path)
                        logger.info(f"[INFO] Resolved {'/'.join(path)} -> {node.nodeid}")
                        nodes.append(node)
                        nodeid_to_table[node] = table
                    except Exception as e:
                        logger.error(f"[ERROR] Failed to resolve {'/'.join(path)}: {e}")

                # create subscription
                handler = SubscriptionHandler()
                subscription = await client.create_subscription(1000, handler)
                await subscription.subscribe_data_change(nodes)
                logger.info(f"[INFO] Subscribed to {len(nodes)} nodes. Monitoring...")

                # do nothing after subscription
                while True:
                    await asyncio.sleep(1)

        except Exception as e:
            logger.warning(f"[WARN] Connection failed: {e}. Retrying in 2 seconds...")
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
