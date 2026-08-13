// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

namespace SDAFWebApp.Models
{
    public class RepositoryPersistenceSettings
    {
        public const string SectionName = "RepositoryPersistence";

        public string Mode { get; set; } = "RepositoryPreferredWithStorageFallback";

        public RepositoryPathSettings Paths { get; set; } = new();
    }

    public class RepositoryPathSettings
    {
        public string Root { get; set; } = "WORKSPACES";

        public string Landscapes { get; set; } = "LANDSCAPE";

        public string Systems { get; set; } = "SYSTEM";

        public string AppFiles { get; set; } = "APPDATA/FILES";
    }
}
