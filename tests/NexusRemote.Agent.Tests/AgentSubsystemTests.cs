using NexusRemote.Agent.Control;
using NexusRemote.Agent.Monitoring;
using NexusRemote.Agent.Security;
using NexusRemote.Agent.Streaming;
using Xunit;

namespace NexusRemote.Agent.Tests;

public class AgentSubsystemTests
{
    [Fact]
    public void CpuMonitor_ReturnsRealCpuData()
    {
        var monitor = new CpuMonitor();
        monitor.Initialize();
        var data = monitor.GetCpuData();

        Assert.NotNull(data);
        Assert.True(data.CoreCount > 0, "CPU CoreCount must be > 0");
        Assert.True(data.ThreadCount > 0, "CPU ThreadCount must be > 0");
        Assert.False(string.IsNullOrWhiteSpace(data.Model), "CPU Model should not be empty");
        Assert.True(data.Usage >= 0 && data.Usage <= 100, "CPU Usage should be between 0 and 100%");
    }

    [Fact]
    public void MemoryMonitor_ReturnsRealMemoryData()
    {
        var monitor = new MemoryMonitor();
        monitor.Initialize();
        var data = monitor.GetMemoryData();

        Assert.NotNull(data);
        Assert.True(data.TotalBytes > 1024L * 1024 * 1024, "Total RAM should be > 1GB");
        Assert.True(data.AvailableBytes > 0, "Available RAM should be > 0");
        Assert.True(data.UsagePercentage > 0 && data.UsagePercentage <= 100, "RAM usage % should be 0-100");
    }

    [Fact]
    public void StorageMonitor_ReturnsRealDisks()
    {
        var monitor = new StorageMonitor();
        monitor.Initialize();
        var disks = monitor.GetDisksData();

        Assert.NotEmpty(disks);
        var cDrive = disks.FirstOrDefault(d => d.Drive.StartsWith("C", StringComparison.OrdinalIgnoreCase));
        Assert.NotNull(cDrive);
        Assert.True(cDrive.TotalBytes > 0, "C: Drive total bytes must be > 0");
        Assert.True(cDrive.FreeBytes > 0, "C: Drive free bytes must be > 0");
    }

    [Fact]
    public void NetworkMonitor_ReturnsRealInterface()
    {
        var monitor = new NetworkMonitor();
        monitor.Initialize();
        var data = monitor.GetNetworkData();

        Assert.NotNull(data);
        Assert.False(string.IsNullOrWhiteSpace(data.LocalIp), "Local IP should not be empty");
    }

    [Fact]
    public void PairingManager_HandlesPairingWorkflow()
    {
        var pm = new PairingManager();
        string code = pm.CurrentPairingCode;

        Assert.Equal(6, code.Length);
        Assert.True(int.TryParse(code, out _), "Pairing code must be 6 digits");

        // Validate code
        Assert.True(pm.ValidatePairingCode(code));
        Assert.False(pm.ValidatePairingCode("000000-invalid"));

        // Register device
        string token = pm.RegisterPairedDevice("test-device-1", "Test Android Phone");
        Assert.False(string.IsNullOrWhiteSpace(token));

        // Authenticate device
        Assert.True(pm.AuthenticateDevice("test-device-1", token));
        Assert.False(pm.AuthenticateDevice("test-device-1", "wrong-token"));

        // Revocation
        Assert.True(pm.RevokeDevice("test-device-1"));
        Assert.False(pm.AuthenticateDevice("test-device-1", token));
    }

    [Fact]
    public void ProcessMonitor_ReturnsRunningProcesses()
    {
        var pm = new ProcessMonitor();
        var result = pm.GetProcesses("cpu", 50);

        Assert.NotNull(result);
        Assert.NotEmpty(result.Processes);
        Assert.True(result.TotalCount > 0);

        var first = result.Processes.First();
        Assert.True(first.Pid > 0);
        Assert.False(string.IsNullOrWhiteSpace(first.Name));
    }

    [Fact]
    public void ScreenCaptureService_ProducesValidNxrsFrame()
    {
        using var capture = new ScreenCaptureService();
        capture.SetConfig(0.5, 50);

        byte[]? frame = capture.CaptureFrame(out int w, out int h);

        Assert.NotNull(frame);
        Assert.True(frame.Length > 21, "Frame must contain header + JPEG bytes");
        // Verify NXRS header (0x4E, 0x58, 0x52, 0x53)
        Assert.Equal(0x4E, frame[0]);
        Assert.Equal(0x58, frame[1]);
        Assert.Equal(0x52, frame[2]);
        Assert.Equal(0x53, frame[3]);
        Assert.True(w > 0 && h > 0);
    }
}
