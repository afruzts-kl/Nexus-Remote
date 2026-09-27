using System.Diagnostics;
using System.Globalization;
using LibreHardwareMonitor.Hardware;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class GpuMonitor : IGpuMonitor
{
    private string? _nvidiaSmiPath;
    private string _gpuName = "Generic GPU";
    private bool _initialized;

    public void Initialize()
    {
        if (_initialized) return;

        // Check if nvidia-smi exists
        string system32Smi = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "nvidia-smi.exe");
        if (File.Exists(system32Smi))
        {
            _nvidiaSmiPath = system32Smi;
        }

        // Try getting initial name from LibreHardwareMonitor
        try
        {
            var comp = LibreHardwareService.Instance.Computer;
            foreach (var hw in comp.Hardware)
            {
                if (hw.HardwareType == HardwareType.GpuNvidia ||
                    hw.HardwareType == HardwareType.GpuAmd ||
                    hw.HardwareType == HardwareType.GpuIntel)
                {
                    _gpuName = hw.Name;
                    break;
                }
            }
        }
        catch { }

        _initialized = true;
    }

    public GpuTelemetry GetGpuData()
    {
        Initialize();

        // 1. Try LibreHardwareMonitor first
        var data = QueryFromLibreHardware();
        if (data != null && data.Usage.HasValue)
        {
            return data;
        }

        // 2. If LibreHardwareMonitor doesn't have elevated permissions or values, query nvidia-smi
        if (!string.IsNullOrEmpty(_nvidiaSmiPath))
        {
            var smiData = QueryFromNvidiaSmi();
            if (smiData != null) return smiData;
        }

        return data ?? new GpuTelemetry { Name = _gpuName };
    }

    private GpuTelemetry? QueryFromLibreHardware()
    {
        try
        {
            var comp = LibreHardwareService.Instance.Computer;
            foreach (var hw in comp.Hardware)
            {
                if (hw.HardwareType == HardwareType.GpuNvidia ||
                    hw.HardwareType == HardwareType.GpuAmd ||
                    hw.HardwareType == HardwareType.GpuIntel)
                {
                    var result = new GpuTelemetry
                    {
                        Name = hw.Name
                    };

                    foreach (var s in hw.Sensors)
                    {
                        if (s.SensorType == SensorType.Load)
                        {
                            if (s.Name.Contains("Core", StringComparison.OrdinalIgnoreCase) || s.Name.Contains("GPU", StringComparison.OrdinalIgnoreCase))
                                result.Usage = s.Value.HasValue ? Math.Round(s.Value.Value, 1) : result.Usage;
                        }
                        else if (s.SensorType == SensorType.Temperature && s.Name.Contains("Core", StringComparison.OrdinalIgnoreCase))
                        {
                            result.TemperatureC = s.Value.HasValue ? Math.Round(s.Value.Value, 1) : result.TemperatureC;
                        }
                        else if (s.SensorType == SensorType.SmallData)
                        {
                            if (s.Name.Contains("Memory Used", StringComparison.OrdinalIgnoreCase))
                                result.VramUsedBytes = s.Value.HasValue ? (long)(s.Value.Value * 1024 * 1024) : result.VramUsedBytes;
                            else if (s.Name.Contains("Memory Total", StringComparison.OrdinalIgnoreCase))
                                result.VramTotalBytes = s.Value.HasValue ? (long)(s.Value.Value * 1024 * 1024) : result.VramTotalBytes;
                        }
                        else if (s.SensorType == SensorType.Control || (s.SensorType == SensorType.Level && s.Name.Contains("Fan", StringComparison.OrdinalIgnoreCase)))
                        {
                            result.FanSpeedPercent = s.Value.HasValue ? Math.Round(s.Value.Value, 0) : result.FanSpeedPercent;
                        }
                        else if (s.SensorType == SensorType.Clock)
                        {
                            if (s.Name.Contains("Core", StringComparison.OrdinalIgnoreCase))
                                result.CoreClockMhz = s.Value.HasValue ? Math.Round(s.Value.Value, 0) : result.CoreClockMhz;
                            else if (s.Name.Contains("Memory", StringComparison.OrdinalIgnoreCase))
                                result.MemoryClockMhz = s.Value.HasValue ? Math.Round(s.Value.Value, 0) : result.MemoryClockMhz;
                        }
                        else if (s.SensorType == SensorType.Power && s.Name.Contains("Package", StringComparison.OrdinalIgnoreCase))
                        {
                            result.PowerWatts = s.Value.HasValue ? Math.Round(s.Value.Value, 1) : result.PowerWatts;
                        }
                    }

                    return result;
                }
            }
        }
        catch { }

        return null;
    }

    private GpuTelemetry? QueryFromNvidiaSmi()
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = _nvidiaSmiPath!,
                Arguments = "--query-gpu=name,utilization.gpu,temperature.gpu,memory.total,memory.used,fan.speed,clocks.current.graphics,clocks.current.memory,power.draw --format=csv,noheader,nounits",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(psi);
            if (process == null) return null;

            string output = process.StandardOutput.ReadToEnd();
            process.WaitForExit(1000);

            if (string.IsNullOrWhiteSpace(output)) return null;

            var parts = output.Trim().Split(',');
            if (parts.Length >= 9)
            {
                var result = new GpuTelemetry
                {
                    Name = parts[0].Trim()
                };

                if (double.TryParse(parts[1].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var usage))
                    result.Usage = usage;

                if (double.TryParse(parts[2].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var temp))
                    result.TemperatureC = temp;

                if (double.TryParse(parts[3].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var totalMb))
                    result.VramTotalBytes = (long)(totalMb * 1024 * 1024);

                if (double.TryParse(parts[4].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var usedMb))
                    result.VramUsedBytes = (long)(usedMb * 1024 * 1024);

                if (double.TryParse(parts[5].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var fan))
                    result.FanSpeedPercent = fan;

                if (double.TryParse(parts[6].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var coreClock))
                    result.CoreClockMhz = coreClock;

                if (double.TryParse(parts[7].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var memClock))
                    result.MemoryClockMhz = memClock;

                if (double.TryParse(parts[8].Trim(), NumberStyles.Any, CultureInfo.InvariantCulture, out var power))
                    result.PowerWatts = power;

                return result;
            }
        }
        catch { }

        return null;
    }
}
