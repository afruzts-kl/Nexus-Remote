using System.Runtime.InteropServices;

namespace NexusRemote.Agent.Control;

public class MouseController
{
    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct INPUT
    {
        [FieldOffset(0)] public uint type;
        [FieldOffset(8)] public MOUSEINPUT mi;
    }

    private const uint INPUT_MOUSE = 0;
    private const uint MOUSEEVENTF_MOVE = 0x0001;
    private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    private const uint MOUSEEVENTF_LEFTUP = 0x0004;
    private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    private const uint MOUSEEVENTF_RIGHTUP = 0x0010;
    private const uint MOUSEEVENTF_MIDDLEDOWN = 0x0020;
    private const uint MOUSEEVENTF_MIDDLEUP = 0x0040;
    private const uint MOUSEEVENTF_WHEEL = 0x0800;
    private const uint MOUSEEVENTF_HWHEEL = 0x1000;
    private const uint MOUSEEVENTF_ABSOLUTE = 0x8000;

    [DllImport("user32.dll")]
    private static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    private static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    private const int SM_CXSCREEN = 0;
    private const int SM_CYSCREEN = 1;

    public void MoveRelative(double dx, double dy)
    {
        if (GetCursorPos(out POINT pt))
        {
            int newX = pt.X + (int)Math.Round(dx);
            int newY = pt.Y + (int)Math.Round(dy);
            SetCursorPos(newX, newY);
        }
    }

    public void MoveAbsolute(double normX, double normY)
    {
        int screenW = GetSystemMetrics(SM_CXSCREEN);
        int screenH = GetSystemMetrics(SM_CYSCREEN);
        int x = (int)Math.Round(normX * screenW);
        int y = (int)Math.Round(normY * screenH);
        SetCursorPos(x, y);
    }

    public void ButtonAction(string button, string action)
    {
        uint downFlag = 0;
        uint upFlag = 0;

        switch (button.ToLowerInvariant())
        {
            case "right":
                downFlag = MOUSEEVENTF_RIGHTDOWN;
                upFlag = MOUSEEVENTF_RIGHTUP;
                break;
            case "middle":
                downFlag = MOUSEEVENTF_MIDDLEDOWN;
                upFlag = MOUSEEVENTF_MIDDLEUP;
                break;
            case "left":
            default:
                downFlag = MOUSEEVENTF_LEFTDOWN;
                upFlag = MOUSEEVENTF_LEFTUP;
                break;
        }

        switch (action.ToLowerInvariant())
        {
            case "down":
                SendMouseEvent(downFlag);
                break;
            case "up":
                SendMouseEvent(upFlag);
                break;
            case "double":
                SendMouseEvent(downFlag);
                SendMouseEvent(upFlag);
                Thread.Sleep(30);
                SendMouseEvent(downFlag);
                SendMouseEvent(upFlag);
                break;
            case "click":
            default:
                SendMouseEvent(downFlag);
                SendMouseEvent(upFlag);
                break;
        }
    }

    public void Scroll(int deltaX, int deltaY)
    {
        if (deltaY != 0)
        {
            SendMouseEvent(MOUSEEVENTF_WHEEL, (uint)deltaY);
        }
        if (deltaX != 0)
        {
            SendMouseEvent(MOUSEEVENTF_HWHEEL, (uint)deltaX);
        }
    }

    private static void SendMouseEvent(uint flags, uint data = 0)
    {
        var input = new INPUT
        {
            type = INPUT_MOUSE,
            mi = new MOUSEINPUT
            {
                dwFlags = flags,
                mouseData = data,
                time = 0,
                dwExtraInfo = IntPtr.Zero
            }
        };

        SendInput(1, new[] { input }, Marshal.SizeOf<INPUT>());
    }
}
