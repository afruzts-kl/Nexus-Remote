# Nexus Remote Communication Protocol (v1)

## Overview
Nexus Remote utilizes a hybrid discovery and WebSocket protocol for ultra-low latency, bi-directional telemetry and remote control over local area networks (LAN).

- **Discovery Port**: `UDP 48899`
- **Agent Server Port**: `TCP/WebSocket 48898`
- **Transport**: JSON for control and telemetry; Binary WebSocket messages for screen frames.
- **Latency Measurement**: Bidirectional ping/pong with client-side round-trip time (RTT) calculation.

---

## 1. LAN Discovery (UDP)

### Discovery Broadcast (Mobile -> 255.255.255.255:48899)
```json
{
  "version": 1,
  "type": "discover_request",
  "timestamp": 1727420000000,
  "payload": {
    "clientName": "Pixel 8 Pro",
    "clientId": "a8f3b2..."
  }
}
```

### Discovery Response (Agent -> Mobile)
```json
{
  "version": 1,
  "type": "discover_response",
  "timestamp": 1727420000100,
  "payload": {
    "hostname": "Zeyrox-PC",
    "port": 48898,
    "os": "Windows 11 Pro 64-bit",
    "isPaired": false,
    "agentVersion": "1.0.0"
  }
}
```

---

## 2. Pairing & Authentication (WebSocket)

### Step 1: Pair Request (Mobile -> Agent)
```json
{
  "version": 1,
  "type": "pair_request",
  "timestamp": 1727420000200,
  "payload": {
    "deviceId": "client-uuid-1234",
    "deviceName": "Afruz Phone",
    "pairingCode": "739421"
  }
}
```

### Step 2: Pair Response (Agent -> Mobile)
```json
{
  "version": 1,
  "type": "pair_response",
  "timestamp": 1727420000300,
  "payload": {
    "status": "approved", // "approved", "rejected", "invalid_code"
    "deviceToken": "sec_tok_98231...",
    "hostname": "Zeyrox-PC"
  }
}
```

### Step 3: Auth Request (Mobile -> Agent upon reconnect)
```json
{
  "version": 1,
  "type": "auth_request",
  "timestamp": 1727420000400,
  "payload": {
    "deviceId": "client-uuid-1234",
    "deviceToken": "sec_tok_98231..."
  }
}
```

### Step 4: Auth Response (Agent -> Mobile)
```json
{
  "version": 1,
  "type": "auth_response",
  "timestamp": 1727420000500,
  "payload": {
    "success": true,
    "sessionToken": "sess_89412...",
    "serverTime": 1727420000500
  }
}
```

---

## 3. Telemetry Stream (Agent -> Mobile)
Sent at 2–5 Hz intervals:
```json
{
  "version": 1,
  "type": "telemetry",
  "timestamp": 1727420001000,
  "payload": {
    "cpu": {
      "model": "12th Gen Intel(R) Core(TM) i5-12400F",
      "architecture": "x64",
      "usage": 24.5,
      "perCoreUsage": [22.1, 28.0, 19.4, 30.1, 21.0, 26.3, 18.2, 29.0, 20.1, 24.5, 23.0, 27.2],
      "coreCount": 6,
      "threadCount": 12,
      "currentFrequencyMhz": 2500,
      "temperatureC": 48.0,
      "powerWatts": 32.5
    },
    "memory": {
      "totalBytes": 17020755968,
      "usedBytes": 8945200000,
      "availableBytes": 8075555968,
      "usagePercentage": 52.55,
      "pageFileUsagePercentage": 41.2
    },
    "gpu": {
      "name": "NVIDIA GeForce RTX 3050",
      "usage": 35.0,
      "temperatureC": 54.0,
      "vramTotalBytes": 4293918720,
      "vramUsedBytes": 1610612736,
      "fanSpeedPercent": 45,
      "coreClockMhz": 1552,
      "memoryClockMhz": 7000,
      "powerWatts": 65.2
    },
    "disks": [
      {
        "drive": "C:",
        "name": "Local Fixed Disk",
        "type": "SSD",
        "totalBytes": 255555555555,
        "usedBytes": 114437677283,
        "freeBytes": 141117878272,
        "usagePercentage": 44.78,
        "readSpeedBps": 1258291,
        "writeSpeedBps": 4194304,
        "temperatureC": 42.0
      }
    ],
    "network": {
      "interface": "Ethernet",
      "localIp": "192.168.1.15",
      "linkSpeedMbps": 1000,
      "downloadSpeedBps": 1048576,
      "uploadSpeedBps": 262144,
      "totalDownloadedBytes": 524288000,
      "totalUploadedBytes": 104857600
    },
    "system": {
      "uptimeSeconds": 18450,
      "osVersion": "Microsoft Windows 11 Pro 10.0.26200",
      "motherboard": "Standard Motherboard",
      "bios": "AMI BIOS"
    }
  }
}
```

---

## 4. Remote Control Commands (Mobile -> Agent)

### Mouse Movement
```json
{
  "version": 1,
  "type": "mouse_move",
  "timestamp": 1727420002000,
  "payload": {
    "dx": 12.5,
    "dy": -5.2,
    "isRelative": true
  }
}
```

### Mouse Click / Down / Up / Double
```json
{
  "version": 1,
  "type": "mouse_button",
  "timestamp": 1727420002050,
  "payload": {
    "button": "left", // "left", "right", "middle"
    "action": "click" // "click", "down", "up", "double"
  }
}
```

### Mouse Scroll
```json
{
  "version": 1,
  "type": "mouse_scroll",
  "timestamp": 1727420002100,
  "payload": {
    "deltaX": 0,
    "deltaY": -120
  }
}
```

### Keyboard Input
```json
{
  "version": 1,
  "type": "keyboard",
  "timestamp": 1727420002200,
  "payload": {
    "key": "Enter",
    "vkCode": 13,
    "modifiers": ["ctrl", "alt"],
    "action": "tap"
  }
}
```

### Keyboard Text
```json
{
  "version": 1,
  "type": "keyboard_text",
  "timestamp": 1727420002250,
  "payload": {
    "text": "Hello PC"
  }
}
```

### System Commands
```json
{
  "version": 1,
  "type": "system_command",
  "timestamp": 1727420002300,
  "payload": {
    "action": "lock" // "lock", "sleep", "restart", "shutdown", "signout"
  }
}
```

---

## 5. Screen Capture Streaming

### Start Screen Stream
```json
{
  "version": 1,
  "type": "screen_start",
  "timestamp": 1727420003000,
  "payload": {
    "fps": 30,
    "quality": 60,
    "scale": 0.75
  }
}
```

### Binary Frame Packet Format
Sent as a WebSocket binary message:
- Bytes [0..3]: Header Magic `0x4E585253` ("NXRS")
- Bytes [4..7]: 32-bit uint BigEndian Frame Sequence Number
- Bytes [8..15]: 64-bit uint BigEndian Server Timestamp (ms)
- Bytes [16..17]: 16-bit uint BigEndian Frame Width
- Bytes [18..19]: 16-bit uint BigEndian Frame Height
- Bytes [20]: Format byte (1 = JPEG, 2 = WebP)
- Bytes [21..N]: Compressed image bytes.
