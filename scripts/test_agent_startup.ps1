$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "C:\Users\Zeyrox Viper\Desktop\PC MONITOR\nexus-remote\windows-agent\bin\Debug\net8.0-windows\NexusRemote.Agent.exe"
$psi.Arguments = "--console"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)

$p.WaitForExit(4000)

$out = $p.StandardOutput.ReadToEnd()
$err = $p.StandardError.ReadToEnd()

Write-Host "--- STDOUT ---"
Write-Host $out
Write-Host "--- STDERR ---"
Write-Host $err
Write-Host "ExitCode: $($p.ExitCode)"
