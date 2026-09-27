using System.Net.NetworkInformation;
using System.Net.Sockets;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class NetworkMonitor : INetworkMonitor
{
    private DateTime _lastTime = DateTime.UtcNow;
    private long _lastBytesReceived;
    private long _lastBytesSent;
    private bool _initialized;

    public void Initialize()
    {
        if (_initialized) return;

        var primaryNic = GetPrimaryInterface();
        if (primaryNic != null)
        {
            try
            {
                var stats = primaryNic.GetIPv4Statistics();
                _lastBytesReceived = stats.BytesReceived;
                _lastBytesSent = stats.BytesSent;
                _lastTime = DateTime.UtcNow;
            }
            catch { }
        }

        _initialized = true;
    }

    public NetworkTelemetry GetNetworkData()
    {
        Initialize();

        var primaryNic = GetPrimaryInterface();
        if (primaryNic == null)
        {
            return new NetworkTelemetry();
        }

        string localIp = "127.0.0.1";
        try
        {
            var ipProps = primaryNic.GetIPProperties();
            foreach (var addr in ipProps.UnicastAddresses)
            {
                if (addr.Address.AddressFamily == AddressFamily.InterNetwork &&
                    !System.Net.IPAddress.IsLoopback(addr.Address))
                {
                    localIp = addr.Address.ToString();
                    break;
                }
            }
        }
        catch { }

        long currentReceived = 0;
        long currentSent = 0;
        long downloadSpeed = 0;
        long uploadSpeed = 0;

        try
        {
            var stats = primaryNic.GetIPv4Statistics();
            currentReceived = stats.BytesReceived;
            currentSent = stats.BytesSent;

            var now = DateTime.UtcNow;
            double elapsed = (now - _lastTime).TotalSeconds;
            if (elapsed > 0.1)
            {
                long deltaRecv = currentReceived - _lastBytesReceived;
                long deltaSent = currentSent - _lastBytesSent;

                if (deltaRecv >= 0) downloadSpeed = (long)(deltaRecv / elapsed);
                if (deltaSent >= 0) uploadSpeed = (long)(deltaSent / elapsed);

                _lastBytesReceived = currentReceived;
                _lastBytesSent = currentSent;
                _lastTime = now;
            }
        }
        catch { }

        long linkSpeedMbps = 0;
        try
        {
            if (primaryNic.Speed > 0)
            {
                linkSpeedMbps = primaryNic.Speed / 1_000_000;
            }
        }
        catch { }

        return new NetworkTelemetry
        {
            Interface = primaryNic.Name,
            Type = primaryNic.NetworkInterfaceType.ToString(),
            LocalIp = localIp,
            LinkSpeedMbps = linkSpeedMbps,
            DownloadSpeedBps = downloadSpeed,
            UploadSpeedBps = uploadSpeed,
            TotalDownloadedBytes = currentReceived,
            TotalUploadedBytes = currentSent
        };
    }

    private static NetworkInterface? GetPrimaryInterface()
    {
        try
        {
            var interfaces = NetworkInterface.GetAllNetworkInterfaces()
                .Where(n => n.OperationalStatus == OperationalStatus.Up &&
                            n.NetworkInterfaceType != NetworkInterfaceType.Loopback &&
                            !n.Description.Contains("Virtual", StringComparison.OrdinalIgnoreCase) &&
                            !n.Description.Contains("Pseudo", StringComparison.OrdinalIgnoreCase) &&
                            !n.Description.Contains("vEthernet", StringComparison.OrdinalIgnoreCase))
                .ToList();

            // Find an interface that has an active IPv4 gateway
            foreach (var nic in interfaces)
            {
                var props = nic.GetIPProperties();
                if (props.GatewayAddresses.Any(g => g.Address.AddressFamily == AddressFamily.InterNetwork))
                {
                    return nic;
                }
            }

            return interfaces.FirstOrDefault();
        }
        catch
        {
            return null;
        }
    }
}
