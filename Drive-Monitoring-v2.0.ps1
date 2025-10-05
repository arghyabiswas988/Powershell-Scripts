<#
.SYNOPSIS
    Sends a storage report of all drives via Gmail every time the system starts.

.DESCRIPTION
    Collects free/used space for all local drives and emails it using Gmail SMTP.
    Works with Gmail App Password (not your normal Gmail password).

=========================================================================================
Create scheduled task
=========================================================================================
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"C:\Scripts\Send-DriveReport.ps1`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "Drive Report on Startup" -Action $Action -Trigger $Trigger -Principal $Principal

#>



# ================================
# CONFIGURATION
# ================================
$ThresholdPercent = 5                     # Alert if below this %
$From            = "yourgmail@gmail.com"  # Sender (your Gmail address)
$To              = "yourgmail@gmail.com"  # Recipient (can be same or different)
$GmailAppPass    = "YOUR_APP_PASSWORD"    # Gmail App Password (not normal password)
$SmtpServer      = "smtp.gmail.com"
$SmtpPort        = 587
$ComputerName    = $env:COMPUTERNAME      # Get current machine name
$DateTime        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# ================================
# COLLECT DRIVE INFO
# ================================
$Drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }

$Report = @()
foreach ($Drive in $Drives) {
    $TotalBytes = ($Drive.Used + $Drive.Free)
    $FreePct = [math]::Round(($Drive.Free / $TotalBytes) * 100, 2)
    $FreeGB  = [math]::Round($Drive.Free / 1GB, 2)
    $UsedGB  = [math]::Round($Drive.Used / 1GB, 2)
    $TotalGB = [math]::Round($TotalBytes / 1GB, 2)

    $Status = if ($FreePct -lt $ThresholdPercent) { "LOW" } else { "OK" }

    $Report += [PSCustomObject]@{
        Drive     = $Drive.Name
        'Total (GB)' = $TotalGB
        'Used (GB)'  = $UsedGB
        'Free (GB)'  = $FreeGB
        'Free (%)'   = "$FreePct%"
        Status    = $Status
    }
}

# ================================
# GENERATE HTML REPORT
# ================================
$HtmlRows = foreach ($Item in $Report) {
    $Color = if ($Item.Status -eq "LOW") { " style='color:red; font-weight:bold;'" } else { "" }
    "<tr$Color><td>$($Item.Drive)</td><td>$($Item.'Total (GB)')</td><td>$($Item.'Used (GB)')</td><td>$($Item.'Free (GB)')</td><td>$($Item.'Free (%)')</td><td>$($Item.Status)</td></tr>"
}

$HtmlBody = @"
<html>
<head>
<style>
table {border-collapse:collapse; width:70%; font-family:Segoe UI,Arial,sans-serif;}
th, td {border:1px solid #ccc; padding:6px 10px; text-align:center;}
th {background-color:#f2f2f2;}
</style>
</head>
<body>
<h3>💻 Drive Space Report - $ComputerName</h3>
<p>Generated on: $DateTime</p>
<table>
<tr><th>Drive</th><th>Total (GB)</th><th>Used (GB)</th><th>Free (GB)</th><th>Free (%)</th><th>Status</th></tr>
$($HtmlRows -join "`n")
</table>
</body>
</html>
"@

# ================================
# SEND EMAIL
# ================================
$Subject = "[$ComputerName] Drive Space Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

$SecurePass = ConvertTo-SecureString $GmailAppPass -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($From, $SecurePass)

try {
    Send-MailMessage -From $From -To $To -Subject $Subject -Body $HtmlBody -BodyAsHtml `
                     -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credential

    Write-Host "✅ Drive space report sent for $ComputerName to $To" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to send email: $($_.Exception.Message)" -ForegroundColor Red
}
