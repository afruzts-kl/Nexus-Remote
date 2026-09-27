$licensesDir = "C:\Android\Sdk\licenses"
New-Item -ItemType Directory -Force -Path $licensesDir | Out-Null

$sdkLicense = @"
24333f8a63cbd82a46e19661404ee5a715a0f3ee
8933bad161af4178b1185d1a37fbf41ea5269c55
d56f5187479451eabf01fb78af6dfcb131a6481e
"@
Set-Content -Path "$licensesDir\android-sdk-license" -Value $sdkLicense -Encoding Ascii

$armLicense = @"
d975f751698a77b662f1254ddbeed3901e156fec
"@
Set-Content -Path "$licensesDir\android-sdk-arm-dbt-license" -Value $armLicense -Encoding Ascii

$previewLicense = @"
84831b9409646a918e30573bab4c9c91346d8abd
"@
Set-Content -Path "$licensesDir\android-sdk-preview-license" -Value $previewLicense -Encoding Ascii

Write-Host "Licenses written."

$sdkRoot = "C:\Android\Sdk"
$sdkManager = "$sdkRoot\cmdline-tools\latest\bin\sdkmanager.bat"
& "$sdkManager" --sdk_root="$sdkRoot" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
Write-Host "Installation completed."
