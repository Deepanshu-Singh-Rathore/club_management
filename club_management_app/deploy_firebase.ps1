param (
    [string]$ApiUrl = "",
    [string]$ProjectId = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " ClubSphere - Firebase Hosting Deploy Script " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Check flutter command
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter is not found in PATH. Please ensure Flutter is installed."
    exit 1
}

# 2. Check firebase command
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Warning "Firebase CLI not found in PATH."
    Write-Host "Please install it with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# 3. Prompt for API_URL if not provided
if (-not $ApiUrl) {
    $defaultApi = "http://127.0.0.1:8000/api"
    $inputApi = Read-Host "Enter your Backend API URL (Press Enter for default: $defaultApi)"
    if ($inputApi) {
        $ApiUrl = $inputApi
    } else {
        $ApiUrl = $defaultApi
    }
}

Write-Host "`n[1/3] Building Flutter Web with API_URL=$ApiUrl..." -ForegroundColor Green
flutter build web --release --dart-define=API_URL="$ApiUrl"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter web build failed."
    exit $LASTEXITCODE
}

Write-Host "`n[2/3] Verifying build output in build/web..." -ForegroundColor Green
if (-not (Test-Path "build/web/index.html")) {
    Write-Error "build/web/index.html does not exist. Build may have failed."
    exit 1
}

Write-Host "`n[3/3] Deploying to Firebase Hosting..." -ForegroundColor Green
if ($ProjectId) {
    firebase deploy --only hosting --project $ProjectId
} else {
    firebase deploy --only hosting
}

Write-Host "`nDeployment completed successfully!" -ForegroundColor Cyan
