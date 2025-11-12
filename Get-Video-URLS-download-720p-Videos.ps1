# =============================================================
# Script: ChromeProfile2_DownloadVideos.ps1
# Purpose:
#   1. Launch Chrome Profile 2 with remote debugging if not running
#   2. Extract open tab URLs
#   3. Download videos at 720p (or nearest lower)
#   4. Skip already existing files
#   5. Save failed URLs to C:\Temp\Chrome_Failed_download_URLs.txt
#   6. Close tab automatically if download succeeds
#   7. Display summary report
# =============================================================

$ChromePath     = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$UserDir        = "$ENV:USERPROFILE\AppData\Local\Temp\chrome-debug-profile"
$Endpoint       = "http://127.0.0.1:9222/json"
$UrlFile        = "C:\Temp\Chrome_Profile_Download_URLs.txt"
$DownloadFolder = "C:\Temp\Downloads"
$FailedFile     = "C:\Temp\Chrome_Failed_download_URLs.txt"

# Ensure folders exist
$OutDir = Split-Path $UrlFile
if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
if (!(Test-Path $DownloadFolder)) { New-Item -ItemType Directory -Path $DownloadFolder | Out-Null }
if (Test-Path $FailedFile) { Remove-Item $FailedFile -Force }

$scriptStart = Get-Date

# -------------------------------------------------------------
# Step 1: Ensure Chrome debugging active
# -------------------------------------------------------------
$debugRunning = $false
try {
    $null = Invoke-RestMethod -Uri "$Endpoint/version" -TimeoutSec 1 -ErrorAction Stop
    $debugRunning = $true
}
catch {
    Write-Host "Chrome not running with remote debugging. Launching Profile 2..." -ForegroundColor Yellow
    Start-Process -FilePath $ChromePath -ArgumentList "--user-data-dir=""$($UserDir)"" --remote-debugging-port=9222"
    Write-Host "After Chrome opens, load your desired tabs, then press ENTER to continue." -ForegroundColor Cyan
    Read-Host
}
if ($debugRunning) { Write-Host "Chrome debugging interface already active." -ForegroundColor Cyan }

# -------------------------------------------------------------
# Step 2: Connect & extract open tab URLs
# -------------------------------------------------------------
$tries = 0; $max = 15; $data = $null
do {
    try {
        $data = Invoke-RestMethod -Uri $Endpoint -TimeoutSec 2 -ErrorAction Stop
        break
    } catch { Start-Sleep -Seconds 1; $tries++ }
} while ($tries -lt $max)

if (-not $data) { Write-Host "Could not connect to $Endpoint" -ForegroundColor Red; exit 1 }

$tabs = $data | Where-Object { $_.type -eq "page" -and $_.url -match '^https?://' -and $_.url -notmatch '^chrome://' -and $_.url -notmatch '^chrome-extension://' }
$urls = $tabs | Select-Object -ExpandProperty url -Unique
if (-not $urls) { Write-Host "No usable URLs found." -ForegroundColor Yellow; exit }

$urls | Out-File -FilePath $UrlFile -Encoding UTF8
Write-Host "Found $($urls.Count) open tabs. Starting downloads..." -ForegroundColor Cyan

# -------------------------------------------------------------
# Step 3: Helper functions
# -------------------------------------------------------------
function Close-ChromeTab($wsUrl, $url) {
    try {
        if ($wsUrl) {
            $jsonClose = '{"id":1,"method":"Page.close"}'
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonClose)
            $client = [System.Net.WebSockets.ClientWebSocket]::new()
            $uri = [Uri]$wsUrl
            $client.ConnectAsync($uri, [Threading.CancellationToken]::None).Wait()

            $segment = [System.ArraySegment[byte]]::new($bytes)
            $client.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()

            # Wait briefly for Chrome to process and acknowledge
            $buffer = New-Object byte[] 1024
            $segmentRecv = [System.ArraySegment[byte]]::new($buffer)
            $receiveTask = $client.ReceiveAsync($segmentRecv, [Threading.CancellationToken]::None)
            $receiveTask.Wait(300) | Out-Null

            $client.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", [Threading.CancellationToken]::None).Wait()
            $client.Dispose()

            Write-Host "Closed Chrome tab for: $url" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "Failed to close Chrome tab for: $url ($_)" -ForegroundColor Yellow
    }
}

function Get-SafeFileName($name) {
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $pattern = "[{0}]" -f [Regex]::Escape($invalidChars)
    return ($name -replace $pattern, '_')
}

# -------------------------------------------------------------
# Step 4: Download loop
# -------------------------------------------------------------
$successCount = 0; $skipCount = 0; $failCount = 0

foreach ($tab in $tabs) {
    $url = $tab.url; $wsUrl = $tab.webSocketDebuggerUrl
    Write-Host ""
    Write-Host "Processing: $url" -ForegroundColor White

    $videoName = yt-dlp --print "%(title)s.%(ext)s" $url 2>$null
    if (-not $videoName -or $videoName -match "^NA$") {
        Write-Host "Unable to get video title. Skipping." -ForegroundColor Yellow
        Add-Content -Path $FailedFile -Value $url
        $failCount++
        continue
    }

    $safeName = Get-SafeFileName $videoName
    $outputFile = Join-Path $DownloadFolder $safeName

    if (Test-Path $outputFile) {
        Write-Host "File exists, skipping download: $safeName" -ForegroundColor Yellow
        $skipCount++
        Close-ChromeTab $wsUrl $url
        continue
    }

    Write-Host "Downloading: $safeName" -ForegroundColor Cyan
    try {
        yt-dlp -N 10 `
            -S "res:720" `
            -f "bestvideo[height<=720]+bestaudio/best[height<=720]" `
            --no-warnings --ignore-errors `
            -o "$DownloadFolder\$safeName" "$url"

        if (Test-Path $outputFile) {
            $successCount++
            Write-Host "Completed: $safeName" -ForegroundColor Green
            Close-ChromeTab $wsUrl $url
        } else {
            $failCount++
            Add-Content -Path $FailedFile -Value $url
            Write-Host "Download failed: $safeName" -ForegroundColor Red
        }
    } catch {
        $failCount++
        Add-Content -Path $FailedFile -Value $url
        Write-Host "Error downloading: $safeName" -ForegroundColor Red
    }
}

# -------------------------------------------------------------
# Step 5: Summary
# -------------------------------------------------------------
$scriptEnd = Get-Date
$totalTime = New-TimeSpan -Start $scriptStart -End $scriptEnd

Write-Host ""
Write-Host "================ Download Summary ================" -ForegroundColor Cyan
Write-Host ("Total URLs found:          {0}" -f $urls.Count) -ForegroundColor White
Write-Host ("Successfully downloaded:   {0}" -f $successCount) -ForegroundColor Green
Write-Host ("Skipped (already exist):   {0}" -f $skipCount) -ForegroundColor Yellow
Write-Host ("Failed downloads:          {0}" -f $failCount) -ForegroundColor Red
Write-Host ("Total time taken:          {0} minutes {1} seconds" -f $totalTime.Minutes, $totalTime.Seconds) -ForegroundColor Cyan
Write-Host ("Downloads saved in:        {0}" -f $DownloadFolder) -ForegroundColor White
if (Test-Path $FailedFile) {
    Write-Host ("Failed URLs saved to:      {0}" -f $FailedFile) -ForegroundColor Yellow
}
Write-Host "==================================================" -ForegroundColor Cyan
