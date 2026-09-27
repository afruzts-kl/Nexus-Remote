using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using NexusRemote.Agent.Models;
using NexusRemote.Agent.Security;

namespace NexusRemote.Agent.Network;

public class UdpDiscoveryServer : IDisposable
{
    private readonly int _port;
    private readonly int _tcpServerPort;
    private readonly PairingManager _pairingManager;
    private UdpClient? _udpListener;
    private CancellationTokenSource? _cts;
    private bool _running;

    public UdpDiscoveryServer(int port = 48899, int tcpServerPort = 48898, PairingManager? pairingManager = null)
    {
        _port = port;
        _tcpServerPort = tcpServerPort;
        _pairingManager = pairingManager ?? new PairingManager();
    }

    public void Start()
    {
        if (_running) return;

        _cts = new CancellationTokenSource();
        _running = true;

        Task.Run(() => ListenLoop(_cts.Token));
        Task.Run(() => BroadcastPresenceLoop(_cts.Token));

        Console.WriteLine($"[Discovery] UDP Discovery listening on port {_port}");
    }

    private async Task ListenLoop(CancellationToken token)
    {
        try
        {
            _udpListener = new UdpClient();
            _udpListener.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
            _udpListener.Client.Bind(new IPEndPoint(IPAddress.Any, _port));

            while (!token.IsCancellationRequested)
            {
                var result = await _udpListener.ReceiveAsync(token);
                string text = Encoding.UTF8.GetString(result.Buffer);

                try
                {
                    using var doc = JsonDocument.Parse(text);
                    if (doc.RootElement.TryGetProperty("type", out var typeElem) &&
                        typeElem.GetString() == "discover_request")
                    {
                        var response = CreateDiscoveryResponse();
                        byte[] responseBytes = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(response));
                        await _udpListener.SendAsync(responseBytes, responseBytes.Length, result.RemoteEndPoint);
                    }
                }
                catch { }
            }
        }
        catch (OperationCanceledException) { }
        catch (Exception ex)
        {
            Console.WriteLine($"[Discovery] Listener stopped: {ex.Message}");
        }
    }

    private async Task BroadcastPresenceLoop(CancellationToken token)
    {
        using var broadcaster = new UdpClient();
        broadcaster.EnableBroadcast = true;
        var broadcastEndpoint = new IPEndPoint(IPAddress.Broadcast, _port);

        while (!token.IsCancellationRequested)
        {
            try
            {
                var response = CreateDiscoveryResponse();
                byte[] data = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(response));
                await broadcaster.SendAsync(data, data.Length, broadcastEndpoint);
            }
            catch { }

            try
            {
                await Task.Delay(3000, token);
            }
            catch (OperationCanceledException) { break; }
        }
    }

    private ProtocolMessage CreateDiscoveryResponse()
    {
        return ProtocolMessage.Create("discover_response", new
        {
            hostname = Environment.MachineName,
            port = _tcpServerPort,
            os = Environment.OSVersion.VersionString,
            agentVersion = "1.0.0",
            pairingCode = _pairingManager.CurrentPairingCode
        });
    }

    public void Stop()
    {
        _running = false;
        _cts?.Cancel();
        _udpListener?.Close();
    }

    public void Dispose()
    {
        Stop();
        _udpListener?.Dispose();
        _cts?.Dispose();
    }
}
