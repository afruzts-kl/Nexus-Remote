$ErrorActionPreference = 'Continue'
$sdkRoot = "C:\Android\Sdk"
$sdkManager = "$sdkRoot\cmdline-tools\latest\bin\sdkmanager.bat"

Write-Host "Accepting licenses and installing Android SDK packages..."
$packages = @("platform-tools", "platforms;android-34", "build-tools;34.0.0")

# Auto accept licenses
cmd /c "echo y | `"$sdkManager`" --sdk_root=`"$sdkRoot`" `"platform-tools`" `"platforms;android-34`" `"build-tools;34.0.0`""
cmd /c "echo y | `"$sdkManager`" --sdk_root=`"$sdkRoot`" --licenses"

Write-Host "Android packages installed successfully."
