using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public interface IHardwareMonitor
{
    void Initialize();
    TelemetryData GetTelemetry();
}

public interface ICpuMonitor
{
    void Initialize();
    CpuTelemetry GetCpuData();
}

public interface IMemoryMonitor
{
    void Initialize();
    MemoryTelemetry GetMemoryData();
}

public interface IGpuMonitor
{
    void Initialize();
    GpuTelemetry GetGpuData();
}

public interface IStorageMonitor
{
    void Initialize();
    List<DiskTelemetry> GetDisksData();
}

public interface INetworkMonitor
{
    void Initialize();
    NetworkTelemetry GetNetworkData();
}

public interface ISystemInfoMonitor
{
    void Initialize();
    SystemTelemetry GetSystemData();
}
