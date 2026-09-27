$yes = "y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`n"
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = "C:\src\flutter\bin\flutter.bat"
$processInfo.Arguments = "doctor --android-licenses"
$processInfo.RedirectStandardInput = $true
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($processInfo)
$writer = $p.StandardInput
for ($i = 0; $i -lt 30; $i++) {
    $writer.WriteLine("y")
}
$writer.Flush()
$p.WaitForExit(15000)
$out = $p.StandardOutput.ReadToEnd()
Write-Host $out
