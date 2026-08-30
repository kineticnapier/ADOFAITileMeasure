using System;
using System.Reflection;

namespace KineticNapier.ADOFAITileMeasure
{
    internal static class WorkbenchBootstrap
    {
        private const string WorkbenchAssemblyName = "ADOFAIWorkbench";
        private const string IntegrationTypeName = "KineticNapier.ADOFAITileMeasure.MeasureWorkbenchIntegration";
        private const float RefreshInterval = 0.05f;
        private const float RegisterRetryInterval = 1f;

        private static bool registered;
        private static float refreshElapsed;
        private static float retryElapsed;
        private static MethodInfo refreshMethod;
        private static MethodInfo unregisterMethod;

        internal static void TryRegister()
        {
            if (registered || !IsWorkbenchLoaded()) return;

            try
            {
                Type type = typeof(WorkbenchBootstrap).Assembly.GetType(IntegrationTypeName, false);
                if (type == null) return;

                MethodInfo register = type.GetMethod("Register", BindingFlags.NonPublic | BindingFlags.Static);
                refreshMethod = type.GetMethod("Refresh", BindingFlags.NonPublic | BindingFlags.Static);
                unregisterMethod = type.GetMethod("Unregister", BindingFlags.NonPublic | BindingFlags.Static);
                if (register == null || refreshMethod == null || unregisterMethod == null) return;

                register.Invoke(null, null);
                registered = true;
                refreshElapsed = RefreshInterval;
                retryElapsed = 0f;
                Main.Log("Measure pane registered with ADOFAIWorkbench.");
            }
            catch (Exception ex)
            {
                refreshMethod = null;
                unregisterMethod = null;
                Main.LogError("Workbench registration failed.", ex);
            }
        }

        internal static void Tick(float deltaTime)
        {
            float elapsed = Math.Max(0f, deltaTime);
            if (!registered)
            {
                retryElapsed += elapsed;
                if (retryElapsed >= RegisterRetryInterval)
                {
                    retryElapsed = 0f;
                    TryRegister();
                }
                return;
            }

            refreshElapsed += elapsed;
            if (refreshElapsed < RefreshInterval) return;
            refreshElapsed = 0f;

            try
            {
                refreshMethod.Invoke(null, null);
            }
            catch (Exception ex)
            {
                Main.LogError("Measure pane refresh failed.", ex);
            }
        }

        internal static void Unregister()
        {
            if (!registered) return;

            try
            {
                unregisterMethod.Invoke(null, null);
            }
            catch (Exception ex)
            {
                Main.LogError("Workbench unregister failed.", ex);
            }
            finally
            {
                registered = false;
                refreshElapsed = 0f;
                retryElapsed = 0f;
                refreshMethod = null;
                unregisterMethod = null;
            }
        }

        private static bool IsWorkbenchLoaded()
        {
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();
            for (int i = 0; i < assemblies.Length; i++)
            {
                try
                {
                    if (string.Equals(assemblies[i].GetName().Name, WorkbenchAssemblyName, StringComparison.Ordinal))
                        return true;
                }
                catch
                {
                }
            }
            return false;
        }
    }
}
