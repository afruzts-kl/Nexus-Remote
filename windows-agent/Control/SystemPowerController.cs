using System.Diagnostics;
using System.Runtime.InteropServices;

namespace NexusRemote.Agent.Control;

public class SystemPowerController
{
    [DllImport("user32.dll")]
    private static extern bool LockWorkStation();

    [DllImport("PowrProf.dll", SetLastError = true)]
    private static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool ExitWindowsEx(uint uFlags, uint dwReason);

    private const uint EWX_LOGOFF = 0x00000000;
    private const uint EWX_FORCEIFHUNG = 0x00000010;

    public bool ExecuteAction(string action, out string? message)
    {
        message = null;
        try
        {
            switch (action.ToLowerInvariant())
            {
                case "lock":
                    bool locked = LockWorkStation();
                    message = locked ? "PC locked successfully" : "Failed to lock PC";
                    return locked;

                case "sleep":
                    bool slept = SetSuspendState(false, true, false);
                    message = slept ? "Sleep state initiated" : "Failed to enter sleep state";
                    return slept;

                case "restart":
                    Process.Start(new ProcessStartInfo("shutdown.exe", "/r /t 0") { CreateNoWindow = true, UseShellExecute = false });
                    message = "Restart command executed";
                    return true;

                case "shutdown":
                    Process.Start(new ProcessStartInfo("shutdown.exe", "/s /t 0") { CreateNoWindow = true, UseShellExecute = false });
                    message = "Shutdown command executed";
                    return true;

                case "signout":
                    ExitWindowsEx(EWX_LOGOFF | EWX_FORCEIFHUNG, 0);
                    message = "Sign out initiated";
                    return true;

                default:
                    message = $"Unknown system command '{action}'";
                    return false;
            }
        }
        catch (Exception ex)
        {
            message = ex.Message;
            return false;
        }
    }
}
