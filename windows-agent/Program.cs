using System.Net;
using System.Net.Sockets;
using System.Windows.Forms;
using NexusRemote.Agent.Monitoring;
using NexusRemote.Agent.Network;
using NexusRemote.Agent.Security;
using NexusRemote.Agent.UI;

namespace NexusRemote.Agent;

public static class Program
{
    [STAThread]
    public static void Main(string[] args)
    {
        Console.Title = "Nexus Remote Agent";
        Console.ForegroundColor = ConsoleColor.Cyan;
        Console.WriteLine(@"
  _   _                       ____                      _       
 | \ | | _____  ___   _ ___  |  _ \ ___ _ __ ___   ___ | |_ ___ 
 |  \| |/ _ \ \/ / | | / __| | |_) / _ \ '_ ` _ \ / _ \| __/ _ \
 | |\  |  __/>  <| |_| \__ \ |  _ <  __/ | | | | | (_) | ||  __/
 |_| \_|\___/_/\_\\__,_|___/ |_| \_\___|_| |_| |_|\___/ \__\___|
        ");
        Console.ResetColor();

        bool runAsTray = args.Contains("--tray") || !args.Contains("--console");
        int tcpPort = 48898;
        int udpPort = 48899;

        Console.WriteLine($"[Agent] Initializing hardware monitoring subsystem...");
        var hwMonitor = new HardwareMonitor();
        hwMonitor.Initialize();

        Console.WriteLine($"[Agent] Initializing security and pairing manager...");
        var pairingManager = new PairingManager();
        string pairingCode = pairingManager.CurrentPairingCode;

        Console.WriteLine($"[Agent] Starting WebSocket Server on port {tcpPort}...");
        var wsServer = new WebSocketServer(tcpPort, hwMonitor, pairingManager);
        wsServer.Start();

        Console.WriteLine($"[Agent] Starting UDP LAN Discovery on port {udpPort}...");
        var udpDiscovery = new UdpDiscoveryServer(udpPort, tcpPort, pairingManager);
        udpDiscovery.Start();

        // Print connection information
        Console.WriteLine();
        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine($"=================================================");
        Console.WriteLine($"  Nexus Remote Agent is ONLINE and READY");
        Console.WriteLine($"  Machine Name : {Environment.MachineName}");
        Console.WriteLine($"  Pairing Code : {pairingCode}");
        Console.WriteLine($"  TCP Port     : {tcpPort}");
        Console.WriteLine($"  Discovery    : UDP {udpPort}");
        Console.WriteLine($"  Local IPs    : {string.Join(", ", GetLocalIpAddresses())}");
        Console.WriteLine($"=================================================");
        Console.ResetColor();
        Console.WriteLine();

        if (runAsTray)
        {
            Console.WriteLine("[Agent] Launching Windows System Tray context...");
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new TrayApplicationContext(wsServer, udpDiscovery, pairingManager));
        }
        else
        {
            Console.WriteLine("[Agent] Running in console mode. Press Ctrl+C or Enter to exit.");
            var exitEvent = new ManualResetEvent(false);
            Console.CancelKeyPress += (s, e) =>
            {
                e.Cancel = true;
                exitEvent.Set();
            };
            exitEvent.WaitOne();

            Console.WriteLine("[Agent] Shutting down...");
            wsServer.Dispose();
            udpDiscovery.Dispose();
        }
    }

    private static IEnumerable<string> GetLocalIpAddresses()
    {
        var list = new List<string>();
        try
        {
            var host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (var ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(ip))
                {
                    list.Add(ip.ToString());
                }
            }
        }
        catch { }

        return list.Count > 0 ? list : new[] { "127.0.0.1" };
    }
}
