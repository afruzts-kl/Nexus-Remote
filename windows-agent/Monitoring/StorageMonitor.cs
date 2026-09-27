using System.Diagnostics;
using LibreHardwareMonitor.Hardware;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class StorageMonitor : IStorageMonitor
{
    private readonly Dictionary<string, (PerformanceCounter Read, PerformanceCounter Write)> _diskCounters = new();
    private bool _initialized;

    public void Initialize()
    {
        if (_initialized) return;

        try
        {
            var drives = DriveInfo.GetDrives().Where(d => d.IsReady && d.DriveType == DriveType.Fixed);
            foreach (var d in drives)
            {
                string letter = d.Name.TrimEnd('\\');
                try
                {
                    var readCounter = new PerformanceCounter("LogicalDisk", "Disk Read Bytes/sec", letter, true);
                    var writeCounter = new PerformanceCounter("LogicalDisk", "Disk Write Bytes/sec", letter, true);
                    readCounter.NextValue();
                    writeCounter.NextValue();
                    _diskCounters[letter] = (readCounter, writeCounter);
                }
                catch { }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[StorageMonitor] Disk counter init warning: {ex.Message}");
        }

        _initialized = true;
    }

    public List<DiskTelemetry> GetDisksData()
    {
        Initialize();

        var result = new List<DiskTelemetry>();
        var driveInfos = DriveInfo.GetDrives().Where(d => d.IsReady && (d.DriveType == DriveType.Fixed || d.DriveType == DriveType.Removable));

        // Get storage temperatures from LibreHardwareMonitor if available
        var diskTemps = new Dictionary<string, double>();
        try
        {
            var comp = LibreHardwareService.Instance.Computer;
            foreach (var hw in comp.Hardware)
            {
                if (hw.HardwareType == HardwareType.Storage)
                {
                    foreach (var s in hw.Sensors)
                    {
                        if (s.SensorType == SensorType.Temperature && s.Value.HasValue)
                        {
                            diskTemps[hw.Name] = Math.Round(s.Value.Value, 1);
                        }
                    }
                }
            }
        }
        catch { }

        foreach (var d in driveInfos)
        {
            string driveLetter = d.Name.TrimEnd('\\');
            long total = d.TotalSize;
            long free = d.AvailableFreeSpace;
            long used = total - free;
            double percent = total > 0 ? Math.Round((double)used / total * 100.0, 1) : 0;

            long readSpeed = 0;
            long writeSpeed = 0;

            if (_diskCounters.TryGetValue(driveLetter, out var counters))
            {
                try
                {
                    readSpeed = (long)counters.Read.NextValue();
                    writeSpeed = (long)counters.Write.NextValue();
                }
                catch { }
            }

            double? temp = null;
            foreach (var kv in diskTemps)
            {
                temp = kv.Value; // Match first or relevant disk sensor
                break;
            }

            result.Add(new DiskTelemetry
            {
                Drive = driveLetter,
                Name = string.IsNullOrWhiteSpace(d.VolumeLabel) ? "Local Disk" : d.VolumeLabel,
                Type = d.DriveType.ToString(),
                TotalBytes = total,
                UsedBytes = used,
                FreeBytes = free,
                UsagePercentage = percent,
                ReadSpeedBps = Math.Max(0, readSpeed),
                WriteSpeedBps = Math.Max(0, writeSpeed),
                ActivityPercentage = null,
                TemperatureC = temp,
                Health = "Good"
            });
        }

        return result;
    }
}
