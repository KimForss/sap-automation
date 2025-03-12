// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using Newtonsoft.Json;

namespace SDAFWebApp.Models
{

    public class EnvironmentModel
    {
        public string name { get; set; }
        public string description { get; set; }

        public int id { get; set; }
        public Variables variables { get; set; }
        public VariableGroupProjectReference[] variableGroupProjectReferences { get; set; }

        public string sdafControlPlaneEnvironment { get; set; }

        public bool isControlPlane { get; set; }
    }

    public class Variables
    {
        public Variable Agent { get; set; }
        public Variable ARM_CLIENT_ID { get; set; }
        public Variable ARM_OBJECT_ID { get; set; }
        public Variable ARM_CLIENT_SECRET { get; set; }
        public Variable ARM_SUBSCRIPTION_ID { get; set; }
        public Variable ARM_TENANT_ID { get; set; }
        public Variable POOL { get; set; }

        public Variable Use_MSI { get; set; }

        public Variable APPLICATION_CONFIGURATION_ID { get; set; }

        public Variable CONTROL_PLANE_NAME { get; set; }

        public Variable APP_REGISTRATION_APP_ID { get; set; }

        public Variable APP_REGISTRATION_OBJECT_ID { get; set; }

        public Variable IsControlPlane { get; set; }


    }

    public class Variable
    {
        public string value { get; set; }
        [JsonIgnore]
        public bool? isSecret { get; set; }
        [JsonIgnore]
        public bool? isReadOnly { get; set; }
    }

    public class VariableGroupProjectReference
    {
        public ProjectReference projectReference { get; set; }
        public string name { get; set; }
        public string description { get; set; }
    }

    public class ProjectReference
    {
        public string id { get; set; }
        public string name { get; set; }
    }

}
