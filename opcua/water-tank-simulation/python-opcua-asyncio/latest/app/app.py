import argparse
import asyncio
import logging

from asyncua import Client
from pump import Pump
from tank import Tank

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def main(server_uri: str):
    sim_step = .1
    static_outflow = 40

    tank1 = Tank(name = 'tank1',
                 volume_m3 = 1000,
                 height_mm = 5000,
                 max_lvl_mm = 4500, 
                 min_lvl_mm = 600, 
                 lvl_mm = 3900, 
                 sim_step_s=sim_step)

    pump1 = Pump(name='pump1',
                 nominal_flow_rate_lps = 60,
                 sim_step = sim_step)

    # auto-reconnect to server in any case
    while True:
        try:
            logger.info(f"[INFO] Connecting to {server_uri}")
            async with Client(url=server_uri) as client:
                # Resolve fill level NodeId from browse path
                node = await client.nodes.objects.get_child(
                    "1:TankV001/1:Measurement/1:FillLevel/1:Percent")
                logger.info(f"[INFO] Resolved fill level percentage to {node.nodeid}")

                while True:
                    # Start timer to ensure minimal loop time of sim_step
                    waiting_task = asyncio.create_task(asyncio.sleep(sim_step))

                    # Logic that runs concurrently
                    if tank1.lvl_mm >= tank1.max_lvl_mm and pump1.pump_on == True:
                        pump1.pump_on = False

                    if tank1.lvl_mm <= tank1.min_lvl_mm and pump1.pump_on == False:
                        pump1.pump_on = True

                    measured_flow = pump1.get_flow()
                    tank1.calculate_new_fill_level([measured_flow], [static_outflow])
                    logger.info(f"[INFO] Writing to server with value {tank1.fill_pct}")
                    await node.write_value(tank1.fill_pct)

                    # Ensure minimal loop time
                    await waiting_task

        except Exception as e:
            logger.warning(f"[WARN] Connection failed: {e}. Retrying in 2 seconds...")
            await asyncio.sleep(2)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Watertank simulation with OPC UA client')
    parser.add_argument('-s', '--suri', type=str,
                        default='opc.tcp://127.0.0.1:4840',
                        help='OPC UA PLC server endpoint URI [default: opc.tcp://127.0.0.1:4840]')
    args = parser.parse_args()

    asyncio.run(main(args.suri))
