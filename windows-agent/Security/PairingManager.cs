using System.Security.Cryptography;
using System.Text.Json;
using NexusRemote.Agent.Models;

namespace NexusRemote.Agent.Security;

public class PairingManager
{
    private static readonly string ConfigPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "NexusRemote",
        "agent-config.json"
    );

    private AgentConfig _config;
    private string _currentPairingCode;
    private readonly object _lock = new();

    public event Action<string, string>? DevicePairingRequested;

    public PairingManager()
    {
        _config = LoadConfig();
        _currentPairingCode = GenerateRandomPairingCode();
    }

    public string CurrentPairingCode
    {
        get
        {
            lock (_lock) return _currentPairingCode;
        }
    }

    public void RegeneratePairingCode()
    {
        lock (_lock)
        {
            _currentPairingCode = GenerateRandomPairingCode();
        }
    }

    private static string GenerateRandomPairingCode()
    {
        int code = RandomNumberGenerator.GetInt32(100000, 999999);
        return code.ToString();
    }

    public bool ValidatePairingCode(string code)
    {
        lock (_lock)
        {
            return string.Equals(_currentPairingCode.Trim(), code.Trim(), StringComparison.Ordinal);
        }
    }

    public void NotifyPairingAttempt(string deviceId, string deviceName)
    {
        DevicePairingRequested?.Invoke(deviceId, deviceName);
    }

    public string RegisterPairedDevice(string deviceId, string deviceName)
    {
        lock (_lock)
        {
            byte[] tokenBytes = new byte[32];
            RandomNumberGenerator.Fill(tokenBytes);
            string token = Convert.ToHexString(tokenBytes).ToLowerInvariant();

            var existing = _config.PairedDevices.FirstOrDefault(d => d.DeviceId == deviceId);
            if (existing != null)
            {
                existing.DeviceName = deviceName;
                existing.DeviceToken = token;
                existing.LastConnected = DateTime.UtcNow;
            }
            else
            {
                _config.PairedDevices.Add(new PairedDevice
                {
                    DeviceId = deviceId,
                    DeviceName = deviceName,
                    DeviceToken = token,
                    PairedAt = DateTime.UtcNow,
                    LastConnected = DateTime.UtcNow
                });
            }

            SaveConfig();
            RegeneratePairingCode(); // Cycle pairing code after successful pairing
            return token;
        }
    }

    public bool AuthenticateDevice(string deviceId, string deviceToken)
    {
        lock (_lock)
        {
            var dev = _config.PairedDevices.FirstOrDefault(d => d.DeviceId == deviceId && d.DeviceToken == deviceToken);
            if (dev != null)
            {
                dev.LastConnected = DateTime.UtcNow;
                SaveConfig();
                return true;
            }
            return false;
        }
    }

    public List<PairedDevice> GetPairedDevices()
    {
        lock (_lock)
        {
            return new List<PairedDevice>(_config.PairedDevices);
        }
    }

    public bool RevokeDevice(string deviceId)
    {
        lock (_lock)
        {
            int removed = _config.PairedDevices.RemoveAll(d => d.DeviceId == deviceId);
            if (removed > 0)
            {
                SaveConfig();
                return true;
            }
            return false;
        }
    }

    private static AgentConfig LoadConfig()
    {
        try
        {
            if (File.Exists(ConfigPath))
            {
                string json = File.ReadAllText(ConfigPath);
                var cfg = JsonSerializer.Deserialize<AgentConfig>(json);
                if (cfg != null) return cfg;
            }
        }
        catch { }

        return new AgentConfig();
    }

    private void SaveConfig()
    {
        try
        {
            string dir = Path.GetDirectoryName(ConfigPath)!;
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            string json = JsonSerializer.Serialize(_config, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(ConfigPath, json);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[Config] Error saving config: {ex.Message}");
        }
    }
}
