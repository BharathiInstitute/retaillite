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
    & $Command
    if ($LASTEXITCODE -eq 0) { return $true }

    Write-Warn "$StepName failed! Auto-fixing..."
    if ($CleanOnFail) {
        Write-Info "Running flutter clean..."
        flutter clean 2>$null | Out-Null
        Write-Info "Running flutter pub get..."
        flutter pub get 2>$null | Out-Null
    }
    Write-Info "Retrying $StepName..."
    & $Command
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$StepName passed on retry!"
        return $true
    }
    Write-Fail "$StepName failed again after retry!"
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
#   PHASE 2: AUTO-RUN EVERYTHING - no more questions!
# ===========================================================
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Running... sit back and watch!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green

Write-DeployLog "DEPLOY START | Type: $($typeNames[$updateType]) | Version: $newVersion+$newBuild"

# --- Update pubspec.yaml ---
if (-not $skipBuild) {
    Write-Step "Updating version to $newVersion+$newBuild"
    $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion+$newBuild"
    [System.IO.File]::WriteAllText($pubspecPath, $pubspecContent, [System.Text.UTF8Encoding]::new($false))
    Write-Ok "pubspec.yaml updated"
}

# --- Run Tests (with auto-retry) ---
if (-not $skipBuild) {
    Write-Step "Running tests..."
    $testPass = Run-WithRetry "Tests" { flutter test --reporter compact }
    if (-not $testPass) {
        Write-Fail "TESTS FAILED after retry - Deploy blocked!"
        Write-DeployLog "DEPLOY BLOCKED | Tests failed"
        $revertContent = Get-Content $pubspecPath -Raw
        $revertContent = $revertContent -replace "version: $newVersion\+$newBuild", "version: $($currentVersion.version)+$($currentVersion.build)"
        [System.IO.File]::WriteAllText($pubspecPath, $revertContent, [System.Text.UTF8Encoding]::new($false))
        Write-Warn "Reverted pubspec.yaml"
        exit 1
    }
    Write-Ok "All tests passed"
    Write-DeployLog "TESTS PASSED"

    Write-Step "Running analyzer..."
    $analyzePass = Run-WithRetry "Analyzer" { flutter analyze --no-pub }
    if (-not $analyzePass) {
        Write-Fail "ANALYSIS FAILED after retry - Deploy blocked!"
        Write-DeployLog "DEPLOY BLOCKED | Analysis failed"
        exit 1
    }
    Write-Ok "No analysis issues"
    Write-DeployLog "ANALYSIS PASSED"
}

# --- Backup ---
$backupDir = Join-Path $root "deploy-backups"
$backupTimestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

if ($deployWeb) {
    $distDir = Join-Path $root "dist"
    if (Test-Path $distDir) {
        Write-Step "Backing up current web deployment..."
        $backupPath = Join-Path $backupDir "dist_$backupTimestamp"
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        Copy-Item -Path "$distDir\*" -Destination $backupPath -Recurse -Force
        Write-Ok "Backup saved to deploy-backups\dist_$backupTimestamp"
        Write-DeployLog "BACKUP | Web"
    }
}

if ($deployWindows) {
    $winVersionPath = Join-Path $root "installers\version.json"
    if (Test-Path $winVersionPath) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item $winVersionPath (Join-Path $backupDir "version_win_$backupTimestamp.json")
        Write-Ok "Windows version.json backed up"
    }
}

if ($deployAndroid) {
    $androidVersionPath = Join-Path $root "installers\android-version.json"
    if (Test-Path $androidVersionPath) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item $androidVersionPath (Join-Path $backupDir "version_android_$backupTimestamp.json")
        Write-Ok "Android version.json backed up"
    }
}

# --- Build and Deploy: Web ---
if ($deployWeb) {
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

    $webBuildPass = Run-WithRetry "Web build" { flutter build web --base-href=/app/ --release }
    if (-not $webBuildPass) {
        Write-Fail "Web build failed after retry!"
        Write-DeployLog "DEPLOY FAILED | Web build error"
        exit 1
    }
    $appDir = Join-Path $distDir "app"
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    Copy-Item -Path "$flutterBuildDir\*" -Destination $appDir -Recurse -Force
    Write-Ok "Web built to dist/app/"

    $serveJson = '{"rewrites":[{"source":"/app/**","destination":"/app/index.html"}],"headers":[{"source":"**/*","headers":[{"key":"Cache-Control","value":"no-cache"}]}]}'
    [System.IO.File]::WriteAllText((Join-Path $distDir "serve.json"), $serveJson, [System.Text.UTF8Encoding]::new($false))

    Write-Step "Deploying to Firebase Hosting..."
    $deployPass = Run-WithRetry "Firebase deploy" { firebase deploy --only hosting } -CleanOnFail $false
    if ($deployPass) {
        Write-Ok "Web deployed to Firebase Hosting!"
        Write-DeployLog "WEB DEPLOYED"

        Write-Step "Health check..."
        Start-Sleep -Seconds 5

        $healthUrls = @(
            "https://login-radha.web.app/",
            "https://login-radha.web.app/app/"
        )

        $allHealthy = $true
        foreach ($url in $healthUrls) {
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    Write-Ok "$url -> HTTP 200"
                }
                else {
                    Write-Warn "$url -> HTTP $($response.StatusCode)"
                    $allHealthy = $false
                }
            }
            catch {
                Write-Fail "$url -> FAILED"
                $allHealthy = $false
            }
        }

        if ($allHealthy) {
            Write-Ok "Health check passed - site is live!"
            Write-DeployLog "HEALTH CHECK PASSED"
        }
        else {
            Write-Warn "Health check issues - verify manually!"
            Write-DeployLog "HEALTH CHECK WARNING"
            Write-Info "Rollback: copy deploy-backups\dist_$backupTimestamp\* to dist\ then firebase deploy --only hosting"
        }
    }
    else {
        Write-Fail "Firebase deploy failed!"
        Write-DeployLog "DEPLOY FAILED | Firebase Hosting"
    }
}

# --- Build and Deploy: Windows ---
if ($deployWindows) {
    Write-Step "Building Windows..."
    $winBuildPass = Run-WithRetry "Windows build" { flutter build windows --release }
    if (-not $winBuildPass) {
        Write-Fail "Windows build failed after retry!"
        Write-DeployLog "DEPLOY FAILED | Windows build"
    }
    else {
        Write-Ok "Windows built"
        Write-DeployLog "WINDOWS BUILT"

        $winVersionPath = Join-Path $root "installers\version.json"
        $downloadUrl = ""
        if (Test-Path $winVersionPath) {
            $existingJson = Get-Content $winVersionPath -Raw | ConvertFrom-Json
            $downloadUrl = $existingJson.downloadUrl
        }

        $versionJson = @{
            version     = $newVersion
            buildNumber = $newBuild
            downloadUrl = $downloadUrl
            changelog   = $changelog
            forceUpdate = ($updateType -eq 3)
        } | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($winVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "version.json updated to v$newVersion"

        $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
        if ($gsutilExists) {
            Write-Step "Uploading Windows version.json to Firebase Storage..."
            $storagePath = "gs://login-radha.firebasestorage.app/updates/windows/version.json"
            gsutil cp $winVersionPath $storagePath
            gsutil setmeta -h "Cache-Control:no-cache,max-age=0" $storagePath
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "version.json uploaded"
                Write-DeployLog "FIREBASE UPLOAD | Windows version.json"
            }
            else {
                Write-Warn "Upload failed - upload manually to Firebase Console > Storage > updates/windows/"
            }
        }
        else {
            Write-Warn "gsutil not found - upload manually:"
            Write-Info "  Firebase Console > Storage > updates/windows/ > upload version.json + .exe"
        }
    }
}

# --- Build and Deploy: Android ---
if ($deployAndroid) {
    Write-Step "Building Android APK..."
    $apkBuildPass = Run-WithRetry "Android build" { flutter build apk --release }
    if (-not $apkBuildPass) {
        Write-Fail "Android build failed after retry!"
        Write-DeployLog "DEPLOY FAILED | Android build"
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
            Write-Step "Uploading Android files to Firebase Storage..."
            $storagePath = "gs://login-radha.firebasestorage.app/updates/android/"
            gsutil cp $androidVersionPath "${storagePath}version.json"
            gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"

            if (Test-Path $apkPath) {
                $apkStorageName = "TulasiStores_v$newVersion.apk"
                gsutil cp $apkPath "${storagePath}$apkStorageName"
                Write-Ok "APK uploaded: $apkStorageName"
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Android files uploaded"
                Write-DeployLog "FIREBASE UPLOAD | Android version.json + APK"
            }
            else {
                Write-Warn "Upload failed - upload manually"
            }
        }
        else {
            Write-Warn "gsutil not found - upload manually:"
            Write-Info "  Firebase Console > Storage > updates/android/ > upload version.json + APK"
        }
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
    git add -A
    $commitMsg = switch ($updateType) {
        1 { "release: v$newVersion+$newBuild" }
        2 { "fix: v$newVersion+$newBuild" }
        3 { "CRITICAL: v$newVersion+$newBuild" }
    }
    git commit -m $commitMsg
    git tag "v$newVersion+$newBuild"
    Write-Ok "Committed + tagged: v$newVersion+$newBuild"

    git push 2>$null
    git push --tags 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Pushed to remote"
        Write-DeployLog "GIT | Pushed v$newVersion+$newBuild"
    }
    else {
        Write-Warn "Push failed - run git push manually"
    }
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
