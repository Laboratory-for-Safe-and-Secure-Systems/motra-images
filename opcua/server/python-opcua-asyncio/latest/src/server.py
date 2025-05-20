import os.path
import asyncio
import logging
import random

import argparse

from asyncua import ua, Server
from asyncua.common.instantiate_util import instantiate
# from asyncua.crypto.permission_rules import User, UserRole


# Dummy user manager (replace with a proper implementation)
# user_manager = {
#     "admin": User(
#         username="admin",
#         password="password123",
#         roles=[UserRole.Admin] # Or define custom roles with permissions
#     ),
#      "reader": User(
#         username="reader",
#         password="password",
#         roles=[UserRole.Observer] # Built-in Observer role is typically read-only
#     )
# }

# Dummy user manager - REPLACE with your actual logic
# This manager allows 'user1' with 'password' to do anything (including write)
# Anonymous users might still be restricted depending on server defaults
class TestUserManager:
    def get_user(self, iserver, username=None, password=None, certificate=None):
        """
        Default user_manager, does nothing much but check for admin
        """
        print(f"Client authentication attempt: user='{username}'") # Add logging

        if username == "user1" and password == "password":
            # Grant broad permissions - customize roles/groups for finer control
            # isession.user = Server.User(role="Admin") # Example role concept
            print(f"Authentication SUCCESSFUL for user: {username}")
            return User(role=UserRole.Admin) # Allow login

        print(f"Authentication FAILED for user: {username}")
        return User(role=UserRole.User) # Deny login for others
    
        # if username and iserver.allow_remote_admin and username in ("admin", "Admin"):
        #     return User(role=UserRole.Admin)
        # else:
        #     return User(role=UserRole.User)
        

class Kritis3mServer:
    def __init__(self, endpoint, name, model_filepath):
        self.userman = TestUserManager()

        # self.server = Server(user_manager=self.userman)
        self.server = Server()

        self.model_filepath = model_filepath
        self.server.set_server_name(name)
        self.server.set_endpoint(endpoint)
        logging.basicConfig(level=logging.INFO)


    async def init(self):
        await self.server.init()
        await self.server.set_application_uri("urn:open62541.server.application")

        #  This need to be imported at the start or else it will overwrite the data
        # await self.server.import_xml("/schemas/UA-Nodeset/Schema/Opc.Ua.NodeSet2.xml")
        # await self.server.import_xml("/schemas/Opc.Ua.Di.NodeSet2.xml")
        await self.server.import_xml(os.path.join(self.model_filepath, "Server.NodeSet2.xml"))

        await self.server.register_namespace("urn:open62541.server.application")

        # self.device = await instantiate(
        #     self.server.nodes.objects,
        #     await self.server.nodes.base_object_type.get_child("1:GenericWaterTankType"),
        #     bname="test_Server_OPC_UA",
        #     dname=ua.LocalizedText("Test Tank"),
        #     idx=1,
        #     instantiate_optional=False,
        # )

    async def __aenter__(self):
        await self.init()
        self.server.set_security_policy(security_policy = [
                            ua.SecurityPolicyType.NoSecurity,
                            ua.SecurityPolicyType.Basic256Sha256_SignAndEncrypt,
                            ua.SecurityPolicyType.Basic256Sha256_Sign
                                ])
        await self.server.start()
        return self.server

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.server.stop()

async def main():

    script_dir = os.path.dirname(__file__)
    async with Kritis3mServer(
        "opc.tcp://0.0.0.0:4840/KRITIS3M/",
        "KRITIS3M Sample Server",
        script_dir,
    ) as server:
        while True:
            await asyncio.sleep(1)
            a, b = random.randint(0, 5), random.randint(0, 4)
            # Update variables
            # await server.get_node("ns=4;i=7830").write_value(a)  # CurrentMode
            # await server.get_node("ns=4;i=7831").write_value(b)  # CurrentState
            await asyncio.sleep(5)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())