# Smart Deploy Agent v3.0 - Tulasi Stores
# Asks smart questions first, then runs everything automatically
#
# Usage: .\smart-deploy.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

# --- Colors and Helpers ---
function Write-Step { param($msg) Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-Ok { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "  [INFO] $msg" -ForegroundColor Gray }

function Pick {
    param([string]$Question, [string[]]$Options)
    Write-Host ""
    Write-Host "  $Question" -ForegroundColor White
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "    [$($i+1)] $($Options[$i])" -ForegroundColor Yellow
    }
    do {
        $choice = Read-Host "  > Pick"
        $num = [int]$choice
    } while ($num -lt 1 -or $num -gt $Options.Length)
    return $num
}

function Write-DeployLog {
    param([string]$Entry)
    $logPath = Join-Path $root "deploy-history.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Entry" -Encoding UTF8
}

function Run-WithRetry {
    param([string]$StepName, [scriptblock]$Command, [bool]$CleanOnFail = $true)
    $ErrorActionPreference = "Continue"
    & $Command
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($exitCode -eq 0) { return $true }

    Write-Warn "$StepName failed (exit code $exitCode). Auto-fixing..."
    Write-DeployLog "RETRY | $StepName failed, attempting auto-fix"
    if ($CleanOnFail) {
        Write-Info "Running flutter clean..."
        $ErrorActionPreference = "Continue"
        flutter clean 2>&1 | Out-Null
        Write-Info "Running flutter pub get..."
        flutter pub get 2>&1 | Out-Null
        $ErrorActionPreference = "Stop"
    }
    Start-Sleep -Seconds 2
    Write-Info "Retrying $StepName..."
    $ErrorActionPreference = "Continue"
    & $Command
    $exitCode2 = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($exitCode2 -eq 0) {
        Write-Ok "$StepName passed on retry!"
        Write-DeployLog "RETRY | $StepName passed on retry"
        return $true
    }
    Write-Fail "$StepName failed again after retry (exit code $exitCode2)!"
    Write-DeployLog "RETRY | $StepName failed after retry"
    return $false
}

# ===========================================================
#   PHASE 1: ASK ALL QUESTIONS UPFRONT
# ===========================================================
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Tulasi Stores - Smart Deploy Agent v3.0" -ForegroundColor Cyan
Write-Host "  Answer a few questions, then I do the rest!" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# --- Q1: Update type ---
$updateType = Pick "Q1: What type of update?" @(
    "Normal      - feature, minor fix",
    "Patch Fix   - bug fix, quick patch",
    "Critical    - FORCE all users to update",
    "Maintenance - block ALL users temporarily",
    "Config Only - Remote Config change, no code"
)

$skipBuild = ($updateType -eq 4 -or $updateType -eq 5)
$deployWeb = $false
$deployWindows = $false
$deployAndroid = $false

# --- Q2: Platforms ---
if (-not $skipBuild) {
    $platformChoice = Pick "Q2: Deploy to which platforms?" @(
        "Web only",
        "Windows only",
        "Android only",
        "Web + Windows",
        "Web + Android",
        "Windows + Android",
        "All platforms"
    )
    switch ($platformChoice) {
        1 { $deployWeb = $true }
        2 { $deployWindows = $true }
        3 { $deployAndroid = $true }
        4 { $deployWeb = $true; $deployWindows = $true }
        5 { $deployWeb = $true; $deployAndroid = $true }
        6 { $deployWindows = $true; $deployAndroid = $true }
        7 { $deployWeb = $true; $deployWindows = $true; $deployAndroid = $true }
    }
}

# --- Parse current version ---
$pubspecPath = Join-Path $root "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath -Raw
$currentVersion = if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    @{ version = $matches[1]; build = [int]$matches[2] }
}
else {
    @{ version = "1.0.0"; build = 1 }
}

$newVersion = $currentVersion.version
$newBuild = $currentVersion.build

# --- Q3: Version bump ---
if (-not $skipBuild) {
    $parts = $currentVersion.version -split '\.'
    $patchBumped = "$($parts[0]).$($parts[1]).$([int]$parts[2] + 1)"
    $minorBumped = "$($parts[0]).$([int]$parts[1] + 1).0"
    $majorBumped = "$([int]$parts[0] + 1).0.0"
    $buildBumped = $currentVersion.build + 1

    Write-Host ""
    Write-Host "  Current: $($currentVersion.version)+$($currentVersion.build)" -ForegroundColor Gray

    $bumpChoice = Pick "Q3: Version bump?" @(
        "Build only     ($($currentVersion.version)+$buildBumped)",
        "Patch          ($patchBumped+$buildBumped)",
        "Minor          ($minorBumped+$buildBumped)",
        "Major          ($majorBumped+$buildBumped)",
        "Custom         - enter manually"
    )

    $newBuild = $buildBumped
    switch ($bumpChoice) {
        1 { $newVersion = $currentVersion.version }
        2 { $newVersion = $patchBumped }
        3 { $newVersion = $minorBumped }
        4 { $newVersion = $majorBumped }
        5 {
            $newVersion = Read-Host "  Enter version (e.g. 1.2.3)"
            $newBuild = [int](Read-Host "  Enter build number")
        }
    }
}

# --- Q4: Changelog ---
$changelog = ""
if (-not $skipBuild) {
    Write-Host ""
    Write-Host "  Q4: What changed? (one per line, blank to finish)" -ForegroundColor White
    $lines = @()
    while ($true) {
        $line = Read-Host "  *"
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        $lines += "* $line"
    }
    $changelog = $lines -join "`n"
    if ($changelog -eq "") { $changelog = "Bug fixes and improvements" }
}

# --- Q5: Force version (critical only) ---
$forceMinVersion = ""
if ($updateType -eq 3) {
    $forceMinVersion = Read-Host "  Q5: Minimum required version to force? (Enter = $newVersion)"
    if ([string]::IsNullOrWhiteSpace($forceMinVersion)) { $forceMinVersion = $newVersion }
}

# --- Q5/Q6: Announcement (optional) ---
$announcementMsg = ""
$setLatestVersion = $false
if (-not $skipBuild -and $updateType -le 3) {
    $setLatestVersion = $true

    Write-Host ""
    $announcementInput = Read-Host "  Q5: Announcement for ALL users? (Enter = skip)"
    if (-not [string]::IsNullOrWhiteSpace($announcementInput)) {
        $announcementMsg = $announcementInput
    }
}

# ===========================================================
#   CONFIRM - Last chance to cancel
# ===========================================================
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Deploy Plan" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

$typeNames = @("", "Normal", "Patch", "Critical", "Maintenance", "Config Only")
Write-Host "  Type:       $($typeNames[$updateType])" -ForegroundColor White
if (-not $skipBuild) {
    Write-Host "  Version:    $newVersion+$newBuild" -ForegroundColor White
    $platforms = @()
    if ($deployWeb) { $platforms += "Web" }
    if ($deployWindows) { $platforms += "Windows" }
    if ($deployAndroid) { $platforms += "Android" }
    Write-Host "  Platforms:  $($platforms -join ', ')" -ForegroundColor White
    if ($changelog) {
        $previewLen = [Math]::Min(60, $changelog.Length)
        Write-Host "  Changelog:  $($changelog.Substring(0, $previewLen))..." -ForegroundColor Gray
    }
}
if ($forceMinVersion) { Write-Host "  Force min:  v$forceMinVersion" -ForegroundColor Red }
if ($announcementMsg) { Write-Host "  Announce:   $announcementMsg" -ForegroundColor Cyan }
if ($updateType -eq 4) { Write-Host "  Action:     Enable maintenance mode" -ForegroundColor Yellow }

Write-Host ""
Write-Host "  After confirm, I will automatically:" -ForegroundColor Gray
if (-not $skipBuild) {
    Write-Host "    > Run tests + analyzer" -ForegroundColor Gray
    Write-Host "    > Bump version in pubspec.yaml" -ForegroundColor Gray
    Write-Host "    > Backup current deployment" -ForegroundColor Gray
    if ($deployWeb) { Write-Host "    > Build web + deploy to Firebase Hosting + health check" -ForegroundColor Gray }
    if ($deployWindows) { Write-Host "    > Build Windows + update version.json + upload to Storage" -ForegroundColor Gray }
    if ($deployAndroid) { Write-Host "    > Build Android APK + update version.json + upload to Storage" -ForegroundColor Gray }
    Write-Host "    > Git commit + tag + push" -ForegroundColor Gray
}
Write-Host ""

$confirm = Read-Host "  Deploy? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "`n  Deploy cancelled." -ForegroundColor Yellow
    exit 0
}

# ===========================================================
#   PHASE 2: AUTO-RUN EVERYTHING with full restart on error
#   Max 3 attempts. On failure: clean + pub get + restart
# ===========================================================
$maxAttempts = 3
$attempt = 0
$deploySuccess = $false

while ($attempt -lt $maxAttempts -and -not $deploySuccess) {
    $attempt++
    $failed = $false

    if ($attempt -gt 1) {
        Write-Host ""
        Write-Host "========================================================" -ForegroundColor Yellow
        Write-Host "  RESTARTING - Attempt $attempt of $maxAttempts" -ForegroundColor Yellow
        Write-Host "========================================================" -ForegroundColor Yellow
        Write-DeployLog "RESTART | Attempt $attempt of $maxAttempts"

        Write-Step "Cleaning up before retry..."
        $ErrorActionPreference = "Continue"
        flutter clean 2>&1 | Out-Null
        flutter pub get 2>&1 | Out-Null
        $ErrorActionPreference = "Stop"
        Write-Ok "Clean + pub get done"
        Start-Sleep -Seconds 2
    }
    else {
        Write-Host ""
        Write-Host "========================================================" -ForegroundColor Green
        Write-Host "  Running... sit back and watch!" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Green
    }

    Write-DeployLog "DEPLOY START | Attempt $attempt | Type: $($typeNames[$updateType]) | Version: $newVersion+$newBuild"

    # --- Update pubspec.yaml ---
    if (-not $skipBuild) {
        Write-Step "Updating version to $newVersion+$newBuild"
        $pubspecContent = Get-Content $pubspecPath -Raw
        $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion+$newBuild"
        [System.IO.File]::WriteAllText($pubspecPath, $pubspecContent, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "pubspec.yaml updated"
    }

    # --- Run Tests ---
    if (-not $skipBuild -and -not $failed) {
        Write-Step "Running tests..."
        $ErrorActionPreference = "Continue"
        flutter test --reporter compact
        $testExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($testExit -ne 0) {
            Write-Fail "Tests failed!"
            $failed = $true
        }
        else {
            Write-Ok "All tests passed"
            Write-DeployLog "TESTS PASSED"
        }
    }

    # --- Run Analyzer ---
    if (-not $skipBuild -and -not $failed) {
        Write-Step "Running analyzer..."
        $ErrorActionPreference = "Continue"
        flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
        $analyzeExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($analyzeExit -ne 0) {
            Write-Fail "Analysis has real errors!"
            $failed = $true
        }
        else {
            Write-Ok "Analysis passed"
            Write-DeployLog "ANALYSIS PASSED"
        }
    }

    # --- Backup ---
    $backupDir = Join-Path $root "deploy-backups"
    $backupTimestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

    if (-not $failed -and $deployWeb) {
        $distDir = Join-Path $root "dist"
        if (Test-Path $distDir) {
            Write-Step "Backing up current web deployment..."
            $backupPath = Join-Path $backupDir "dist_$backupTimestamp"
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            Copy-Item -Path "$distDir\*" -Destination $backupPath -Recurse -Force
            Write-Ok "Backup saved"
            Write-DeployLog "BACKUP | Web"
        }
    }

    if (-not $failed -and $deployWindows) {
        $winVersionPath = Join-Path $root "installers\version.json"
        if (Test-Path $winVersionPath) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item $winVersionPath (Join-Path $backupDir "version_win_$backupTimestamp.json")
        }
    }

    if (-not $failed -and $deployAndroid) {
        $androidVersionPath = Join-Path $root "installers\android-version.json"
        if (Test-Path $androidVersionPath) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item $androidVersionPath (Join-Path $backupDir "version_android_$backupTimestamp.json")
        }
    }

    # --- Build and Deploy: Web ---
    if (-not $failed -and $deployWeb) {
        Write-Step "Building Web..."
        $distDir = Join-Path $root "dist"
        $websiteDir = Join-Path $root "website"
        $flutterBuildDir = Join-Path $root "build\web"

        if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null

        if (Test-Path $websiteDir) {
            Copy-Item -Path "$websiteDir\*" -Destination $distDir -Recurse -Force
            Write-Ok "Copied website/ to dist/"
        }

        $ErrorActionPreference = "Continue"
        flutter build web --base-href=/app/ --release
        $webExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($webExit -ne 0) {
            Write-Fail "Web build failed!"
            $failed = $true
        }
        else {
            $appDir = Join-Path $distDir "app"
            New-Item -ItemType Directory -Path $appDir -Force | Out-Null
            Copy-Item -Path "$flutterBuildDir\*" -Destination $appDir -Recurse -Force
            Write-Ok "Web built to dist/app/"

            $serveJson = '{"rewrites":[{"source":"/app/**","destination":"/app/index.html"}],"headers":[{"source":"**/*","headers":[{"key":"Cache-Control","value":"no-cache"}]}]}'
            [System.IO.File]::WriteAllText((Join-Path $distDir "serve.json"), $serveJson, [System.Text.UTF8Encoding]::new($false))

            Write-Step "Deploying to Firebase Hosting..."
            $ErrorActionPreference = "Continue"
            firebase deploy --only hosting
            $fbExit = $LASTEXITCODE
            $ErrorActionPreference = "Stop"
            if ($fbExit -eq 0) {
                Write-Ok "Web deployed to Firebase Hosting!"
                Write-DeployLog "WEB DEPLOYED"

                Write-Step "Health check..."
                Start-Sleep -Seconds 5
                $healthUrls = @(
                    "https://login-radha.web.app/",
                    "https://login-radha.web.app/app/"
                )
                foreach ($url in $healthUrls) {
                    try {
                        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
                        if ($response.StatusCode -eq 200) { Write-Ok "$url -> HTTP 200" }
                        else { Write-Warn "$url -> HTTP $($response.StatusCode)" }
                    }
                    catch {
                        Write-Warn "$url -> Could not reach"
                    }
                }
                Write-DeployLog "HEALTH CHECK DONE"
            }
            else {
                Write-Fail "Firebase deploy failed!"
                $failed = $true
            }
        }
    }

    # --- Build and Deploy: Windows (MSIX) ---
    if (-not $failed -and $deployWindows) {
        Write-Step "Building Windows + MSIX installer..."

        # Update MSIX version in pubspec.yaml (MSIX needs x.x.x.0 format)
        $msixVersion = "$newVersion.0"
        $currentPubspec = Get-Content $pubspecPath -Raw
        $currentPubspec = $currentPubspec -replace 'msix_version:\s*\d+\.\d+\.\d+\.\d+', "msix_version: $msixVersion"
        [System.IO.File]::WriteAllText($pubspecPath, $currentPubspec, [System.Text.UTF8Encoding]::new($false))

        # Build Windows release
        $ErrorActionPreference = "Continue"
        flutter build windows --release
        $winExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($winExit -ne 0) {
            Write-Fail "Windows build failed!"
            $failed = $true
        }
        else {
            Write-Ok "Windows built"

            # Create MSIX installer
            Write-Step "Creating MSIX installer..."
            $ErrorActionPreference = "Continue"
            dart run msix:create
            $msixExit = $LASTEXITCODE
            $ErrorActionPreference = "Stop"

            if ($msixExit -ne 0) {
                Write-Fail "MSIX creation failed!"
                $failed = $true
            }
            else {
                $msixFile = Join-Path $root "build\windows\x64\runner\Release\TulasiStores_Setup.msix"
                if (Test-Path $msixFile) {
                    $msixSize = "{0:N1} MB" -f ((Get-Item $msixFile).Length / 1MB)
                    Write-Ok "MSIX created ($msixSize)"
                    Write-DeployLog "WINDOWS MSIX | $msixSize"
                }
                else {
                    # Try alternate location
                    $msixFile = Get-ChildItem -Path (Join-Path $root "build\windows") -Filter "*.msix" -Recurse | Select-Object -First 1
                    if ($msixFile) {
                        $msixSize = "{0:N1} MB" -f ($msixFile.Length / 1MB)
                        Write-Ok "MSIX created ($msixSize) at $($msixFile.FullName)"
                        $msixFile = $msixFile.FullName
                    }
                    else {
                        Write-Warn "MSIX file not found in build output"
                    }
                }

                # Update version.json with MSIX download URL
                $winVersionPath = Join-Path $root "installers\version.json"
                $msixStorageName = "TulasiStores_Setup_v$newVersion.msix"
                $downloadUrl = "https://firebasestorage.googleapis.com/v0/b/login-radha.firebasestorage.app/o/updates%2Fwindows%2F$msixStorageName`?alt=media"

                $versionJson = @{
                    version     = $newVersion
                    buildNumber = [int]$newBuild
                    downloadUrl = $downloadUrl
                    changelog   = $changelog
                    forceUpdate = ($updateType -eq 3)
                } | ConvertTo-Json -Depth 3
                [System.IO.File]::WriteAllText($winVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))
                Write-Ok "version.json updated (MSIX download URL)"

                # Upload to Firebase Storage
                $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
                if ($gsutilExists) {
                    Write-Step "Uploading MSIX + version.json to Firebase Storage..."
                    $storagePath = "gs://login-radha.firebasestorage.app/updates/windows/"
                    $ErrorActionPreference = "Continue"

                    # Upload version.json
                    gsutil cp $winVersionPath "${storagePath}version.json"
                    gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"

                    # Upload MSIX installer
                    if ($msixFile -and (Test-Path $msixFile)) {
                        gsutil cp $msixFile "${storagePath}$msixStorageName"
                        gsutil setmeta -h "Content-Type:application/msix" "${storagePath}$msixStorageName"
                        Write-Ok "MSIX uploaded: $msixStorageName"
                    }

                    $ErrorActionPreference = "Stop"
                    Write-Ok "All Windows files uploaded"
                    Write-DeployLog "FIREBASE UPLOAD | Windows MSIX + version.json"
                }
                else {
                    Write-Warn "gsutil not found - upload manually:"
                    Write-Info "  Firebase Console > Storage > updates/windows/"
                    Write-Info "  Upload: version.json + $msixStorageName"
                }
            }
        }
    }

    # --- Build and Deploy: Android ---
    if (-not $failed -and $deployAndroid) {
        Write-Step "Building Android APK..."
        $ErrorActionPreference = "Continue"
        flutter build apk --release
        $apkExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($apkExit -ne 0) {
            Write-Fail "Android build failed!"
            $failed = $true
        }
        else {
            $apkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
            $apkSize = if (Test-Path $apkPath) { "{0:N1} MB" -f ((Get-Item $apkPath).Length / 1MB) } else { "unknown" }
            Write-Ok "APK built ($apkSize)"
            Write-DeployLog "ANDROID BUILT | $apkSize"

            $androidVersionPath = Join-Path $root "installers\android-version.json"
            $downloadUrl = ""
            if (Test-Path $androidVersionPath) {
                $existingJson = Get-Content $androidVersionPath -Raw | ConvertFrom-Json
                $downloadUrl = $existingJson.downloadUrl
            }
            else {
                $downloadUrl = "https://firebasestorage.googleapis.com/v0/b/login-radha.firebasestorage.app/o/updates%2Fandroid%2FTulasiStores_v$newVersion.apk?alt=media"
            }
            $versionJson = @{
                version     = $newVersion
                buildNumber = $newBuild
                downloadUrl = $downloadUrl
                changelog   = $changelog
                forceUpdate = ($updateType -eq 3)
            } | ConvertTo-Json -Depth 3
            [System.IO.File]::WriteAllText($androidVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))
            Write-Ok "android-version.json updated to v$newVersion"

            $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
            if ($gsutilExists) {
                Write-Step "Uploading Android files..."
                $storagePath = "gs://login-radha.firebasestorage.app/updates/android/"
                $ErrorActionPreference = "Continue"
                gsutil cp $androidVersionPath "${storagePath}version.json"
                gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"
                if (Test-Path $apkPath) {
                    gsutil cp $apkPath "${storagePath}TulasiStores_v$newVersion.apk"
                    Write-Ok "APK uploaded"
                }
                $ErrorActionPreference = "Stop"
                Write-DeployLog "FIREBASE UPLOAD | Android"
            }
            else {
                Write-Warn "gsutil not found - upload manually"
            }
        }
    }

    # --- Check if all passed ---
    if (-not $failed) {
        $deploySuccess = $true
    }
    elseif ($attempt -lt $maxAttempts) {
        Write-Host ""
        Write-Warn "Attempt $attempt failed. Will auto-fix and restart from top..."
        Write-DeployLog "ATTEMPT $attempt FAILED | Restarting..."
    }
    else {
        Write-Host ""
        Write-Fail "ALL $maxAttempts ATTEMPTS FAILED. Deploy aborted."
        Write-DeployLog "DEPLOY ABORTED | All $maxAttempts attempts failed"
        # Revert version
        if (-not $skipBuild) {
            $revertContent = Get-Content $pubspecPath -Raw
            $revertContent = $revertContent -replace "version: $newVersion\+$newBuild", "version: $($currentVersion.version)+$($currentVersion.build)"
            [System.IO.File]::WriteAllText($pubspecPath, $revertContent, [System.Text.UTF8Encoding]::new($false))
            Write-Warn "Reverted pubspec.yaml to $($currentVersion.version)+$($currentVersion.build)"
        }
        exit 1
    }
}

# --- Remote Config (manual Firebase Console action) ---
if ($updateType -eq 3 -and $forceMinVersion) {
    Write-Step "MANUAL ACTION: Set Remote Config"
    Write-Host ""
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Red
    Write-Host "  |  Go to Firebase Console > Remote Config          |" -ForegroundColor Red
    Write-Host "  |  Set: min_app_version = $forceMinVersion                  |" -ForegroundColor Yellow
    Write-Host "  |  Click: Publish Changes                          |" -ForegroundColor Yellow
    Write-Host "  |  WARNING: This BLOCKS users below v$forceMinVersion        |" -ForegroundColor Red
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Red
    Read-Host "  Press Enter after done"
    Write-Ok "Force update configured"
    Write-DeployLog "REMOTE CONFIG | min_app_version = $forceMinVersion"
}

if ($updateType -eq 4) {
    Write-Step "MANUAL ACTION: Enable Maintenance Mode"
    Write-Host ""
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |  Go to Firebase Console > Remote Config          |" -ForegroundColor Yellow
    Write-Host "  |  Set: maintenance_mode = true                    |" -ForegroundColor Yellow
    Write-Host "  |  Click: Publish Changes                          |" -ForegroundColor Yellow
    Write-Host "  |  Set to false when done with maintenance         |" -ForegroundColor Gray
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Yellow
    Read-Host "  Press Enter after done"
    Write-Ok "Maintenance mode enabled"
    Write-DeployLog "REMOTE CONFIG | maintenance_mode = true"
}

# --- Optional Remote Config ---
if ($setLatestVersion -or $announcementMsg) {
    Write-Step "MANUAL ACTION: Update Remote Config"
    Write-Host ""
    Write-Host "  Go to Firebase Console > Remote Config:" -ForegroundColor Yellow
    if ($setLatestVersion) {
        Write-Host "    Set: latest_version = $newVersion" -ForegroundColor Green
        Write-Host "         Users on older versions see Update available banner" -ForegroundColor Gray
    }
    if ($announcementMsg) {
        Write-Host "    Set: announcement = $announcementMsg" -ForegroundColor Cyan
        Write-Host "         ALL users see this banner. Set empty to remove." -ForegroundColor Gray
    }
    Write-Host "    Click: Publish Changes" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter after done"
    Write-Ok "Remote Config updated"
    if ($setLatestVersion) { Write-DeployLog "REMOTE CONFIG | latest_version = $newVersion" }
    if ($announcementMsg) { Write-DeployLog "REMOTE CONFIG | announcement = $announcementMsg" }
}

# --- Git Commit + Tag + Push ---
if (-not $skipBuild) {
    Write-Step "Git commit + tag + push..."
    $ErrorActionPreference = "Continue"
    git add -A 2>&1 | Out-Null
    $commitMsg = switch ($updateType) {
        1 { "release: v$newVersion+$newBuild" }
        2 { "fix: v$newVersion+$newBuild" }
        3 { "CRITICAL: v$newVersion+$newBuild" }
    }
    git commit -m $commitMsg 2>&1 | Out-Null
    git tag "v$newVersion+$newBuild" 2>&1 | Out-Null
    Write-Ok "Committed + tagged: v$newVersion+$newBuild"

    git push 2>&1 | Out-Null
    git push --tags 2>&1 | Out-Null
    Write-Ok "Pushed to remote"
    Write-DeployLog "GIT | Pushed v$newVersion+$newBuild"
    $ErrorActionPreference = "Stop"
}

# --- Cleanup old backups ---
if (Test-Path $backupDir) {
    $backups = Get-ChildItem $backupDir -Directory | Sort-Object Name -Descending
    if ($backups.Count -gt 5) {
        $toDelete = $backups | Select-Object -Skip 5
        foreach ($old in $toDelete) {
            Remove-Item $old.FullName -Recurse -Force
        }
        Write-Info "Cleaned $($toDelete.Count) old backups"
    }
}

# ===========================================================
#   DONE!
# ===========================================================
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Deploy Complete!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""

if (-not $skipBuild) {
    Write-Host "  Version: v$newVersion+$newBuild" -ForegroundColor White
}
Write-Host "  Type:    $($typeNames[$updateType])" -ForegroundColor White

if ($deployWeb) { Write-Host "  Web:     Deployed + Health Checked" -ForegroundColor Green }
if ($deployWindows) { Write-Host "  Windows: Built + Uploaded" -ForegroundColor Green }
if ($deployAndroid) { Write-Host "  Android: Built + Uploaded" -ForegroundColor Green }
if ($forceMinVersion) { Write-Host "  Force:   min_app_version = $forceMinVersion" -ForegroundColor Red }
if ($announcementMsg) { Write-Host "  Announce: $announcementMsg" -ForegroundColor Cyan }
if ($updateType -eq 4) { Write-Host "  Mode:    Maintenance ON" -ForegroundColor Yellow }
Write-Host ""
Write-Host "  Log: deploy-history.log" -ForegroundColor Gray
Write-Host ""

Write-DeployLog "DEPLOY COMPLETE | v$newVersion+$newBuild | $($typeNames[$updateType])"
Write-DeployLog "------------------------------------------------"
