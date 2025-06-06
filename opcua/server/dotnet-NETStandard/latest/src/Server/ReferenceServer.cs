﻿/* ========================================================================
 * Copyright (c) 2005-2020 The OPC Foundation, Inc. All rights reserved.
 *
 * OPC Foundation MIT License 1.00
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * The complete license agreement can be found here:
 * http://opcfoundation.org/License/MIT/1.00/
 * ======================================================================*/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using Opc.Ua;
using Opc.Ua.Server;
using KRITIS3M.NodeManager;
using Utils = Opc.Ua.Utils;

namespace KRITIS3M.Server
{
    /// <summary>
    /// Implements the Quickstart Reference Server.
    /// </summary>
    /// <remarks>
    /// Each server instance must have one instance of a StandardServer object which is
    /// responsible for reading the configuration file, creating the endpoints and dispatching
    /// incoming requests to the appropriate handler.
    /// 
    /// This sub-class specifies non-configurable metadata such as Product Name and initializes
    /// the EmptyNodeManager which provides access to the data exposed by the Server.
    /// </remarks>
    public partial class ReferenceServer : ReverseConnectServer
    {
        #region Properties
        public ITokenValidator TokenValidator { get; set; }

        #endregion
        #region Overridden Methods
        /// <summary>
        /// Creates the node managers for the server.
        /// </summary>
        /// <remarks>
        /// This method allows the sub-class create any additional node managers which it uses. The SDK
        /// always creates a CoreNodeManager which handles the built-in nodes defined by the specification.
        /// Any additional NodeManagers are expected to handle application specific nodes.
        /// </remarks>
        protected override MasterNodeManager CreateMasterNodeManager(IServerInternal server, ApplicationConfiguration configuration)
        {
            Opc.Ua.Utils.LogInfo(Opc.Ua.Utils.TraceMasks.StartStop, "Creating the Reference Server Node Manager.");

            IList<INodeManager> nodeManagers = new List<INodeManager>();

            // create the custom node manager.
            nodeManagers.Add(new ReferenceNodeManager(server));

            foreach (var nodeManagerFactory in NodeManagerFactories)
            {
                nodeManagers.Add(nodeManagerFactory.Create(server, configuration));
            }

            // create master node manager.
            return new MasterNodeManager(server, configuration, null, nodeManagers.ToArray());
        }

        /// <summary>
        /// Loads the non-configurable properties for the application.
        /// </summary>
        /// <remarks>
        /// These properties are exposed by the server but cannot be changed by administrators.
        /// </remarks>
        protected override ServerProperties LoadServerProperties()
        {
            ServerProperties properties = new ServerProperties {
                ManufacturerName = "OPC Foundation",
                ProductName = "Quickstart Reference Server",
                ProductUri = "http://opcfoundation.org/Quickstart/ReferenceServer/v1.04",
                SoftwareVersion = Opc.Ua.Utils.GetAssemblySoftwareVersion(),
                BuildNumber = Opc.Ua.Utils.GetAssemblyBuildNumber(),
                BuildDate = Opc.Ua.Utils.GetAssemblyTimestamp()
            };

            return properties;
        }

        /// <summary>
        /// Creates the resource manager for the server.
        /// </summary>
        protected override ResourceManager CreateResourceManager(IServerInternal server, ApplicationConfiguration configuration)
        {
            ResourceManager resourceManager = new ResourceManager(server, configuration);

            System.Reflection.FieldInfo[] fields = typeof(StatusCodes).GetFields(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);

            foreach (System.Reflection.FieldInfo field in fields)
            {
                uint? id = field.GetValue(typeof(StatusCodes)) as uint?;

                if (id != null)
                {
                    resourceManager.Add(id.Value, "en-US", field.Name);
                }
            }

            return resourceManager;
        }

        /// <summary>
        /// Initializes the server before it starts up.
        /// </summary>
        /// <remarks>
        /// This method is called before any startup processing occurs. The sub-class may update the 
        /// configuration object or do any other application specific startup tasks.
        /// </remarks>
        protected override void OnServerStarting(ApplicationConfiguration configuration)
        {
            Opc.Ua.Utils.LogInfo(Opc.Ua.Utils.TraceMasks.StartStop, "The server is starting.");

            base.OnServerStarting(configuration);

            // it is up to the application to decide how to validate user identity tokens.
            // this function creates validator for X509 identity tokens.
            CreateUserIdentityValidators(configuration);
        }

        /// <summary>
        /// Called after the server has been started.
        /// </summary>
        protected override void OnServerStarted(IServerInternal server)
        {
            base.OnServerStarted(server);

            // request notifications when the user identity is changed. all valid users are accepted by default.
            server.SessionManager.ImpersonateUser += new ImpersonateEventHandler(SessionManager_ImpersonateUser);

            try
            {
                lock (ServerInternal.Status.Lock)
                {
                    // allow a faster sampling interval for CurrentTime node.
                    ServerInternal.Status.Variable.CurrentTime.MinimumSamplingInterval = 250;
                }
            }
            catch
            { }

        }

        /// <summary>
        /// Override some of the default user token policies for some endpoints.
        /// </summary>
        /// <remarks>
        /// Sample to show how to override default user token policies.
        /// </remarks>
        public override UserTokenPolicyCollection GetUserTokenPolicies(ApplicationConfiguration configuration, EndpointDescription description)
        {
            var policies = base.GetUserTokenPolicies(configuration, description);

            // sample how to modify default user token policies
            if (description.SecurityPolicyUri == SecurityPolicies.Aes256_Sha256_RsaPss &&
                description.SecurityMode == MessageSecurityMode.SignAndEncrypt)
            {
                policies = new UserTokenPolicyCollection(policies.Where(u => u.TokenType != UserTokenType.Certificate));
            }
            else if (description.SecurityPolicyUri == SecurityPolicies.Aes128_Sha256_RsaOaep &&
                description.SecurityMode == MessageSecurityMode.Sign)
            {
                policies = new UserTokenPolicyCollection(policies.Where(u => u.TokenType != UserTokenType.Anonymous));
            }
            else if (description.SecurityPolicyUri == SecurityPolicies.Aes128_Sha256_RsaOaep &&
                description.SecurityMode == MessageSecurityMode.SignAndEncrypt)
            {
                policies = new UserTokenPolicyCollection(policies.Where(u => u.TokenType != UserTokenType.UserName));
            }
            return policies;
        }
        #endregion

        #region User Validation Functions
        /// <summary>
        /// Creates the objects used to validate the user identity tokens supported by the server.
        /// </summary>
        private void CreateUserIdentityValidators(ApplicationConfiguration configuration)
        {
            for (int ii = 0; ii < configuration.ServerConfiguration.UserTokenPolicies.Count; ii++)
            {
                UserTokenPolicy policy = configuration.ServerConfiguration.UserTokenPolicies[ii];

                // create a validator for a certificate token policy.
                if (policy.TokenType == UserTokenType.Certificate)
                {
                    // check if user certificate trust lists are specified in configuration.
                    // if (configuration.SecurityConfiguration.TrustedUserCertificates != null &&
                    //     configuration.SecurityConfiguration.UserIssuerCertificates != null)
                    // {
                    //     CertificateValidator certificateValidator = new CertificateValidator();
                    //     certificateValidator.Update(configuration.SecurityConfiguration).Wait();
                    //     certificateValidator.Update(configuration.SecurityConfiguration.UserIssuerCertificates,
                    //         configuration.SecurityConfiguration.TrustedUserCertificates,
                    //         configuration.SecurityConfiguration.RejectedCertificateStore);
                    //
                    //     // set custom validator for user certificates.
                    //     m_userCertificateValidator = certificateValidator.GetChannelValidator();
                    // }
                    
                }
            }
        }

        /// <summary>
        /// Called when a client tries to change its user identity.
        /// </summary>
        private void SessionManager_ImpersonateUser(Session session, ImpersonateEventArgs args)
        {
            // check for a user name token.
            UserNameIdentityToken userNameToken = args.NewIdentity as UserNameIdentityToken;

            if (userNameToken != null)
            {
                args.Identity = VerifyPassword(userNameToken);

                Opc.Ua.Utils.LogInfo(Opc.Ua.Utils.TraceMasks.Security, "Username Token Accepted: {0}", args.Identity?.DisplayName);

                return;
            }

            // check for x509 user token.
            X509IdentityToken x509Token = args.NewIdentity as X509IdentityToken;

            if (x509Token != null)
            {
                VerifyUserTokenCertificate(x509Token.Certificate);
                // set AuthenticatedUser role for accepted certificate authentication
                args.Identity =  new RoleBasedIdentity(new UserIdentity(x509Token),
                    new List<Role>() { Role.AuthenticatedUser });
                Opc.Ua.Utils.LogInfo(Opc.Ua.Utils.TraceMasks.Security, "X509 Token Accepted: {0}", args.Identity?.DisplayName);

                return;
            }

            // tbd, this needs integration with ID Token
            // // check for issued identity token.
            // if (args.NewIdentity is IssuedIdentityToken issuedToken)
            // {
            //     args.Identity = this.VerifyIssuedToken(issuedToken);
            //
            //     // set AuthenticatedUser role for accepted identity token
            //     args.Identity.GrantedRoleIds.Add(ObjectIds.WellKnownRole_AuthenticatedUser);
            //
            //     return;
            // }

            // check for anonymous token.
            if (args.NewIdentity is AnonymousIdentityToken || args.NewIdentity == null)
            {
                // allow anonymous authentication and set Anonymous role for this authentication
                args.Identity = new RoleBasedIdentity(new UserIdentity(),
                    new List<Role>() { Role.Anonymous });
                return;
            }

            // unsupported identity token type.
            throw ServiceResultException.Create(StatusCodes.BadIdentityTokenInvalid,
                   "Not supported user token type: {0}.", args.NewIdentity);
        }

        /// <summary>
        /// Validates the password for a username token.
        /// </summary>
        private IUserIdentity VerifyPassword(UserNameIdentityToken userNameToken)
        {
            var userName = userNameToken.UserName;
            var password = userNameToken.DecryptedPassword;
            if (String.IsNullOrEmpty(userName))
            {
                // an empty username is not accepted.
                throw ServiceResultException.Create(StatusCodes.BadIdentityTokenInvalid,
                    "Security token is not a valid username token. An empty username is not accepted.");
            }

            if (String.IsNullOrEmpty(password))
            {
                // an empty password is not accepted.
                throw ServiceResultException.Create(StatusCodes.BadIdentityTokenRejected,
                    "Security token is not a valid username token. An empty password is not accepted.");
            }

            // User with permission to configure server
            if (userName == "sysadmin" && password == "demo")
            {
                return new SystemConfigurationIdentity(new UserIdentity(userNameToken));
            }

            // standard users for CTT verification
            if (!((userName == "user1" && password == "password") ||
                (userName == "user2" && password == "password1")))
            {
                // construct translation object with default text.
                TranslationInfo info = new TranslationInfo(
                    "InvalidPassword",
                    "en-US",
                    "Invalid username or password.",
                    userName);

                // create an exception with a vendor defined sub-code.
                throw new ServiceResultException(new ServiceResult(
                    StatusCodes.BadUserAccessDenied,
                    "InvalidPassword",
                    LoadServerProperties().ProductUri,
                    new LocalizedText(info)));
            }
            return new RoleBasedIdentity(new UserIdentity(userNameToken),
                   new List<Role>() { Role.AuthenticatedUser});
        }

        /// <summary>
        /// Verifies that a certificate user token is trusted.
        /// </summary>
        private void VerifyUserTokenCertificate(X509Certificate2 certificate)
        {
            try
            {
                if (m_userCertificateValidator != null)
                {
                    m_userCertificateValidator.Validate(certificate);
                }
                else
                {
                    CertificateValidator.Validate(certificate);
                }
            }
            catch (Exception e)
            {
                TranslationInfo info;
                StatusCode result = StatusCodes.BadIdentityTokenRejected;
                ServiceResultException se = e as ServiceResultException;
                if (se != null && se.StatusCode == StatusCodes.BadCertificateUseNotAllowed)
                {
                    info = new TranslationInfo(
                        "InvalidCertificate",
                        "en-US",
                        "'{0}' is an invalid user certificate.",
                        certificate.Subject);

                    result = StatusCodes.BadIdentityTokenInvalid;
                }
                else
                {
                    // construct translation object with default text.
                    info = new TranslationInfo(
                        "UntrustedCertificate",
                        "en-US",
                        "'{0}' is not a trusted user certificate.",
                        certificate.Subject);
                }

                // create an exception with a vendor defined sub-code.
                throw new ServiceResultException(new ServiceResult(
                    result,
                    info.Key,
                    LoadServerProperties().ProductUri,
                    new LocalizedText(info)));
            }
        }

        private IUserIdentity VerifyIssuedToken(IssuedIdentityToken issuedToken)
        {
            if (this.TokenValidator == null)
            {
                Opc.Ua.Utils.LogWarning(Opc.Ua.Utils.TraceMasks.Security, "No TokenValidator is specified.");
                return null;
            }
            try
            {
                if (issuedToken.IssuedTokenType == IssuedTokenType.JWT)
                {
                    Opc.Ua.Utils.LogDebug(Opc.Ua.Utils.TraceMasks.Security, "VerifyIssuedToken: ValidateToken");
                    return this.TokenValidator.ValidateToken(issuedToken);
                }
                else
                {
                    return null;
                }
            }
            catch (Exception e)
            {
                TranslationInfo info;
                StatusCode result = StatusCodes.BadIdentityTokenRejected;
                if (e is ServiceResultException se && se.StatusCode == StatusCodes.BadIdentityTokenInvalid)
                {
                    info = new TranslationInfo("IssuedTokenInvalid", "en-US", "token is an invalid issued token.");
                    result = StatusCodes.BadIdentityTokenInvalid;
                }
                else // Rejected                
                {
                    // construct translation object with default text.
                    info = new TranslationInfo("IssuedTokenRejected", "en-US", "token is rejected.");
                }

                Opc.Ua.Utils.LogWarning(Opc.Ua.Utils.TraceMasks.Security, "VerifyIssuedToken: Throw ServiceResultException 0x{result:x}");
                throw new ServiceResultException(new ServiceResult(
                    result,
                    info.Key,
                    this.LoadServerProperties().ProductUri,
                    new LocalizedText(info)));
            }
        }
        #endregion

        #region Private Fields
        private ICertificateValidator m_userCertificateValidator;
        #endregion
    }
}