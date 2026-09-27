using System.Text.Json;
using System.Text.Json.Serialization;

namespace NexusRemote.Agent.Models;

public class ProtocolMessage
{
    [JsonPropertyName("version")]
    public int Version { get; set; } = 1;

    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("timestamp")]
    public long Timestamp { get; set; } = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    [JsonPropertyName("payload")]
    public JsonElement? Payload { get; set; }

    public static ProtocolMessage Create<T>(string type, T payload)
    {
        var json = JsonSerializer.SerializeToElement(payload);
        return new ProtocolMessage
        {
            Version = 1,
            Type = type,
            Timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
            Payload = json
        };
    }
}
