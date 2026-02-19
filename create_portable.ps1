# Create TulasiStores Portable ZIP
$releaseDir = 'd:\retaillite\build\windows\x64\runner\Release'
$outputZip = 'd:\retaillite\build\TulasiStores_Portable.zip'

# Remove old zip if exists
if (Test-Path $outputZip) { Remove-Item $outputZip -Force }

# Create temp folder
$tempDir = Join-Path $env:TEMP 'TulasiStores'
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copy only runtime files (exclude .msix, .lib, .exp, .bat, .vbs, .zip, .json, installer folder)
$excludeExtensions = @('.msix', '.lib', '.exp', '.bat', '.vbs', '.zip', '.json')
$excludeFolders = @('TulasiStores_Installer')

Get-ChildItem $releaseDir | Where-Object {
    if ($_.PSIsContainer) {
        $excludeFolders -notcontains $_.Name
    }
    else {
        $excludeExtensions -notcontains $_.Extension
    }
} | ForEach-Object {
    Copy-Item $_.FullName -Destination $tempDir -Recurse -Force
}

# Create ZIP
Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

# Cleanup
Remove-Item $tempDir -Recurse -Force

# Report
$size = [math]::Round((Get-Item $outputZip).Length / 1MB, 1)
Write-Host "Done! TulasiStores_Portable.zip created at: $outputZip"
Write-Host "Size: $size MB"
