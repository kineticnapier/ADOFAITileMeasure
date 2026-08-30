using System;
using UnityModManagerNet;

namespace KineticNapier.ADOFAITileMeasure
{
    public static class Main
    {
        internal const string Version = "0.1.0";

        private static UnityModManager.ModEntry.ModLogger logger;
        private static bool enabled = true;

        public static bool Load(UnityModManager.ModEntry entry)
        {
            logger = entry.Logger;
            entry.OnToggle = OnToggle;
            entry.OnUpdate = OnUpdate;
            entry.OnUnload = OnUnload;

            WorkbenchBootstrap.TryRegister();
            Log("ADOFAI Tile Measure v" + Version + " loaded.");
            return true;
        }

        private static bool OnToggle(UnityModManager.ModEntry entry, bool value)
        {
            enabled = value;
            if (value) WorkbenchBootstrap.TryRegister();
            else WorkbenchBootstrap.Unregister();
            return true;
        }

        private static void OnUpdate(UnityModManager.ModEntry entry, float deltaTime)
        {
            if (enabled) WorkbenchBootstrap.Tick(deltaTime);
        }

        private static bool OnUnload(UnityModManager.ModEntry entry)
        {
            enabled = false;
            WorkbenchBootstrap.Unregister();
            return true;
        }

        internal static void Log(string message)
        {
            try
            {
                if (logger != null) logger.Log("[ADOFAITileMeasure] " + message);
            }
            catch
            {
            }
        }

        internal static void LogError(string message, Exception ex)
        {
            try
            {
                if (logger != null)
                    logger.Error("[ADOFAITileMeasure] " + message + (ex != null ? Environment.NewLine + ex : string.Empty));
            }
            catch
            {
            }
        }
    }
}
