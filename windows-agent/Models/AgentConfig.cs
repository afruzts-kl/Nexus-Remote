using System.Text.Json.Serialization;

namespace NexusRemote.Agent.Models;

public class AgentConfig
{
    [JsonPropertyName("serverPort")]
    public int ServerPort { get; set; } = 48898;

    [JsonPropertyName("discoveryPort")]
    public int DiscoveryPort { get; set; } = 48899;

    [JsonPropertyName("machineName")]
    public string MachineName { get; set; } = Environment.MachineName;

    [JsonPropertyName("startWithWindows")]
    public bool StartWithWindows { get; set; } = false;

    [JsonPropertyName("pairedDevices")]
    public List<PairedDevice> PairedDevices { get; set; } = new();
}

public class PairedDevice
{
    [JsonPropertyName("deviceId")]
    public string DeviceId { get; set; } = string.Empty;

    [JsonPropertyName("deviceName")]
    public string DeviceName { get; set; } = string.Empty;

    [JsonPropertyName("deviceToken")]
    public string DeviceToken { get; set; } = string.Empty;

    [JsonPropertyName("pairedAt")]
    public DateTime PairedAt { get; set; } = DateTime.UtcNow;

    [JsonPropertyName("lastConnected")]
    public DateTime? LastConnected { get; set; }
}
