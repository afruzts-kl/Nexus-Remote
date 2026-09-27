using System.Diagnostics;
using System.Management;
using System.Runtime.InteropServices;
using LibreHardwareMonitor.Hardware;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class CpuMonitor : ICpuMonitor
{
    private string _model = "Unknown CPU";
    private string _manufacturer = "Unknown";
    private string _architecture = RuntimeInformation.ProcessArchitecture.ToString();
    private int _coreCount = Environment.ProcessorCount;
    private int _threadCount = Environment.ProcessorCount;
    private double _maxClockSpeedMhz = 0;

    private PerformanceCounter? _totalCpuCounter;
    private readonly List<PerformanceCounter> _coreCounters = new();
    private bool _initialized;

    public void Initialize()
    {
        if (_initialized) return;

        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed FROM Win32_Processor");
            foreach (ManagementObject obj in searcher.Get())
            {
                _model = obj["Name"]?.ToString()?.Trim() ?? _model;
                _manufacturer = obj["Manufacturer"]?.ToString()?.Trim() ?? _manufacturer;
                if (int.TryParse(obj["NumberOfCores"]?.ToString(), out var cores)) _coreCount = cores;
                if (int.TryParse(obj["NumberOfLogicalProcessors"]?.ToString(), out var threads)) _threadCount = threads;
                if (double.TryParse(obj["MaxClockSpeed"]?.ToString(), out var maxClock)) _maxClockSpeedMhz = maxClock;
                break;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[CpuMonitor] WMI Query warning: {ex.Message}");
        }

        try
        {
            _totalCpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total", true);
            _totalCpuCounter.NextValue(); // Prime first reading

            for (int i = 0; i < _threadCount; i++)
            {
                try
                {
                    var pc = new PerformanceCounter("Processor", "% Processor Time", i.ToString(), true);
                    pc.NextValue();
                    _coreCounters.Add(pc);
                }
                catch
                {
                    break;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[CpuMonitor] Performance counter init: {ex.Message}");
        }

        _initialized = true;
    }

    public CpuTelemetry GetCpuData()
    {
        Initialize();

        double totalUsage = 0;
        try
        {
            if (_totalCpuCounter != null)
            {
                totalUsage = Math.Round(_totalCpuCounter.NextValue(), 1);
            }
        }
        catch { }

        var perCore = new List<double>();
        foreach (var counter in _coreCounters)
        {
            try
            {
                perCore.Add(Math.Round(counter.NextValue(), 1));
            }
            catch
            {
                perCore.Add(0);
            }
        }

        double? packageTemp = null;
        double? packagePower = null;
        double currentFreq = _maxClockSpeedMhz;

        // Query LibreHardwareMonitor sensors
        try
        {
            var comp = LibreHardwareService.Instance.Computer;
            foreach (var hw in comp.Hardware)
            {
                if (hw.HardwareType == HardwareType.Cpu)
                {
                    foreach (var s in hw.Sensors)
                    {
                        if (s.SensorType == SensorType.Temperature)
                        {
                            if (s.Name.Contains("Package", StringComparison.OrdinalIgnoreCase) ||
                                s.Name.Contains("Core Average", StringComparison.OrdinalIgnoreCase) ||
                                (packageTemp == null && s.Name.Contains("Core", StringComparison.OrdinalIgnoreCase)))
                            {
                                if (s.Value.HasValue) packageTemp = Math.Round(s.Value.Value, 1);
                            }
                        }
                        else if (s.SensorType == SensorType.Power)
                        {
                            if (s.Name.Contains("Package", StringComparison.OrdinalIgnoreCase) || s.Name.Contains("CPU", StringComparison.OrdinalIgnoreCase))
                            {
                                if (s.Value.HasValue) packagePower = Math.Round(s.Value.Value, 1);
                            }
                        }
                        else if (s.SensorType == SensorType.Clock && s.Name.Contains("Core #1", StringComparison.OrdinalIgnoreCase))
                        {
                            if (s.Value.HasValue && s.Value.Value > 0)
                            {
                                currentFreq = Math.Round(s.Value.Value, 0);
                            }
                        }
                    }
                }
            }
        }
        catch { }

        return new CpuTelemetry
        {
            Model = _model,
            Manufacturer = _manufacturer,
            Architecture = _architecture,
            Usage = totalUsage,
            PerCoreUsage = perCore,
            CoreCount = _coreCount,
            ThreadCount = _threadCount,
            CurrentFrequencyMhz = currentFreq > 0 ? currentFreq : _maxClockSpeedMhz,
            MaximumFrequencyMhz = _maxClockSpeedMhz,
            TemperatureC = packageTemp,
            PowerWatts = packagePower
        };
    }
}
