using System.Text.Json.Serialization;

namespace NexusRemote.Agent.Models;

public class ProcessInfoModel
{
    [JsonPropertyName("pid")]
    public int Pid { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("cpuPercent")]
    public double CpuPercent { get; set; }

    [JsonPropertyName("ramBytes")]
    public long RamBytes { get; set; }

    [JsonPropertyName("ramPercent")]
    public double RamPercent { get; set; }

    [JsonPropertyName("diskBytesPerSec")]
    public long DiskBytesPerSec { get; set; }

    [JsonPropertyName("networkBytesPerSec")]
    public long NetworkBytesPerSec { get; set; }
}

public class ProcessListResponse
{
    [JsonPropertyName("processes")]
    public List<ProcessInfoModel> Processes { get; set; } = new();

    [JsonPropertyName("totalCount")]
    public int TotalCount { get; set; }
}
