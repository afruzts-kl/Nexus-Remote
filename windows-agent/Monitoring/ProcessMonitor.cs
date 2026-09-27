using System.Diagnostics;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class ProcessMonitor
{
    private readonly Dictionary<int, (TimeSpan CpuTime, DateTime Timestamp)> _processTimes = new();
    private readonly object _lock = new();

    public ProcessListResponse GetProcesses(string sortBy = "cpu", int limit = 100)
    {
        var list = new List<ProcessInfoModel>();
        var currentProcesses = Process.GetProcesses();
        long totalMemory = 1;

        try
        {
            var gcMem = GC.GetGCMemoryInfo();
            totalMemory = gcMem.TotalAvailableMemoryBytes > 0 ? gcMem.TotalAvailableMemoryBytes : 16L * 1024 * 1024 * 1024;
        }
        catch { }

        int processorCount = Environment.ProcessorCount;
        var now = DateTime.UtcNow;

        lock (_lock)
        {
            var activePids = new HashSet<int>();

            foreach (var p in currentProcesses)
            {
                activePids.Add(p.Id);
                try
                {
                    double cpuPercent = 0;
                    if (_processTimes.TryGetValue(p.Id, out var prev))
                    {
                        var elapsed = (now - prev.Timestamp).TotalMilliseconds;
                        if (elapsed > 100)
                        {
                            var totalCpu = p.TotalProcessorTime;
                            var cpuDelta = (totalCpu - prev.CpuTime).TotalMilliseconds;
                            cpuPercent = Math.Round((cpuDelta / (elapsed * processorCount)) * 100.0, 1);
                            _processTimes[p.Id] = (totalCpu, now);
                        }
                    }
                    else
                    {
                        try
                        {
                            _processTimes[p.Id] = (p.TotalProcessorTime, now);
                        }
                        catch { }
                    }

                    long ramBytes = p.WorkingSet64;
                    double ramPercent = Math.Round((double)ramBytes / totalMemory * 100.0, 1);

                    list.Add(new ProcessInfoModel
                    {
                        Pid = p.Id,
                        Name = p.ProcessName,
                        CpuPercent = Math.Clamp(cpuPercent, 0, 100),
                        RamBytes = ramBytes,
                        RamPercent = ramPercent,
                        DiskBytesPerSec = 0,
                        NetworkBytesPerSec = 0
                    });
                }
                catch
                {
                    // Access denied for system protected processes (e.g. System, Audiodg, etc.)
                }
                finally
                {
                    p.Dispose();
                }
            }

            // Cleanup exited processes
            var deadPids = _processTimes.Keys.Where(pid => !activePids.Contains(pid)).ToList();
            foreach (var pid in deadPids)
            {
                _processTimes.Remove(pid);
            }
        }

        // Sort based on parameter
        IEnumerable<ProcessInfoModel> query = sortBy.ToLowerInvariant() switch
        {
            "ram" => list.OrderByDescending(p => p.RamBytes),
            "name" => list.OrderBy(p => p.Name),
            _ => list.OrderByDescending(p => p.CpuPercent).ThenByDescending(p => p.RamBytes)
        };

        var selected = query.Take(limit).ToList();
        return new ProcessListResponse
        {
            Processes = selected,
            TotalCount = list.Count
        };
    }

    public bool KillProcess(int pid, out string? error)
    {
        error = null;
        try
        {
            var p = Process.GetProcessById(pid);
            p.Kill(true);
            return true;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }
}
