using System.Runtime.InteropServices;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Monitoring;

public class MemoryMonitor : IMemoryMonitor
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private class MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;

        public MEMORYSTATUSEX()
        {
            dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
        }
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

    public void Initialize()
    {
        // No heavy initialization needed for GlobalMemoryStatusEx
    }

    public MemoryTelemetry GetMemoryData()
    {
        var memStatus = new MEMORYSTATUSEX();
        if (GlobalMemoryStatusEx(memStatus))
        {
            long total = (long)memStatus.ullTotalPhys;
            long avail = (long)memStatus.ullAvailPhys;
            long used = total - avail;
            double percent = total > 0 ? Math.Round((double)used / total * 100.0, 1) : 0;

            long totalPage = (long)memStatus.ullTotalPageFile;
            long availPage = (long)memStatus.ullAvailPageFile;
            double? pagePercent = totalPage > 0 ? Math.Round((double)(totalPage - availPage) / totalPage * 100.0, 1) : null;

            return new MemoryTelemetry
            {
                TotalBytes = total,
                UsedBytes = used,
                AvailableBytes = avail,
                FreeBytes = avail,
                UsagePercentage = percent,
                PageFileUsagePercentage = pagePercent
            };
        }

        return new MemoryTelemetry();
    }
}
