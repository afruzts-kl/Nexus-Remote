using System.Runtime.InteropServices;

namespace NexusRemote.Agent.Control;

public class KeyboardController
{
    [StructLayout(LayoutKind.Sequential)]
    private struct KEYBDINPUT
    {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct INPUT
    {
        [FieldOffset(0)] public uint type;
        [FieldOffset(8)] public KEYBDINPUT ki;
    }

    private const uint INPUT_KEYBOARD = 1;
    private const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    private const uint KEYEVENTF_KEYUP = 0x0002;
    private const uint KEYEVENTF_UNICODE = 0x0004;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    public void SendText(string text)
    {
        if (string.IsNullOrEmpty(text)) return;

        var inputs = new List<INPUT>();
        foreach (char c in text)
        {
            // Key down
            inputs.Add(new INPUT
            {
                type = INPUT_KEYBOARD,
                ki = new KEYBDINPUT
                {
                    wVk = 0,
                    wScan = c,
                    dwFlags = KEYEVENTF_UNICODE,
                    time = 0,
                    dwExtraInfo = IntPtr.Zero
                }
            });

            // Key up
            inputs.Add(new INPUT
            {
                type = INPUT_KEYBOARD,
                ki = new KEYBDINPUT
                {
                    wVk = 0,
                    wScan = c,
                    dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP,
                    time = 0,
                    dwExtraInfo = IntPtr.Zero
                }
            });
        }

        SendInput((uint)inputs.Count, inputs.ToArray(), Marshal.SizeOf<INPUT>());
    }

    public void SendKey(string key, int vkCode, List<string>? modifiers, string action)
    {
        ushort vk = (ushort)vkCode;
        if (vk == 0)
        {
            vk = MapKeyNameToVk(key);
        }

        var modList = modifiers ?? new List<string>();

        switch (action.ToLowerInvariant())
        {
            case "down":
                SetModifiers(modList, true);
                SendVk(vk, false);
                break;
            case "up":
                SendVk(vk, true);
                SetModifiers(modList, false);
                break;
            case "tap":
            default:
                SetModifiers(modList, true);
                SendVk(vk, false);
                Thread.Sleep(20);
                SendVk(vk, true);
                SetModifiers(modList, false);
                break;
        }
    }

    private void SetModifiers(List<string> modifiers, bool down)
    {
        foreach (var mod in modifiers)
        {
            ushort vk = mod.ToLowerInvariant() switch
            {
                "ctrl" or "control" => 0x11, // VK_CONTROL
                "alt" => 0x12,               // VK_MENU
                "shift" => 0x10,             // VK_SHIFT
                "meta" or "win" => 0x5B,     // VK_LWIN
                _ => 0
            };

            if (vk != 0)
            {
                SendVk(vk, !down);
            }
        }
    }

    private static void SendVk(ushort vk, bool isKeyUp)
    {
        uint flags = isKeyUp ? KEYEVENTF_KEYUP : 0;
        if (IsExtendedKey(vk)) flags |= KEYEVENTF_EXTENDEDKEY;

        var input = new INPUT
        {
            type = INPUT_KEYBOARD,
            ki = new KEYBDINPUT
            {
                wVk = vk,
                wScan = 0,
                dwFlags = flags,
                time = 0,
                dwExtraInfo = IntPtr.Zero
            }
        };

        SendInput(1, new[] { input }, Marshal.SizeOf<INPUT>());
    }

    private static bool IsExtendedKey(ushort vk)
    {
        return vk is 0x21 or 0x22 or 0x23 or 0x24 or 0x25 or 0x26 or 0x27 or 0x28 or 0x2D or 0x2E or 0x5B or 0x5C;
    }

    private static ushort MapKeyNameToVk(string key)
    {
        return key.ToUpperInvariant() switch
        {
            "ENTER" or "RETURN" => 0x0D,
            "BACKSPACE" => 0x08,
            "TAB" => 0x09,
            "ESCAPE" or "ESC" => 0x1B,
            "SPACE" => 0x20,
            "LEFT" => 0x25,
            "UP" => 0x26,
            "RIGHT" => 0x27,
            "DOWN" => 0x28,
            "DELETE" or "DEL" => 0x2E,
            "HOME" => 0x24,
            "END" => 0x23,
            "PAGEUP" => 0x21,
            "PAGEDOWN" => 0x22,
            "F1" => 0x70,
            "F2" => 0x71,
            "F3" => 0x72,
            "F4" => 0x73,
            "F5" => 0x74,
            "F6" => 0x75,
            "F7" => 0x76,
            "F8" => 0x77,
            "F9" => 0x78,
            "F10" => 0x79,
            "F11" => 0x7A,
            "F12" => 0x7B,
            _ => (ushort)(key.Length == 1 ? char.ToUpperInvariant(key[0]) : 0)
        };
    }
}
