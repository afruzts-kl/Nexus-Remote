using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

namespace NexusRemote.Agent.Network;

public class ConnectedClient
{
    public string Id { get; }
    public WebSocket WebSocket { get; }
    public string RemoteEndpoint { get; }
    public bool IsAuthenticated { get; set; }
    public string DeviceName { get; set; } = "Client";
    public bool IsScreenStreaming { get; set; }
    public int StreamFps { get; set; } = 20;

    private readonly SemaphoreSlim _sendLock = new(1, 1);

    public ConnectedClient(string id, WebSocket webSocket, string remoteEndpoint)
    {
        Id = id;
        WebSocket = webSocket;
        RemoteEndpoint = remoteEndpoint;
    }

    public async Task SendMessageAsync<T>(T message, CancellationToken token)
    {
        if (WebSocket.State != WebSocketState.Open) return;
        byte[] bytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));
        await _sendLock.WaitAsync(token);
        try
        {
            if (WebSocket.State == WebSocketState.Open)
            {
                await WebSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, token);
            }
        }
        finally
        {
            _sendLock.Release();
        }
    }

    public async Task SendBinaryAsync(byte[] data, CancellationToken token)
    {
        if (WebSocket.State != WebSocketState.Open) return;
        await _sendLock.WaitAsync(token);
        try
        {
            if (WebSocket.State == WebSocketState.Open)
            {
                await WebSocket.SendAsync(new ArraySegment<byte>(data), WebSocketMessageType.Binary, true, token);
            }
        }
        finally
        {
            _sendLock.Release();
        }
    }
}
