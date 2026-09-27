using System.Management;
using System.Runtime.InteropServices;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class SystemInfoMonitor : ISystemInfoMonitor
{
    private string _osVersion = RuntimeInformation.OSDescription;
    private string? _motherboard;
    private string? _bios;
    private bool _initialized;

    public void Initialize()
    {
        if (_initialized) return;

        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT Caption FROM Win32_OperatingSystem");
            foreach (ManagementObject obj in searcher.Get())
            {
                var caption = obj["Caption"]?.ToString();
                if (!string.IsNullOrWhiteSpace(caption))
                {
                    _osVersion = $"{caption.Trim()} ({RuntimeInformation.OSArchitecture})";
                }
                break;
            }
        }
        catch { }

        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT Manufacturer, Product FROM Win32_BaseBoard");
            foreach (ManagementObject obj in searcher.Get())
            {
                var mfg = obj["Manufacturer"]?.ToString()?.Trim();
                var prod = obj["Product"]?.ToString()?.Trim();
                _motherboard = $"{mfg} {prod}".Trim();
                break;
            }
        }
        catch { }

        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT Manufacturer, SMBIOSBIOSVersion FROM Win32_BIOS");
            foreach (ManagementObject obj in searcher.Get())
            {
                var mfg = obj["Manufacturer"]?.ToString()?.Trim();
                var ver = obj["SMBIOSBIOSVersion"]?.ToString()?.Trim();
                _bios = $"{mfg} {ver}".Trim();
                break;
            }
        }
        catch { }

        _initialized = true;
    }

    public SystemTelemetry GetSystemData()
    {
        Initialize();

        return new SystemTelemetry
        {
            UptimeSeconds = (long)(Environment.TickCount64 / 1000),
            OsVersion = _osVersion,
            Motherboard = string.IsNullOrWhiteSpace(_motherboard) ? "Unavailable" : _motherboard,
            Bios = string.IsNullOrWhiteSpace(_bios) ? "Unavailable" : _bios
        };
    }
}
