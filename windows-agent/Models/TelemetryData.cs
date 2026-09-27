using System.Text.Json.Serialization;

namespace NexusRemote.Agent.Models;

public class TelemetryData
{
    [JsonPropertyName("cpu")]
    public CpuTelemetry Cpu { get; set; } = new();

    [JsonPropertyName("memory")]
    public MemoryTelemetry Memory { get; set; } = new();

    [JsonPropertyName("gpu")]
    public GpuTelemetry Gpu { get; set; } = new();

    [JsonPropertyName("disks")]
    public List<DiskTelemetry> Disks { get; set; } = new();

    [JsonPropertyName("network")]
    public NetworkTelemetry Network { get; set; } = new();

    [JsonPropertyName("system")]
    public SystemTelemetry System { get; set; } = new();
}

public class CpuTelemetry
{
    [JsonPropertyName("model")]
    public string Model { get; set; } = "Unknown";

    [JsonPropertyName("manufacturer")]
    public string Manufacturer { get; set; } = "Unknown";

    [JsonPropertyName("architecture")]
    public string Architecture { get; set; } = "x64";

    [JsonPropertyName("usage")]
    public double Usage { get; set; }

    [JsonPropertyName("perCoreUsage")]
    public List<double> PerCoreUsage { get; set; } = new();

    [JsonPropertyName("coreCount")]
    public int CoreCount { get; set; }

    [JsonPropertyName("threadCount")]
    public int ThreadCount { get; set; }

    [JsonPropertyName("currentFrequencyMhz")]
    public double CurrentFrequencyMhz { get; set; }

    [JsonPropertyName("maximumFrequencyMhz")]
    public double MaximumFrequencyMhz { get; set; }

    [JsonPropertyName("temperatureC")]
    public double? TemperatureC { get; set; }

    [JsonPropertyName("powerWatts")]
    public double? PowerWatts { get; set; }
}

public class MemoryTelemetry
{
    [JsonPropertyName("totalBytes")]
    public long TotalBytes { get; set; }

    [JsonPropertyName("usedBytes")]
    public long UsedBytes { get; set; }

    [JsonPropertyName("availableBytes")]
    public long AvailableBytes { get; set; }

    [JsonPropertyName("freeBytes")]
    public long FreeBytes { get; set; }

    [JsonPropertyName("usagePercentage")]
    public double UsagePercentage { get; set; }

    [JsonPropertyName("pageFileUsagePercentage")]
    public double? PageFileUsagePercentage { get; set; }
}

public class GpuTelemetry
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "Not detected";

    [JsonPropertyName("usage")]
    public double? Usage { get; set; }

    [JsonPropertyName("temperatureC")]
    public double? TemperatureC { get; set; }

    [JsonPropertyName("vramTotalBytes")]
    public long? VramTotalBytes { get; set; }

    [JsonPropertyName("vramUsedBytes")]
    public long? VramUsedBytes { get; set; }

    [JsonPropertyName("fanSpeedPercent")]
    public double? FanSpeedPercent { get; set; }

    [JsonPropertyName("coreClockMhz")]
    public double? CoreClockMhz { get; set; }

    [JsonPropertyName("memoryClockMhz")]
    public double? MemoryClockMhz { get; set; }

    [JsonPropertyName("powerWatts")]
    public double? PowerWatts { get; set; }
}

public class DiskTelemetry
{
    [JsonPropertyName("drive")]
    public string Drive { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("type")]
    public string Type { get; set; } = "Fixed";

    [JsonPropertyName("totalBytes")]
    public long TotalBytes { get; set; }

    [JsonPropertyName("usedBytes")]
    public long UsedBytes { get; set; }

    [JsonPropertyName("freeBytes")]
    public long FreeBytes { get; set; }

    [JsonPropertyName("usagePercentage")]
    public double UsagePercentage { get; set; }

    [JsonPropertyName("readSpeedBps")]
    public long ReadSpeedBps { get; set; }

    [JsonPropertyName("writeSpeedBps")]
    public long WriteSpeedBps { get; set; }

    [JsonPropertyName("activityPercentage")]
    public double? ActivityPercentage { get; set; }

    [JsonPropertyName("temperatureC")]
    public double? TemperatureC { get; set; }

    [JsonPropertyName("health")]
    public string? Health { get; set; }
}

public class NetworkTelemetry
{
    [JsonPropertyName("interface")]
    public string Interface { get; set; } = string.Empty;

    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("localIp")]
    public string LocalIp { get; set; } = string.Empty;

    [JsonPropertyName("linkSpeedMbps")]
    public long LinkSpeedMbps { get; set; }

    [JsonPropertyName("downloadSpeedBps")]
    public long DownloadSpeedBps { get; set; }

    [JsonPropertyName("uploadSpeedBps")]
    public long UploadSpeedBps { get; set; }

    [JsonPropertyName("totalDownloadedBytes")]
    public long TotalDownloadedBytes { get; set; }

    [JsonPropertyName("totalUploadedBytes")]
    public long TotalUploadedBytes { get; set; }
}

public class SystemTelemetry
{
    [JsonPropertyName("uptimeSeconds")]
    public long UptimeSeconds { get; set; }

    [JsonPropertyName("osVersion")]
    public string OsVersion { get; set; } = string.Empty;

    [JsonPropertyName("motherboard")]
    public string? Motherboard { get; set; }

    [JsonPropertyName("bios")]
    public string? Bios { get; set; }
}
