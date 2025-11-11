# =============================================================
# Script: ChromeProfile2_DownloadVideos.ps1
# Purpose: 
#   1. Launch Chrome Profile 2 with remote debugging if not running
#   2. Extract open tab URLs
#   3. Download videos at 720p (or nearest lower)
#   4. Skip downloading if file already exists
# =============================================================

$ChromePath     = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$UserDir        = "$ENV:USERPROFILE\AppData\Local\Temp\chrome-debug-profile"
$Endpoint       = "http://127.0.0.1:9222/json"
$UrlFile        = "C:\Temp\Chrome_Profile_Download_URLs.txt"
$DownloadFolder = "C:\Temp\Downloads"

# Ensure output directories exist
$OutDir = Split-Path $UrlFile
if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
if (!(Test-Path $DownloadFolder)) { New-Item -ItemType Directory -Path $DownloadFolder | Out-Null }

# -------------------------------------------------------------
# Step 1: Check if Chrome debugging already active
# -------------------------------------------------------------
$debugRunning = $false
try {
    $null = Invoke-RestMethod -Uri "$Endpoint/version" -TimeoutSec 1 -ErrorAction Stop
    $debugRunning = $true
}
catch {
    Write-Host "Chrome is not running with remote debugging. Launching Profile 2..."
    Start-Process -FilePath $ChromePath `
        -ArgumentList "--user-data-dir=""$($UserDir)"" --remote-debugging-port=9222"

    Write-Host "After Chrome opens, load your desired tabs, then press ENTER to continue." -ForegroundColor Cyan
    Read-Host
}

# -------------------------------------------------------------
# Step 2: Connect and extract tab information (retry loop)
# -------------------------------------------------------------
$tries = 0
$max   = 15
$data  = $null

do {
    try {
        $data = Invoke-RestMethod -Uri $Endpoint -TimeoutSec 2 -ErrorAction Stop
        break
    } catch {
        Start-Sleep -Seconds 1
        $tries++
    }
} while ($tries -lt $max)

if (-not $data) {
    Write-Host "Chrome remote debugging endpoint did not respond at $Endpoint" -ForegroundColor Red
    exit 1
}

# -------------------------------------------------------------
# Step 3: Extract valid page URLs and save
# -------------------------------------------------------------
$urls = $data |
    Where-Object { $_.type -eq "page" -and $_.url } |
    Select-Object -ExpandProperty url |
    Where-Object { $_ -match '^https?://' -and $_ -notmatch '^chrome://' -and $_ -notmatch '^chrome-extension://' } |
    Select-Object -Unique

if (-not $urls) {
    Write-Host "No usable URLs found in open tabs." -ForegroundColor Red
    exit
}

$urls | Out-File -FilePath $UrlFile -Encoding UTF8
Write-Host "Saved $($urls.Count) URLs to $UrlFile" -ForegroundColor Cyan
Write-Host "Starting download process." -ForegroundColor Cyan

# -------------------------------------------------------------
# Step 4: Process each URL with yt-dlp
# -------------------------------------------------------------
foreach ($url in $urls) {
    Write-Host ""
    Write-Host "Processing URL: $url" -ForegroundColor Cyan

    # Try to detect expected output file
    $videoName = yt-dlp --print "%(title)s.%(ext)s" $url 2>$null
    if (-not $videoName -or $videoName -match "^NA$") {
        Write-Host "Could not extract video title. Skipping." -ForegroundColor Yellow
        continue
    }

    $outputFile = Join-Path $DownloadFolder $videoName

    if (Test-Path $outputFile) {
        Write-Host "File already exists: $videoName" -ForegroundColor DarkGreen
        continue
    }

    Write-Host "Downloading: $videoName" -ForegroundColor Cyan

    yt-dlp `
        -N 10 `
        -S "res:720" `
        -f "bv[height=720]+ba/best[height=720]" `
        -o "$DownloadFolder\%(title)s.%(ext)s" `
        "$url"

    Write-Host "Completed: $videoName" -ForegroundColor Green
}

Write-Host ""
Write-Host "All downloads completed." -ForegroundColor Green

