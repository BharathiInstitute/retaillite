# Local preview — mirrors production exactly
# Serves dist/ with SPA rewrite for /app/** (same as Firebase hosting)
# Usage: .\preview.ps1
# Then open http://localhost:9000

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tulasi Stores - Local Preview" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }
$distDir = Join-Path $root "dist"

if (-not (Test-Path $distDir)) {
    Write-Host "  dist/ not found. Running deploy.ps1 first..." -ForegroundColor Yellow
    & (Join-Path $root "deploy.ps1")
}

# Copy serve.json into dist/ if not already there
$serveJson = Join-Path $distDir "serve.json"
if (-not (Test-Path $serveJson)) {
    @'
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
'@ | Set-Content $serveJson -Encoding UTF8
}

Write-Host ""
Write-Host "Routes (same as production):" -ForegroundColor White
Write-Host "  http://localhost:9000/         -> Marketing website" -ForegroundColor Gray
Write-Host "  http://localhost:9000/app/     -> Flutter web app" -ForegroundColor Gray
Write-Host ""
Write-Host "  Website <-> App navigation works exactly like production." -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

npx serve $distDir -l 9000 --no-clipboard
