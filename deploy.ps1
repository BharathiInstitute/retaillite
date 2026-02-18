# Deploy script for Tulasi Stores
# Combines marketing website + Flutter web app into /dist folder
# Usage: .\deploy.ps1
# Then run: firebase deploy --only hosting

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tulasi Stores - Deploy Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

$distDir = Join-Path $root "dist"
$websiteDir = Join-Path $root "website"
$flutterBuildDir = Join-Path $root "build\web"

# ─── Step 0: Test Gate — BLOCK deploy if tests fail ───
Write-Host "[0/6] Running tests..." -ForegroundColor Yellow
flutter test --reporter compact
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "  ❌ TESTS FAILED — Deploy blocked!" -ForegroundColor Red
  Write-Host "  Fix the failing tests before deploying." -ForegroundColor Red
  Write-Host ""
  exit 1
}
Write-Host "  ✅ All tests passed" -ForegroundColor Green

# ─── Step 0.5: Analyze Gate — BLOCK deploy if analysis fails ───
Write-Host "[0.5/6] Running analyzer..." -ForegroundColor Yellow
flutter analyze --no-pub
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "  ❌ ANALYSIS FAILED — Deploy blocked!" -ForegroundColor Red
  Write-Host "  Fix the analyzer issues before deploying." -ForegroundColor Red
  Write-Host ""
  exit 1
}
Write-Host "  ✅ No analysis issues" -ForegroundColor Green

# Step 1: Clean dist folder
Write-Host "[1/4] Cleaning dist folder..." -ForegroundColor Yellow
if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
New-Item -ItemType Directory -Path $distDir -Force | Out-Null
Write-Host "  Done." -ForegroundColor Green

# Step 2: Copy marketing website to dist/
Write-Host "[2/4] Copying marketing website..." -ForegroundColor Yellow
if (Test-Path $websiteDir) {
  Copy-Item -Path "$websiteDir\*" -Destination $distDir -Recurse -Force
  Write-Host "  Copied website/ -> dist/" -ForegroundColor Green
}
else {
  Write-Host "  ERROR: website/ folder not found!" -ForegroundColor Red
  exit 1
}

# Step 3: Build & copy Flutter web app to dist/app/
Write-Host "[3/4] Building Flutter web app with --base-href=/app/ ..." -ForegroundColor Yellow
flutter build web --base-href=/app/ --release
if (Test-Path $flutterBuildDir) {
  $appDir = Join-Path $distDir "app"
  New-Item -ItemType Directory -Path $appDir -Force | Out-Null
  Copy-Item -Path "$flutterBuildDir\*" -Destination $appDir -Recurse -Force
  Write-Host "  Copied build/web/ -> dist/app/" -ForegroundColor Green
}
else {
  Write-Host "  WARNING: build/web/ not found. Run 'flutter build web' first." -ForegroundColor Yellow
  Write-Host "  Deploying website only (no /app route)." -ForegroundColor Yellow
}

# Step 3.5: Add serve.json for local preview (preview.ps1)
$serveJsonContent = @'
{
  "rewrites": [
    { "source": "/app/**", "destination": "/app/index.html" }
  ],
  "headers": [
    {
      "source": "**/*",
      "headers": [
        { "key": "Cache-Control", "value": "no-cache" }
      ]
    }
  ]
}
'@
[System.IO.File]::WriteAllText((Join-Path $distDir "serve.json"), $serveJsonContent, [System.Text.UTF8Encoding]::new($false))

# Step 4: Summary
Write-Host ""
Write-Host "[4/4] Build complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  dist/" -ForegroundColor White
Write-Host "    index.html          <- Marketing website" -ForegroundColor Gray
Write-Host "    src/pages/*.html    <- Website pages" -ForegroundColor Gray
Write-Host "    src/css/styles.css  <- Styles" -ForegroundColor Gray
Write-Host "    src/js/main.js      <- Scripts" -ForegroundColor Gray
if (Test-Path $flutterBuildDir) {
  Write-Host "    app/                <- Flutter web app" -ForegroundColor Gray
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Routes:" -ForegroundColor White
Write-Host "  /              -> Marketing website" -ForegroundColor Gray
Write-Host "  /app           -> Flutter billing app" -ForegroundColor Gray
Write-Host ""
Write-Host "Next: Run 'firebase deploy --only hosting'" -ForegroundColor Yellow
