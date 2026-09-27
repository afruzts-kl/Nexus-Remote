using System.Drawing;
using System.Windows.Forms;
using NexusRemote.Agent.Network;
using NexusRemote.Agent.Security;

namespace NexusRemote.Agent.UI;

public class TrayApplicationContext : ApplicationContext
{
    private readonly NotifyIcon _notifyIcon;
    private readonly WebSocketServer _server;
    private readonly UdpDiscoveryServer _discovery;
    private readonly PairingManager _pairingManager;
    private readonly ContextMenuStrip _contextMenu;

    public TrayApplicationContext(
        WebSocketServer server,
        UdpDiscoveryServer discovery,
        PairingManager pairingManager)
    {
        _server = server;
        _discovery = discovery;
        _pairingManager = pairingManager;

        _contextMenu = new ContextMenuStrip();
        BuildMenu();

        _notifyIcon = new NotifyIcon
        {
            Icon = SystemIcons.Shield, // Standard system icon, or generate custom icon
            ContextMenuStrip = _contextMenu,
            Text = $"Nexus Remote (Code: {_pairingManager.CurrentPairingCode})",
            Visible = true
        };

        _notifyIcon.DoubleClick += (s, e) =>
        {
            MessageBox.Show(
                $"Nexus Remote Server Running\n\nPairing Code: {_pairingManager.CurrentPairingCode}\nListening on Port: 48898\nConnected Clients: {_server.ConnectedClientCount}",
                "Nexus Remote",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        };

        _server.ClientConnectionChanged += (endpoint, connected) =>
        {
            _notifyIcon.BalloonTipTitle = "Nexus Remote";
            _notifyIcon.BalloonTipText = connected ? $"Client connected: {endpoint}" : $"Client disconnected: {endpoint}";
            _notifyIcon.ShowBalloonTip(2000);
            _notifyIcon.ContextMenuStrip?.Invoke(new Action(BuildMenu));
        };
    }

    private void BuildMenu()
    {
        _contextMenu.Items.Clear();

        var titleItem = new ToolStripMenuItem($"Nexus Remote - Running") { Enabled = false, Font = new Font(FontFamily.GenericSansSerif, 9, FontStyle.Bold) };
        _contextMenu.Items.Add(titleItem);

        var codeItem = new ToolStripMenuItem($"Pairing Code: {_pairingManager.CurrentPairingCode}");
        codeItem.Click += (s, e) =>
        {
            Clipboard.SetText(_pairingManager.CurrentPairingCode);
            MessageBox.Show($"Pairing Code '{_pairingManager.CurrentPairingCode}' copied to clipboard!", "Nexus Remote", MessageBoxButtons.OK, MessageBoxIcon.Information);
        };
        _contextMenu.Items.Add(codeItem);

        _contextMenu.Items.Add(new ToolStripSeparator());

        var devicesMenu = new ToolStripMenuItem($"Connected Devices ({_server.ConnectedClientCount})");
        if (_server.ConnectedClientCount == 0)
        {
            devicesMenu.DropDownItems.Add(new ToolStripMenuItem("No devices connected") { Enabled = false });
        }
        else
        {
            foreach (var client in _server.ConnectedClients)
            {
                devicesMenu.DropDownItems.Add(new ToolStripMenuItem($"{client.DeviceName} ({client.RemoteEndpoint})") { Enabled = false });
            }
        }
        _contextMenu.Items.Add(devicesMenu);

        var regenItem = new ToolStripMenuItem("Generate New Pairing Code");
        regenItem.Click += (s, e) =>
        {
            _pairingManager.RegeneratePairingCode();
            _notifyIcon.Text = $"Nexus Remote (Code: {_pairingManager.CurrentPairingCode})";
            BuildMenu();
            MessageBox.Show($"New Pairing Code: {_pairingManager.CurrentPairingCode}", "Nexus Remote", MessageBoxButtons.OK, MessageBoxIcon.Information);
        };
        _contextMenu.Items.Add(regenItem);

        _contextMenu.Items.Add(new ToolStripSeparator());

        var exitItem = new ToolStripMenuItem("Exit Nexus Remote");
        exitItem.Click += (s, e) =>
        {
            _notifyIcon.Visible = false;
            _server.Stop();
            _discovery.Stop();
            Application.Exit();
        };
        _contextMenu.Items.Add(exitItem);
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _notifyIcon.Dispose();
            _contextMenu.Dispose();
        }
        base.Dispose(disposing);
    }
}
