$dotnetRoot = "C:\Users\Zeyrox Viper\AppData\Local\Microsoft\dotnet"
$env:DOTNET_ROOT = $dotnetRoot

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "$dotnetRoot\dotnet.exe"
$psi.Arguments = "run --project `"c:\Users\Zeyrox Viper\Desktop\PC MONITOR\nexus-remote\windows-agent\NexusRemote.Agent.csproj`" -- --console"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)

Start-Sleep -Seconds 4

Write-Host "=== 1. Checking Agent Process Status ==="
Write-Host "Process ID: $($p.Id), HasExited: $($p.HasExited)"

Write-Host "=== 2. Testing HTTP Status Endpoint (Port 48898) ==="
try {
    $tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 48898)
    $stream = $tcp.GetStream()
    $req = [System.Text.Encoding]::ASCII.GetBytes("GET / HTTP/1.1`r`nHost: 127.0.0.1`r`nConnection: close`r`n`r`n")
    $stream.Write($req, 0, $req.Length)
    $reader = New-Object System.IO.StreamReader($stream)
    $res = $reader.ReadToEnd()
    Write-Host "Response:`n$res"
    $tcp.Close()
} catch {
    Write-Host "HTTP error: $($_.Exception.Message)"
}

Write-Host "=== 3. Testing UDP Discovery Request (Port 48899) ==="
try {
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Client.ReceiveTimeout = 3000
    $discoverMsg = '{"version":1,"type":"discover_request","timestamp":1000,"payload":{}}'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($discoverMsg)
    $udp.Send($bytes, $bytes.Length, "127.0.0.1", 48899)
    $remoteEp = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
    $respBytes = $udp.Receive([ref]$remoteEp)
    $respStr = [System.Text.Encoding]::UTF8.GetString($respBytes)
    Write-Host "UDP Discovery Response:`n$respStr"
    $udp.Close()
} catch {
    Write-Host "UDP Discovery error: $($_.Exception.Message)"
}

Write-Host "=== 4. Stopping Agent ==="
$p.Kill()
$p.WaitForExit(3000)
$out = $p.StandardOutput.ReadToEnd()
Write-Host "--- Agent Console Logs ---"
Write-Host $out
