# =============================================================
# Script: ChromeProfile2_DownloadVideos.ps1
# Purpose:
#   - Launch Chrome with TEMP debug profile
#   - Extract open Chrome tabs
#   - Download ONLY 720p videos AND duration >= 20 minutes
#   - Do NOT close tabs if duration < 20 OR no 720p
#   - Close tab only when download success or file already exists
#   - Log failed URLs
# =============================================================

$ChromePath     = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$Endpoint       = "http://127.0.0.1:9222/json"
$UserDir        = "$ENV:USERPROFILE\AppData\Local\Temp\chrome-debug-profile"
$DownloadFolder = "C:\Temp\Downloads"
$FailedFile     = "C:\Temp\Chrome_Failed_download_URLs.txt"

# Ensure folders exist
if (!(Test-Path $UserDir)) { New-Item -ItemType Directory -Path $UserDir | Out-Null }
#if (!(Test-Path $DownloadFolder)) { New-Item -ItemType Directory -Path $DownloadFolder | Out-Null }
if (Test-Path $FailedFile) { Remove-Item $FailedFile -Force }
try {
    if (!(Test-Path -Path $DownloadFolder)) {

        $null = New-Item -ItemType Directory -Path $DownloadFolder -ErrorAction Stop
    }
}
catch {
    Write-Host "Error: Failed to find or create the folder: $DownloadFolder"
    Write-Host "Details: $($_.Exception.Message)"
    exit 1
}


$scriptStart = Get-Date

# -------------------------------------------------------------
# Step 1: Ensure Chrome debugging active
# -------------------------------------------------------------
try {
    Invoke-RestMethod "$Endpoint/version" -TimeoutSec 1 -ErrorAction Stop | Out-Null
    Write-Host "Chrome debugging active." -ForegroundColor Cyan
}
catch {
    Write-Host "Launching Chrome with TEMP debug profile..." -ForegroundColor Yellow

    Start-Process $ChromePath `
        "--user-data-dir=""$($UserDir)"" --remote-debugging-port=9222"

    Write-Host "Open your tabs then press ENTER." -ForegroundColor Cyan
    Read-Host
}

# -------------------------------------------------------------
# Step 2: Extract open tab URLs
# -------------------------------------------------------------
$data = $null
for ($i=0; $i -lt 15; $i++) {
    try {
        $data = Invoke-RestMethod $Endpoint -TimeoutSec 1 -ErrorAction Stop
        break
    } catch { Start-Sleep 1 }
}
if (-not $data) { Write-Host "Cannot connect to Chrome debugging." -ForegroundColor Red; exit }

$tabs = $data | Where-Object {
    $_.type -eq 'page' -and
    $_.url -match '^https?://' -and
    $_.url -notmatch '^chrome://' -and
    $_.url -notmatch '^chrome-extension://'
}

$urls = $tabs.url | Select-Object -Unique
Write-Host "Found $($urls.Count) tabs." -ForegroundColor Cyan

# -------------------------------------------------------------
# Helper: Close Chrome Tab
# -------------------------------------------------------------
function Close-ChromeTab($wsUrl, $url) {
    try {
        if (!$wsUrl) { return }

        $json = '{"id":1,"method":"Page.close"}'
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)

        $client = [Net.WebSockets.ClientWebSocket]::new()
        $client.ConnectAsync([Uri]$wsUrl,[Threading.CancellationToken]::None).Wait()

        $seg = [ArraySegment[byte]]::new($bytes)
        $client.SendAsync($seg,[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).Wait()

        $buff = New-Object byte[] 512
        $seg2 = [ArraySegment[byte]]::new($buff)
        $task = $client.ReceiveAsync($seg2,[Threading.CancellationToken]::None)
        $task.Wait(300) | Out-Null

        $client.CloseAsync([Net.WebSockets.WebSocketCloseStatus]::NormalClosure,"done",[Threading.CancellationToken]::None).Wait()
        $client.Dispose()

        Write-Host "Closed tab: $url" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Could not close tab: $url" -ForegroundColor Yellow
    }
}

# -------------------------------------------------------------
# Helper: Filename sanitization
# -------------------------------------------------------------
function Get-SafeFileName($name) {
    $bad = [IO.Path]::GetInvalidFileNameChars() -join ''
    $pattern = "[{0}]" -f ([Regex]::Escape($bad))
    return ($name -replace $pattern, "_")
}

# -------------------------------------------------------------
# Step 4: Main Download Loop
# -------------------------------------------------------------
$success = 0; $skip = 0; $fail = 0; $filtered = 0

foreach ($tab in $tabs) {
    $url   = $tab.url
    $wsUrl = $tab.webSocketDebuggerUrl

    Write-Host ""
    Write-Host "Checking: $url" -ForegroundColor White

    # Fetch metadata
    $meta = yt-dlp --dump-json --no-warnings "$url" 2>$null | ConvertFrom-Json
    if (-not $meta) {
        Write-Host "Could not extract metadata." -ForegroundColor Red
        Add-Content $FailedFile $url
        $fail++
        continue
    }

    # Duration check (<20 min → skip, KEEP TAB OPEN)
    if ($meta.duration -lt 1200) {
        Write-Host "Skipped: Duration less than 20 minutes (tab left open)." -ForegroundColor Yellow
        $filtered++
        continue
    }

    # Check 720p availability (if missing, DO NOT close tab)
    $has720 = $meta.formats | Where-Object { $_.height -eq 720 } | Select-Object -First 1
    if (-not $has720) {
        Write-Host "Skipped: No 720p available (tab left open)." -ForegroundColor Yellow
        $filtered++
        continue
    }

    # Build safe filename
    $safeName = Get-SafeFileName ($meta.title + ".mp4")
    $output   = Join-Path $DownloadFolder $safeName

    # Already exists → skip + CLOSE TAB
    if (Test-Path $output) {
        Write-Host "Already exists: $safeName" -ForegroundColor Yellow
        $skip++
        Close-ChromeTab $wsUrl $url
        continue
    }

    Write-Host "Downloading 720p: $safeName" -ForegroundColor Cyan

    yt-dlp -N 10 `
        -f "bestvideo[height=720]+bestaudio/best[height=720]" `
        --no-warnings `
        -o "$DownloadFolder\$safeName" `
        "$url"

    if (Test-Path $output) {
        Write-Host "Completed: $safeName" -ForegroundColor Green
        $success++
        Close-ChromeTab $wsUrl $url
    }
    else {
        Write-Host "Failed: $safeName" -ForegroundColor Red
        Add-Content $FailedFile $url
        $fail++
    }
}

# -------------------------------------------------------------
# Summary
# -------------------------------------------------------------
$elapsed = New-TimeSpan $scriptStart (Get-Date)

Write-Host ""
Write-Host "================= SUMMARY =================" -ForegroundColor Cyan
Write-Host "Total tabs:               $($urls.Count)" -ForegroundColor White
Write-Host "Filtered (<20min or no720): $filtered" -ForegroundColor Yellow
Write-Host "Already existed:          $skip" -ForegroundColor Yellow
Write-Host "Downloaded:               $success" -ForegroundColor Green
Write-Host "Failed:                   $fail" -ForegroundColor Red
Write-Host "Time:                     $($elapsed.Minutes)m $($elapsed.Seconds)s" -ForegroundColor Cyan
if (Test-Path $FailedFile) {
    Write-Host "Failed URLs saved:        $FailedFile" -ForegroundColor Yellow
}
Write-Host "===========================================" -ForegroundColor Cyan
