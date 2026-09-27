$ErrorActionPreference = 'Continue'

$sdkRoot = "C:\Android\Sdk"
$cmdlineDir = "$sdkRoot\cmdline-tools"
New-Item -ItemType Directory -Force -Path $cmdlineDir | Out-Null

$zipPath = "$env:TEMP\cmdline-tools.zip"
$zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

Write-Host "Downloading Android Commandline Tools..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

Write-Host "Extracting archive..."
Expand-Archive -Path $zipPath -DestinationPath "$cmdlineDir\temp" -Force
if (Test-Path "$cmdlineDir\latest") {
    Remove-Item -Recurse -Force "$cmdlineDir\latest"
}
Move-Item -Path "$cmdlineDir\temp\cmdline-tools" -Destination "$cmdlineDir\latest" -Force
Remove-Item -Recurse -Force "$cmdlineDir\temp"
Remove-Item -Force $zipPath

Write-Host "Android cmdline-tools installed at $cmdlineDir\latest"

# Configure flutter
& "C:\src\flutter\bin\flutter.bat" config --android-sdk $sdkRoot
Write-Host "Flutter configured with Android SDK at $sdkRoot"
