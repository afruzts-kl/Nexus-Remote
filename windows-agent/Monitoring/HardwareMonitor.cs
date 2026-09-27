using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class HardwareMonitor : IHardwareMonitor
{
    private readonly ICpuMonitor _cpuMonitor;
    private readonly IMemoryMonitor _memoryMonitor;
    private readonly IGpuMonitor _gpuMonitor;
    private readonly IStorageMonitor _storageMonitor;
    private readonly INetworkMonitor _networkMonitor;
    private readonly ISystemInfoMonitor _systemInfoMonitor;
    private bool _initialized;

    public HardwareMonitor(
        ICpuMonitor? cpuMonitor = null,
        IMemoryMonitor? memoryMonitor = null,
        IGpuMonitor? gpuMonitor = null,
        IStorageMonitor? storageMonitor = null,
        INetworkMonitor? networkMonitor = null,
        ISystemInfoMonitor? systemInfoMonitor = null)
    {
        _cpuMonitor = cpuMonitor ?? new CpuMonitor();
        _memoryMonitor = memoryMonitor ?? new MemoryMonitor();
        _gpuMonitor = gpuMonitor ?? new GpuMonitor();
        _storageMonitor = storageMonitor ?? new StorageMonitor();
        _networkMonitor = networkMonitor ?? new NetworkMonitor();
        _systemInfoMonitor = systemInfoMonitor ?? new SystemInfoMonitor();
    }

    public void Initialize()
    {
        if (_initialized) return;

        LibreHardwareService.Instance.Initialize();
        _cpuMonitor.Initialize();
        _memoryMonitor.Initialize();
        _gpuMonitor.Initialize();
        _storageMonitor.Initialize();
        _networkMonitor.Initialize();
        _systemInfoMonitor.Initialize();

        _initialized = true;
    }

    public TelemetryData GetTelemetry()
    {
        Initialize();

        // Update LibreHardwareMonitor sensors
        LibreHardwareService.Instance.Update();

        return new TelemetryData
        {
            Cpu = _cpuMonitor.GetCpuData(),
            Memory = _memoryMonitor.GetMemoryData(),
            Gpu = _gpuMonitor.GetGpuData(),
            Disks = _storageMonitor.GetDisksData(),
            Network = _networkMonitor.GetNetworkData(),
            System = _systemInfoMonitor.GetSystemData()
        };
    }
}
