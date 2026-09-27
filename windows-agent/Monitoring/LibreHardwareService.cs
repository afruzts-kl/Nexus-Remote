using LibreHardwareMonitor.Hardware;

namespace NexusRemote.Agent.Monitoring;

public class HardwareVisitor : IVisitor
{
    public void VisitComputer(IComputer computer)
    {
        computer.Traverse(this);
    }

    public void VisitHardware(IHardware hardware)
    {
        hardware.Update();
        foreach (IHardware subHardware in hardware.SubHardware)
        {
            subHardware.Accept(this);
        }
    }

    public void VisitSensor(ISensor sensor) { }
    public void VisitParameter(IParameter parameter) { }
}

public class LibreHardwareService : IDisposable
{
    private static readonly Lazy<LibreHardwareService> _instance = new(() => new LibreHardwareService());
    public static LibreHardwareService Instance => _instance.Value;

    private readonly Computer _computer;
    private readonly HardwareVisitor _visitor = new();
    private readonly object _lock = new();
    private bool _initialized;

    private LibreHardwareService()
    {
        _computer = new Computer
        {
            IsCpuEnabled = true,
            IsGpuEnabled = true,
            IsMemoryEnabled = true,
            IsMotherboardEnabled = true,
            IsControllerEnabled = true,
            IsStorageEnabled = true,
            IsNetworkEnabled = true
        };
    }

    public void Initialize()
    {
        lock (_lock)
        {
            if (_initialized) return;
            try
            {
                _computer.Open();
                _initialized = true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[LibreHardware] Warning initializing hardware sensors: {ex.Message}");
            }
        }
    }

    public void Update()
    {
        lock (_lock)
        {
            if (!_initialized) return;
            try
            {
                _computer.Accept(_visitor);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[LibreHardware] Warning during update: {ex.Message}");
            }
        }
    }

    public Computer Computer => _computer;

    public void Dispose()
    {
        lock (_lock)
        {
            if (_initialized)
            {
                try { _computer.Close(); } catch { }
                _initialized = false;
            }
        }
    }
}
