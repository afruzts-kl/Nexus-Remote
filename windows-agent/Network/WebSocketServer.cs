using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Net.WebSockets;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using NexusRemote.Agent.Control;
using NexusRemote.Agent.Models;
using NexusRemote.Agent.Monitoring;
using NexusRemote.Agent.Security;
using NexusRemote.Agent.Streaming;

namespace NexusRemote.Agent.Network;

public class WebSocketServer : IDisposable
{
    private const string WsGuid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    private readonly int _port;
    private readonly IHardwareMonitor _hardwareMonitor;
    private readonly ProcessMonitor _processMonitor;
    private readonly MouseController _mouseController;
    private readonly KeyboardController _keyboardController;
    private readonly SystemPowerController _systemPowerController;
    private readonly PairingManager _pairingManager;
    private readonly ScreenCaptureService _screenCaptureService;

    private TcpListener? _tcpListener;
    private CancellationTokenSource? _cts;
    private readonly ConcurrentDictionary<string, ConnectedClient> _clients = new();

    public event Action<string, bool>? ClientConnectionChanged;

    public WebSocketServer(
        int port = 48898,
        IHardwareMonitor? hardwareMonitor = null,
        PairingManager? pairingManager = null)
    {
        _port = port;
        _hardwareMonitor = hardwareMonitor ?? new HardwareMonitor();
        _processMonitor = new ProcessMonitor();
        _mouseController = new MouseController();
        _keyboardController = new KeyboardController();
        _systemPowerController = new SystemPowerController();
        _pairingManager = pairingManager ?? new PairingManager();
        _screenCaptureService = new ScreenCaptureService();
    }

    public int ConnectedClientCount => _clients.Count;
    public IEnumerable<ConnectedClient> ConnectedClients => _clients.Values;

    public void Start()
    {
        _cts = new CancellationTokenSource();
        _tcpListener = new TcpListener(IPAddress.Any, _port);
        _tcpListener.Server.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
        _tcpListener.Start();

        Task.Run(() => AcceptLoop(_cts.Token));
        Console.WriteLine($"[Server] TCP/WebSocket Server listening on 0.0.0.0:{_port}");
    }

    private async Task AcceptLoop(CancellationToken token)
    {
        while (!token.IsCancellationRequested && _tcpListener != null)
        {
            try
            {
                var tcpClient = await _tcpListener.AcceptTcpClientAsync(token);
                _ = HandleIncomingConnection(tcpClient, token);
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex)
            {
                Console.WriteLine($"[Server] Accept error: {ex.Message}");
            }
        }
    }

    private async Task HandleIncomingConnection(TcpClient tcpClient, CancellationToken token)
    {
        var stream = tcpClient.GetStream();
        string remoteEndpoint = tcpClient.Client.RemoteEndPoint?.ToString() ?? "Unknown";

        try
        {
            // Read HTTP handshake request
            var headerBuffer = new byte[4096];
            int read = await stream.ReadAsync(headerBuffer, 0, headerBuffer.Length, token);
            if (read == 0)
            {
                tcpClient.Close();
                return;
            }

            string requestStr = Encoding.UTF8.GetString(headerBuffer, 0, read);

            // Check if this is a WebSocket upgrade request
            var keyMatch = Regex.Match(requestStr, @"Sec-WebSocket-Key:\s*([^\r\n]+)", RegexOptions.IgnoreCase);
            if (keyMatch.Success)
            {
                string secKey = keyMatch.Groups[1].Value.Trim();
                string acceptHash = ComputeWebSocketAcceptKey(secKey);

                string response = "HTTP/1.1 101 Switching Protocols\r\n" +
                                  "Upgrade: websocket\r\n" +
                                  "Connection: Upgrade\r\n" +
                                  $"Sec-WebSocket-Accept: {acceptHash}\r\n\r\n";

                byte[] responseBytes = Encoding.UTF8.GetBytes(response);
                await stream.WriteAsync(responseBytes, 0, responseBytes.Length, token);
                await stream.FlushAsync(token);

                // Create standard .NET WebSocket from stream
                var ws = WebSocket.CreateFromStream(stream, isServer: true, subProtocol: null, TimeSpan.FromSeconds(30));

                string clientId = Guid.NewGuid().ToString("N");
                var client = new ConnectedClient(clientId, ws, remoteEndpoint);
                _clients[clientId] = client;
                ClientConnectionChanged?.Invoke(remoteEndpoint, true);

                using var clientCts = CancellationTokenSource.CreateLinkedTokenSource(token);
                var recvTask = ReceiveLoop(client, clientCts);
                var telemetryTask = TelemetryLoop(client, clientCts.Token);
                var screenTask = ScreenStreamLoop(client, clientCts.Token);

                await Task.WhenAny(recvTask, telemetryTask, screenTask);

                clientCts.Cancel();
                _clients.TryRemove(clientId, out _);
                ClientConnectionChanged?.Invoke(remoteEndpoint, false);

                try
                {
                    if (ws.State == WebSocketState.Open)
                    {
                        await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
                    }
                }
                catch { }
            }
            else
            {
                // Regular HTTP GET response (Health/Status)
                string body = "Nexus Remote Agent Online\r\n";
                byte[] bodyBytes = Encoding.UTF8.GetBytes(body);
                string response = "HTTP/1.1 200 OK\r\n" +
                                  "Content-Type: text/plain\r\n" +
                                  $"Content-Length: {bodyBytes.Length}\r\n" +
                                  "Connection: close\r\n\r\n";
                byte[] headerBytes = Encoding.UTF8.GetBytes(response);
                await stream.WriteAsync(headerBytes, 0, headerBytes.Length, token);
                await stream.WriteAsync(bodyBytes, 0, bodyBytes.Length, token);
                await stream.FlushAsync(token);
                tcpClient.Close();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Server] Handshake failed from {remoteEndpoint}: {ex.Message}");
            tcpClient.Close();
        }
    }

    private static string ComputeWebSocketAcceptKey(string secWebSocketKey)
    {
        byte[] hash = SHA1.HashData(Encoding.UTF8.GetBytes(secWebSocketKey + WsGuid));
        return Convert.ToBase64String(hash);
    }

    private async Task ReceiveLoop(ConnectedClient client, CancellationTokenSource cts)
    {
        var buffer = new byte[64 * 1024];
        var ms = new MemoryStream();

        while (!cts.IsCancellationRequested && client.WebSocket.State == WebSocketState.Open)
        {
            try
            {
                var result = await client.WebSocket.ReceiveAsync(new ArraySegment<byte>(buffer), cts.Token);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    break;
                }

                ms.Write(buffer, 0, result.Count);
                if (result.EndOfMessage)
                {
                    string text = Encoding.UTF8.GetString(ms.ToArray());
                    ms.SetLength(0);
                    await ProcessMessage(client, text, cts.Token);
                }
            }
            catch
            {
                break;
            }
        }
        cts.Cancel();
    }

    private async Task ProcessMessage(ConnectedClient client, string messageJson, CancellationToken token)
    {
        try
        {
            using var doc = JsonDocument.Parse(messageJson);
            var root = doc.RootElement;
            string type = root.GetProperty("type").GetString() ?? string.Empty;
            var payload = root.TryGetProperty("payload", out var p) ? p : (JsonElement?)null;

            switch (type)
            {
                case "ping":
                    await client.SendMessageAsync(ProtocolMessage.Create("pong", new
                    {
                        clientTime = payload?.TryGetProperty("clientTime", out var ct) == true ? ct.GetInt64() : 0,
                        serverTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                    }), token);
                    break;

                case "pair_request":
                    HandlePairRequest(client, payload, token);
                    break;

                case "auth_request":
                    HandleAuthRequest(client, payload, token);
                    break;

                case "process_list_request":
                    if (!client.IsAuthenticated) break;
                    string sortBy = payload?.TryGetProperty("sortBy", out var sb) == true ? sb.GetString() ?? "cpu" : "cpu";
                    var processes = _processMonitor.GetProcesses(sortBy);
                    await client.SendMessageAsync(ProtocolMessage.Create("process_list_response", processes), token);
                    break;

                case "process_kill_request":
                    if (!client.IsAuthenticated) break;
                    if (payload?.TryGetProperty("pid", out var pidElem) == true)
                    {
                        int pid = pidElem.GetInt32();
                        bool killed = _processMonitor.KillProcess(pid, out var killErr);
                        await client.SendMessageAsync(ProtocolMessage.Create("process_kill_response", new
                        {
                            success = killed,
                            pid,
                            error = killErr
                        }), token);
                    }
                    break;

                case "mouse_move":
                    if (!client.IsAuthenticated) break;
                    if (payload.HasValue)
                    {
                        double dx = payload.Value.TryGetProperty("dx", out var dxE) ? dxE.GetDouble() : 0;
                        double dy = payload.Value.TryGetProperty("dy", out var dyE) ? dyE.GetDouble() : 0;
                        bool isRelative = !payload.Value.TryGetProperty("isRelative", out var irE) || irE.GetBoolean();
                        if (isRelative)
                        {
                            _mouseController.MoveRelative(dx, dy);
                        }
                        else
                        {
                            _mouseController.MoveAbsolute(dx, dy);
                        }
                    }
                    break;

                case "mouse_button":
                    if (!client.IsAuthenticated) break;
                    if (payload.HasValue)
                    {
                        string btn = payload.Value.TryGetProperty("button", out var bE) ? bE.GetString() ?? "left" : "left";
                        string act = payload.Value.TryGetProperty("action", out var aE) ? aE.GetString() ?? "click" : "click";
                        _mouseController.ButtonAction(btn, act);
                    }
                    break;

                case "mouse_scroll":
                    if (!client.IsAuthenticated) break;
                    if (payload.HasValue)
                    {
                        int scrollX = payload.Value.TryGetProperty("deltaX", out var sxE) ? sxE.GetInt32() : 0;
                        int scrollY = payload.Value.TryGetProperty("deltaY", out var syE) ? syE.GetInt32() : 0;
                        _mouseController.Scroll(scrollX, scrollY);
                    }
                    break;

                case "keyboard":
                    if (!client.IsAuthenticated) break;
                    if (payload.HasValue)
                    {
                        string key = payload.Value.TryGetProperty("key", out var kE) ? kE.GetString() ?? "" : "";
                        int vk = payload.Value.TryGetProperty("vkCode", out var vkE) ? vkE.GetInt32() : 0;
                        string act = payload.Value.TryGetProperty("action", out var kaE) ? kaE.GetString() ?? "tap" : "tap";

                        List<string> mods = new();
                        if (payload.Value.TryGetProperty("modifiers", out var modsElem) && modsElem.ValueKind == JsonValueKind.Array)
                        {
                            foreach (var item in modsElem.EnumerateArray())
                            {
                                if (item.GetString() is string s) mods.Add(s);
                            }
                        }

                        _keyboardController.SendKey(key, vk, mods, act);
                    }
                    break;

                case "keyboard_text":
                    if (!client.IsAuthenticated) break;
                    if (payload?.TryGetProperty("text", out var tE) == true)
                    {
                        _keyboardController.SendText(tE.GetString() ?? "");
                    }
                    break;

                case "system_command":
                    if (!client.IsAuthenticated) break;
                    if (payload?.TryGetProperty("action", out var scaE) == true)
                    {
                        string action = scaE.GetString() ?? "";
                        bool executed = _systemPowerController.ExecuteAction(action, out var msg);
                        await client.SendMessageAsync(ProtocolMessage.Create("system_command_response", new
                        {
                            action,
                            success = executed,
                            message = msg
                        }), token);
                    }
                    break;

                case "screen_start":
                    if (!client.IsAuthenticated) break;
                    client.IsScreenStreaming = true;
                    if (payload.HasValue)
                    {
                        int fps = payload.Value.TryGetProperty("fps", out var fpsE) ? fpsE.GetInt32() : 20;
                        int quality = payload.Value.TryGetProperty("quality", out var qE) ? qE.GetInt32() : 60;
                        double scale = payload.Value.TryGetProperty("scale", out var scE) ? scE.GetDouble() : 0.75;
                        client.StreamFps = Math.Clamp(fps, 5, 30);
                        _screenCaptureService.SetConfig(scale, quality);
                    }
                    break;

                case "screen_stop":
                    client.IsScreenStreaming = false;
                    break;

                case "screen_config":
                    if (payload.HasValue)
                    {
                        if (payload.Value.TryGetProperty("fps", out var fpsE))
                            client.StreamFps = Math.Clamp(fpsE.GetInt32(), 5, 30);
                        if (payload.Value.TryGetProperty("quality", out var qE) || payload.Value.TryGetProperty("scale", out var scE))
                        {
                            int quality = payload.Value.TryGetProperty("quality", out var q) ? q.GetInt32() : 60;
                            double scale = payload.Value.TryGetProperty("scale", out var s) ? s.GetDouble() : 0.75;
                            _screenCaptureService.SetConfig(scale, quality);
                        }
                    }
                    break;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Server] Message process error: {ex.Message}");
        }
    }

    private void HandlePairRequest(ConnectedClient client, JsonElement? payload, CancellationToken token)
    {
        if (payload == null) return;
        string deviceId = payload.Value.TryGetProperty("deviceId", out var dId) ? dId.GetString() ?? "" : "";
        string deviceName = payload.Value.TryGetProperty("deviceName", out var dName) ? dName.GetString() ?? "Unknown Phone" : "Unknown Phone";
        string pairingCode = payload.Value.TryGetProperty("pairingCode", out var pCode) ? pCode.GetString() ?? "" : "";

        if (_pairingManager.ValidatePairingCode(pairingCode))
        {
            string tokenStr = _pairingManager.RegisterPairedDevice(deviceId, deviceName);
            client.IsAuthenticated = true;
            client.DeviceName = deviceName;

            _ = client.SendMessageAsync(ProtocolMessage.Create("pair_response", new
            {
                status = "approved",
                deviceToken = tokenStr,
                hostname = Environment.MachineName
            }), token);
        }
        else
        {
            _ = client.SendMessageAsync(ProtocolMessage.Create("pair_response", new
            {
                status = "invalid_code",
                error = "Pairing code did not match"
            }), token);
        }
    }

    private void HandleAuthRequest(ConnectedClient client, JsonElement? payload, CancellationToken token)
    {
        if (payload == null) return;
        string deviceId = payload.Value.TryGetProperty("deviceId", out var dId) ? dId.GetString() ?? "" : "";
        string deviceToken = payload.Value.TryGetProperty("deviceToken", out var dTok) ? dTok.GetString() ?? "" : "";

        if (_pairingManager.AuthenticateDevice(deviceId, deviceToken))
        {
            client.IsAuthenticated = true;
            _ = client.SendMessageAsync(ProtocolMessage.Create("auth_response", new
            {
                success = true,
                sessionToken = Guid.NewGuid().ToString("N"),
                serverTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            }), token);
        }
        else
        {
            _ = client.SendMessageAsync(ProtocolMessage.Create("auth_response", new
            {
                success = false,
                error = "Authentication failed. Device unpair or invalid token."
            }), token);
        }
    }

    private async Task TelemetryLoop(ConnectedClient client, CancellationToken token)
    {
        while (!token.IsCancellationRequested && client.WebSocket.State == WebSocketState.Open)
        {
            try
            {
                if (client.IsAuthenticated)
                {
                    var telemetry = _hardwareMonitor.GetTelemetry();
                    var msg = ProtocolMessage.Create("telemetry", telemetry);
                    await client.SendMessageAsync(msg, token);
                }
            }
            catch { }

            try
            {
                await Task.Delay(400, token);
            }
            catch (OperationCanceledException) { break; }
        }
    }

    private async Task ScreenStreamLoop(ConnectedClient client, CancellationToken token)
    {
        while (!token.IsCancellationRequested && client.WebSocket.State == WebSocketState.Open)
        {
            if (client.IsAuthenticated && client.IsScreenStreaming)
            {
                try
                {
                    byte[]? frameData = _screenCaptureService.CaptureFrame(out _, out _);
                    if (frameData != null)
                    {
                        await client.SendBinaryAsync(frameData, token);
                    }
                }
                catch { }

                int delayMs = 1000 / client.StreamFps;
                try
                {
                    await Task.Delay(delayMs, token);
                }
                catch (OperationCanceledException) { break; }
            }
            else
            {
                try
                {
                    await Task.Delay(100, token);
                }
                catch (OperationCanceledException) { break; }
            }
        }
    }

    public void Stop()
    {
        _cts?.Cancel();
        _tcpListener?.Stop();
    }

    public void Dispose()
    {
        Stop();
        _screenCaptureService.Dispose();
        _cts?.Dispose();
    }
}
