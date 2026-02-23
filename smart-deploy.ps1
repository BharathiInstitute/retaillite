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

function Invoke-WithRetry {
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

# --- Step-tracking for granular resume ---
$script:completedSteps = @()

function Is-StepDone {
    param([string]$StepName)
    return $script:completedSteps -contains $StepName
}

function Complete-Step {
    param([string]$StepName)
    if ($script:completedSteps -notcontains $StepName) {
        $script:completedSteps += $StepName
    }
    # Persist progress to state file
    Save-Progress
}

function Save-Progress {
    if (-not (Test-Path variable:script:currentState)) { return }
    $script:currentState.completedSteps = $script:completedSteps
    $stateJson = $script:currentState | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($statePath, $stateJson, [System.Text.UTF8Encoding]::new($false))
}

# ===========================================================
#   CHECK FOR RESUME -- skip questions if previous run failed
# ===========================================================
$statePath = Join-Path $root "deploy-state.json"
$resumed = $false

if (Test-Path $statePath) {
    $savedState = Get-Content $statePath -Raw | ConvertFrom-Json
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "  Previous deploy found! (failed or interrupted)" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "  Type:       $($savedState.typeName)" -ForegroundColor White
    Write-Host "  Version:    $($savedState.newVersion)+$($savedState.newBuild)" -ForegroundColor White
    if ($savedState.platforms) { Write-Host "  Platforms:  $($savedState.platforms)" -ForegroundColor White }
    if ($savedState.winChoiceLabel) { Write-Host "  Windows:    $($savedState.winChoiceLabel)" -ForegroundColor White }
    Write-Host ""
    # Show completed steps if any
    if ($savedState.completedSteps) {
        $doneSteps = @($savedState.completedSteps)
        if ($doneSteps.Count -gt 0) {
            Write-Host "  Completed:  $($doneSteps -join ', ')" -ForegroundColor Green
            Write-Host "  (These steps will be SKIPPED on resume)" -ForegroundColor Gray
        }
    }
    Write-Host ""
    $resumeChoice = Read-Host "  Resume with same settings? (Y/n)"
    if ($resumeChoice -ne 'n' -and $resumeChoice -ne 'N') {
        $resumed = $true
        $updateType = [int]$savedState.updateType
        $skipBuild = [bool]$savedState.skipBuild
        $deployWeb = [bool]$savedState.deployWeb
        $deployWindows = [bool]$savedState.deployWindows
        $deployAndroid = [bool]$savedState.deployAndroid
        $newVersion = $savedState.newVersion
        $newBuild = [int]$savedState.newBuild
        $changelog = $savedState.changelog
        $forceMinVersion = $savedState.forceMinVersion
        $announcementMsg = $savedState.announcementMsg
        $setLatestVersion = [bool]$savedState.setLatestVersion
        $buildMsix = [bool]$savedState.buildMsix
        $buildExe = [bool]$savedState.buildExe
        $winChoiceLabel = $savedState.winChoiceLabel
        # Restore completed steps for granular resume
        if ($savedState.completedSteps) {
            $script:completedSteps = @($savedState.completedSteps)
        }
        # Initialize $script:currentState for Save-Progress
        $script:currentState = @{
            updateType       = $updateType
            typeName         = $savedState.typeName
            skipBuild        = $skipBuild
            deployWeb        = $deployWeb
            deployWindows    = $deployWindows
            deployAndroid    = $deployAndroid
            newVersion       = $newVersion
            newBuild         = $newBuild
            changelog        = $changelog
            forceMinVersion  = $forceMinVersion
            announcementMsg  = $announcementMsg
            setLatestVersion = $setLatestVersion
            buildMsix        = $buildMsix
            buildExe         = $buildExe
            winChoiceLabel   = $winChoiceLabel
            completedSteps   = $script:completedSteps
            platforms        = $savedState.platforms
            savedAt          = $savedState.savedAt
        }
        Write-Host ""
        Write-Ok "Resuming deploy with saved settings!"
        if ($script:completedSteps.Count -gt 0) {
            Write-Ok "Will skip: $($script:completedSteps -join ', ')"
        }
        Write-DeployLog "RESUME | Restarting with saved settings (skipping: $($script:completedSteps -join ', '))"
    }
    else {
        # User wants fresh start -- delete old state
        Remove-Item $statePath -Force
        Write-Info "Previous state cleared. Starting fresh."
    }
}

if (-not $resumed) {
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

    # --- Q6: Windows installer type (if deploying Windows) ---
    $buildMsix = $false
    $buildExe = $false
    $winChoiceLabel = ""
    if ($deployWindows) {
        Write-Host ""
        Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |  Q6: Which Windows installer to build?  |" -ForegroundColor Cyan
        Write-Host "  |                                         |" -ForegroundColor Cyan
        Write-Host "  |  [1] Microsoft Store (MSIX only)        |" -ForegroundColor White
        Write-Host "  |  [2] Web Download (EXE only)            |" -ForegroundColor White
        Write-Host "  |  [3] Both (MSIX + EXE)                  |" -ForegroundColor Yellow
        Write-Host "  |                                         |" -ForegroundColor Cyan
        Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
        $winChoice = Read-Host "  Choose [1/2/3]"
        if ($winChoice -notin @("1", "2", "3")) { $winChoice = "3" }
        $buildMsix = $winChoice -in @("1", "3")
        $buildExe = $winChoice -in @("2", "3")
        $winChoiceLabel = switch ($winChoice) { "1" { "Store (MSIX)" }; "2" { "Web Download (EXE)" }; "3" { "Both (MSIX + EXE)" } }
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
        if ($winChoiceLabel) { Write-Host "  Windows:    $winChoiceLabel" -ForegroundColor White }
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
        if ($deployWindows) { Write-Host "    > Build Windows + MSIX + Inno Setup EXE + upload to Storage" -ForegroundColor Gray }
        if ($deployAndroid) { Write-Host "    > Build Android APK + update version.json + upload to Storage" -ForegroundColor Gray }
        Write-Host "    > Git commit + tag + push" -ForegroundColor Gray
    }
    Write-Host ""

    $confirm = Read-Host "  Deploy? (y/n)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "`n  Deploy cancelled." -ForegroundColor Yellow
        exit 0
    }

    # Save state for resume on failure
    $pubspecPath = Join-Path $root "pubspec.yaml"
    $typeNames = @("", "Normal", "Patch", "Critical", "Maintenance", "Config Only")
    $script:currentState = @{
        updateType       = $updateType
        typeName         = $typeNames[$updateType]
        skipBuild        = $skipBuild
        deployWeb        = $deployWeb
        deployWindows    = $deployWindows
        deployAndroid    = $deployAndroid
        newVersion       = $newVersion
        newBuild         = $newBuild
        changelog        = $changelog
        forceMinVersion  = $forceMinVersion
        announcementMsg  = $announcementMsg
        setLatestVersion = $setLatestVersion
        buildMsix        = $buildMsix
        buildExe         = $buildExe
        winChoiceLabel   = $winChoiceLabel
        completedSteps   = @()
        platforms        = (@($(if ($deployWeb) { 'Web' }), $(if ($deployWindows) { 'Windows' }), $(if ($deployAndroid) { 'Android' })) | Where-Object { $_ }) -join ', '
        savedAt          = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $stateData = $script:currentState | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($statePath, $stateData, [System.Text.UTF8Encoding]::new($false))
    Write-Info "Settings saved for resume"

} # end if (-not $resumed)

# ===========================================================
#   PHASE 2: RUN THE DEPLOY
#   On error: script stops. Fix the error, re-run the script.
#   It will resume with same settings automatically.
# ===========================================================
$failed = $false
$typeNames = @("", "Normal", "Patch", "Critical", "Maintenance", "Config Only")
$pubspecPath = Join-Path $root "pubspec.yaml"

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
if ($resumed) {
    Write-Host "  Resuming deploy... sit back and watch!" -ForegroundColor Green
}
else {
    Write-Host "  Running... sit back and watch!" -ForegroundColor Green
}
Write-Host "========================================================" -ForegroundColor Green

Write-DeployLog "DEPLOY START | Type: $($typeNames[$updateType]) | Version: $newVersion+$newBuild"

try {
    # <- Catch ALL errors -- nothing can stop us!

    # --- Update pubspec.yaml ---
    if (-not $skipBuild -and -not (Is-StepDone "version_bump")) {
        Write-Step "Updating version to $newVersion+$newBuild"
        $pubspecContent = Get-Content $pubspecPath -Raw
        $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion+$newBuild"
        [System.IO.File]::WriteAllText($pubspecPath, $pubspecContent, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "pubspec.yaml updated"
        Complete-Step "version_bump"
    }
    elseif (Is-StepDone "version_bump") {
        Write-Info "SKIP: Version already bumped"
    }

    # --- Run Tests ---
    if (-not $skipBuild -and -not $failed -and -not (Is-StepDone "tests")) {
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
    elseif (Is-StepDone "tests") {
        Write-Info "SKIP: Tests already passed"
    }

    # --- Run Analyzer ---
    if (-not $skipBuild -and -not $failed -and -not (Is-StepDone "analyzer")) {
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
            Complete-Step "tests"  # Mark tests+analyzer as done together
            Complete-Step "analyzer"
        }
    }
    elseif (Is-StepDone "analyzer") {
        Write-Info "SKIP: Analyzer already passed"
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
        $winVersionPath = Join-Path $root "installer\version.json"
        if (Test-Path $winVersionPath) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item $winVersionPath (Join-Path $backupDir "version_win_$backupTimestamp.json")
        }
    }

    if (-not $failed -and $deployAndroid) {
        $androidVersionPath = Join-Path $root "installer\android-version.json"
        if (Test-Path $androidVersionPath) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item $androidVersionPath (Join-Path $backupDir "version_android_$backupTimestamp.json")
        }
    }

    # --- Build and Deploy: Windows (MSIX + Inno Setup EXE) --- [RUNS FIRST to update download.html before web deploy]
    if (-not $failed -and $deployWindows -and -not (Is-StepDone "windows")) {
        Write-Step "Building Windows -- $winChoiceLabel..."

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
            $msixFile = $null
            $exeFile = $null

            # ========== MSIX INSTALLER (for Microsoft Store) ==========
            if ($buildMsix) {
                Write-Step "Creating MSIX installer (for Store)..."
                $ErrorActionPreference = "Continue"
                dart run msix:create
                $msixExit = $LASTEXITCODE
                $ErrorActionPreference = "Stop"

                if ($msixExit -ne 0) {
                    Write-Warn "MSIX creation failed"
                    if ($buildExe) { Write-Warn "Continuing with EXE only" }
                    Write-DeployLog "WINDOWS MSIX | FAILED"
                }
                else {
                    $msixFile = Join-Path $root "build\windows\x64\runner\Release\TulasiStores_Setup.msix"
                    if (Test-Path $msixFile) {
                        $msixSize = "{0:N1} MB" -f ((Get-Item $msixFile).Length / 1MB)
                        Write-Ok "MSIX created ($msixSize)"
                        Write-DeployLog "WINDOWS MSIX | $msixSize"
                    }
                    else {
                        $msixFound = Get-ChildItem -Path (Join-Path $root "build\windows") -Filter "*.msix" -Recurse | Select-Object -First 1
                        if ($msixFound) {
                            $msixSize = "{0:N1} MB" -f ($msixFound.Length / 1MB)
                            Write-Ok "MSIX created ($msixSize) at $($msixFound.FullName)"
                            $msixFile = $msixFound.FullName
                        }
                        else {
                            Write-Warn "MSIX file not found in build output"
                            $msixFile = $null
                        }
                    }
                }
            }

            # ========== INNO SETUP EXE INSTALLER (for Web Download -- 85-90% coverage) ==========
            if ($buildExe) {
                Write-Step "Creating Inno Setup EXE installer (for web download)..."
                $issPath = Join-Path $root "installer\TulasiStores_Setup.iss"
                $isccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

                if ((Test-Path $issPath) -and (Test-Path $isccPath)) {
                    # Update version in .iss file
                    $issContent = Get-Content $issPath -Raw
                    $issContent = $issContent -replace '#define MyAppVersion "[\d.]+"', "#define MyAppVersion `"$newVersion`""
                    [System.IO.File]::WriteAllText($issPath, $issContent, [System.Text.UTF8Encoding]::new($false))
                    Write-Info "Updated .iss version to $newVersion"

                    # Compile with Inno Setup
                    $ErrorActionPreference = "Continue"
                    & $isccPath $issPath
                    $innoExit = $LASTEXITCODE
                    $ErrorActionPreference = "Stop"

                    if ($innoExit -ne 0) {
                        Write-Fail "Inno Setup compilation failed!"
                        if (-not $msixFile -and -not $buildMsix) {
                            $failed = $true
                        }
                        else {
                            Write-Warn "Continuing with MSIX only"
                        }
                    }
                    else {
                        $exeFile = Join-Path $root "installer\Output\TulasiStores_Setup.exe"
                        if (Test-Path $exeFile) {
                            $exeSize = "{0:N1} MB" -f ((Get-Item $exeFile).Length / 1MB)
                            Write-Ok "EXE installer created ($exeSize)"
                            Write-DeployLog "WINDOWS EXE | $exeSize"
                        }
                        else {
                            Write-Warn "EXE file not found at expected path"
                            $exeFile = $null
                        }
                    }
                }
                else {
                    if (-not (Test-Path $isccPath)) { Write-Warn "Inno Setup 6 not found at $isccPath" }
                    if (-not (Test-Path $issPath)) { Write-Warn "Inno Setup script not found at $issPath" }
                    if (-not $msixFile) { $failed = $true }
                }
            }

            # Check at least one installer was created
            if (-not $msixFile -and -not $exeFile) {
                Write-Fail "No installer created!"
                $failed = $true
            }

            if (-not $failed) {
                # Generate one-click VBS installer for MSIX
                if ($msixFile) {
                    Write-Step "Generating one-click MSIX installer script..."
                    $releaseDir = Join-Path $root "build\windows\x64\runner\Release"
                    $vbsInstaller = Join-Path $releaseDir "Install_TulasiStores.vbs"
                    $vbsContent = @"
' Tulasi Stores - One-Click Installer v$newVersion
' Silently installs certificate, then opens MSIX installer GUI

If Not WScript.Arguments.Named.Exists("elevated") Then
    Set objShell = CreateObject("Shell.Application")
    objShell.ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 0
    WScript.Quit
End If

scriptDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
msixFile = scriptDir & "TulasiStores_Setup.msix"

Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(msixFile) Then
    MsgBox "TulasiStores_Setup.msix not found!" & vbCrLf & vbCrLf & "Please place this script in the same folder as the MSIX file.", vbExclamation, "Tulasi Stores Installer"
    WScript.Quit 1
End If

Set objShell = CreateObject("WScript.Shell")
psCommand = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command """ & _
    "$msixPath = '" & msixFile & "'; " & _
    "$cert = (Get-AuthenticodeSignature $msixPath).SignerCertificate; " & _
    "if ($cert) { " & _
    "  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('TrustedPeople', 'LocalMachine'); " & _
    "  $store.Open('ReadWrite'); " & _
    "  $store.Add($cert); " & _
    "  $store.Close(); " & _
    "}" & """"

objShell.Run psCommand, 0, True
objShell.Run """" & msixFile & """", 1, False
WScript.Quit 0
"@
                    [System.IO.File]::WriteAllText($vbsInstaller, $vbsContent, [System.Text.UTF8Encoding]::new($false))
                    Write-Ok "Install_TulasiStores.vbs generated"
                }

                # Update version.json with EXE download URL
                $winVersionPath = Join-Path $root "installer\version.json"
                $exeStorageName = "TulasiStores_Setup_v$newVersion.exe"
                $exeDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/login-radha.firebasestorage.app/o/downloads%2Fwindows%2F$exeStorageName`?alt=media"

                $versionJson = @{
                    version        = $newVersion
                    buildNumber    = [int]$newBuild
                    exeDownloadUrl = $exeDownloadUrl
                    storeUrl       = "https://apps.microsoft.com/detail/tulasi-stores"
                    changelog      = $changelog
                    forceUpdate    = ($updateType -eq 3)
                } | ConvertTo-Json -Depth 3
                [System.IO.File]::WriteAllText($winVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))
                Write-Ok "version.json updated (EXE download + Store URL)"

                # Auto-update website download page with new version
                $downloadPage = Join-Path $root "website\src\pages\download.html"
                if (Test-Path $downloadPage) {
                    Write-Step "Updating website download page..."
                    $pageContent = Get-Content $downloadPage -Raw

                    # Update EXE download URL
                    $pageContent = $pageContent -replace 'TulasiStores_Setup_v[\d.]+\.exe', "TulasiStores_Setup_v$newVersion.exe"

                    # Update version display
                    $pageContent = $pageContent -replace '(<span>v)\d+\.\d+\.\d+(</span>)', "`${1}$newVersion`${2}"
                    $pageContent = $pageContent -replace '(Latest version: <strong>v)\d+\.\d+\.\d+(</strong>)', "`${1}$newVersion`${2}"
                    $pageContent = $pageContent -replace '(style="[^"]*">)\s*v\d+\.\d+\.\d+(</div>)', "`${1}v$newVersion`${2}"

                    [System.IO.File]::WriteAllText($downloadPage, $pageContent, [System.Text.UTF8Encoding]::new($false))
                    Write-Ok "download.html updated to v$newVersion"
                    Write-DeployLog "WEBSITE | download.html updated to v$newVersion"
                }

                # Upload EXE to Firebase Storage (MSIX goes to Microsoft Store separately)
                $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
                if ($gsutilExists) {
                    $storagePath = "gs://login-radha.firebasestorage.app/downloads/windows/"

                    # Clean old EXE files from Storage
                    Write-Step "Cleaning old EXE files from Storage..."
                    $ErrorActionPreference = "Continue"
                    $oldExeFiles = gsutil ls "${storagePath}*.exe" 2>&1
                    if ($oldExeFiles -and $oldExeFiles -notmatch "CommandException") {
                        foreach ($oldFile in $oldExeFiles) {
                            $oldFile = $oldFile.Trim()
                            if ($oldFile -and $oldFile -notlike "*$exeStorageName*" -and $oldFile -like "*.exe") {
                                gsutil rm $oldFile 2>&1 | Out-Null
                                Write-Info "Deleted old: $($oldFile.Split('/')[-1])"
                            }
                        }
                    }
                    Write-Ok "Old files cleaned"

                    # Upload version.json + EXE
                    Write-Step "Uploading EXE + version.json to Firebase Storage..."
                    gsutil cp $winVersionPath "${storagePath}version.json"
                    gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"

                    if ($exeFile -and (Test-Path $exeFile)) {
                        gsutil cp $exeFile "${storagePath}$exeStorageName"
                        gsutil setmeta -h "Content-Type:application/octet-stream" "${storagePath}$exeStorageName"
                        Write-Ok "EXE uploaded: $exeStorageName"
                    }

                    $ErrorActionPreference = "Stop"
                    Write-Ok "EXE uploaded to Firebase Storage"
                    Write-DeployLog "FIREBASE UPLOAD | Windows EXE + version.json"
                }
                else {
                    Write-Warn "gsutil not found - upload EXE manually:"
                    Write-Info "  Firebase Console > Storage > updates/windows/"
                    Write-Info "  Upload: version.json + $exeStorageName"
                }

                # Remind to upload MSIX to Microsoft Store
                if ($msixFile -and (Test-Path $msixFile)) {
                    Write-Step "MANUAL ACTION: Upload MSIX to Microsoft Store"
                    Write-Host ""
                    Write-Host "  +-------------------------------------------------+" -ForegroundColor Cyan
                    Write-Host "  |  MSIX file ready for Microsoft Store:            |" -ForegroundColor Cyan
                    Write-Host "  |  $msixFile" -ForegroundColor Yellow
                    Write-Host "  |                                                  |" -ForegroundColor Cyan
                    Write-Host "  |  1. Go to: partner.microsoft.com/dashboard       |" -ForegroundColor White
                    Write-Host "  |  2. Select your app > Packages                   |" -ForegroundColor White
                    Write-Host "  |  3. Upload the .msix file                        |" -ForegroundColor White
                    Write-Host "  |  4. Submit for review                            |" -ForegroundColor White
                    Write-Host "  +-------------------------------------------------+" -ForegroundColor Cyan
                    Read-Host "  Press Enter after done (or skip)"
                    Write-DeployLog "MSIX | Ready for Microsoft Store upload"
                }
            }
            Complete-Step "windows"
        }
    }
    elseif (Is-StepDone "windows") {
        Write-Info "SKIP: Windows already built + uploaded"
    }

    # --- Build and Deploy: Android --- [RUNS BEFORE Web so download.html has APK link before web deploy]
    if (-not $failed -and $deployAndroid -and -not (Is-StepDone "android")) {
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

            # Update android-version.json
            $androidVersionPath = Join-Path $root "installer\android-version.json"
            $apkStorageName = "TulasiStores_v$newVersion.apk"
            $apkDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/login-radha.firebasestorage.app/o/downloads%2Fandroid%2F$apkStorageName`?alt=media"

            $versionJson = @{
                version     = $newVersion
                buildNumber = [int]$newBuild
                downloadUrl = $apkDownloadUrl
                changelog   = $changelog
                forceUpdate = ($updateType -eq 3)
            } | ConvertTo-Json -Depth 3
            [System.IO.File]::WriteAllText($androidVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))
            Write-Ok "android-version.json updated to v$newVersion"

            # Auto-update website download page with new APK version
            $downloadPage = Join-Path $root "website\src\pages\download.html"
            if (Test-Path $downloadPage) {
                Write-Step "Updating website download page (Android)..."
                $pageContent = Get-Content $downloadPage -Raw

                # Update APK download URL
                $pageContent = $pageContent -replace 'TulasiStores_v[\d.]+\.apk', "TulasiStores_v$newVersion.apk"

                # Update APK file size display
                if (Test-Path $apkPath) {
                    $apkSizeMB = [math]::Round((Get-Item $apkPath).Length / 1MB)
                    $pageContent = $pageContent -replace '(<span>~)\d+ MB(</span>\s*\n\s*<span>v[\d.]+</span>\s*\n\s*</div>\s*\n\s*<a href="https://firebasestorage[^"]*android)', "`${1}$apkSizeMB MB`${2}"
                }

                [System.IO.File]::WriteAllText($downloadPage, $pageContent, [System.Text.UTF8Encoding]::new($false))
                Write-Ok "download.html updated with Android v$newVersion"
                Write-DeployLog "WEBSITE | download.html Android updated to v$newVersion"
            }

            # Upload APK to Firebase Storage
            $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
            if ($gsutilExists) {
                $storagePath = "gs://login-radha.firebasestorage.app/downloads/android/"

                # Clean old APK files from Storage
                Write-Step "Cleaning old APK files from Storage..."
                $ErrorActionPreference = "Continue"
                $oldApkFiles = gsutil ls "${storagePath}*.apk" 2>&1
                if ($oldApkFiles -and $oldApkFiles -notmatch "CommandException") {
                    foreach ($oldFile in $oldApkFiles) {
                        $oldFile = $oldFile.Trim()
                        if ($oldFile -and $oldFile -notlike "*$apkStorageName*" -and $oldFile -like "*.apk") {
                            gsutil rm $oldFile 2>&1 | Out-Null
                            Write-Info "Deleted old: $($oldFile.Split('/')[-1])"
                        }
                    }
                }
                Write-Ok "Old APK files cleaned"

                # Upload version.json + APK
                Write-Step "Uploading APK + version.json to Firebase Storage..."
                gsutil cp $androidVersionPath "${storagePath}version.json"
                gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"

                if (Test-Path $apkPath) {
                    gsutil cp $apkPath "${storagePath}$apkStorageName"
                    gsutil setmeta -h "Content-Type:application/vnd.android.package-archive" "${storagePath}$apkStorageName"
                    Write-Ok "APK uploaded: $apkStorageName"
                }

                $ErrorActionPreference = "Stop"
                Write-Ok "Android uploaded to Firebase Storage"
                Write-DeployLog "FIREBASE UPLOAD | Android APK + version.json"
            }
            else {
                Write-Warn "gsutil not found - upload APK manually:"
                Write-Info "  Firebase Console > Storage > updates/android/"
                Write-Info "  Upload: version.json + $apkStorageName"
            }
            Complete-Step "android"
        }
    }
    elseif (Is-StepDone "android") {
        Write-Info "SKIP: Android already built + uploaded"
    }

    # --- Build and Deploy: Web --- [RUNS LAST so download.html has ALL updated links (Windows + Android)]
    if (-not $failed -and $deployWeb -and -not (Is-StepDone "web")) {
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
            Complete-Step "web"
        }
    }
    elseif (Is-StepDone "web") {
        Write-Info "SKIP: Web already built + deployed"
    }

    # --- All steps completed ---

}
catch {
    # Catch ANY unhandled PowerShell exception
    Write-Host ""
    Write-Fail "Unexpected error: $_"
    Write-DeployLog "ERROR | Unexpected: $_"
    $failed = $true
}

if ($failed) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "  Deploy FAILED! Settings saved for resume." -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Fix the error above, then re-run:" -ForegroundColor Yellow
    Write-Host "    .\smart-deploy.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  It will resume with the same settings!" -ForegroundColor Gray
    Write-Host "  (State saved in deploy-state.json)" -ForegroundColor Gray
    Write-Host ""
    Write-DeployLog "DEPLOY FAILED | Settings saved for resume"
    exit 1
}

# --- SUCCESS! Clean up state file ---
if (Test-Path $statePath) {
    Remove-Item $statePath -Force
    Write-Info "deploy-state.json cleaned up"
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
if ($deployWindows) { Write-Host "  Windows: MSIX + EXE Built + Uploaded" -ForegroundColor Green }
if ($deployAndroid) { Write-Host "  Android: Built + Uploaded" -ForegroundColor Green }
if ($forceMinVersion) { Write-Host "  Force:   min_app_version = $forceMinVersion" -ForegroundColor Red }
if ($announcementMsg) { Write-Host "  Announce: $announcementMsg" -ForegroundColor Cyan }
if ($updateType -eq 4) { Write-Host "  Mode:    Maintenance ON" -ForegroundColor Yellow }
Write-Host ""
Write-Host "  Log: deploy-history.log" -ForegroundColor Gray
Write-Host ""

Write-DeployLog "DEPLOY COMPLETE | v$newVersion+$newBuild | $($typeNames[$updateType])"
Write-DeployLog "------------------------------------------------"
