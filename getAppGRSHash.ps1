#Source https://gist.github.com/ztrhgf
function _getAppGRSHash {
    param (
        [Parameter(Mandatory = $true)]
        [string] $appId
    )

    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | sort LastWriteTime -Descending | select -ExpandProperty FullName

    if (!$intuneLogList) {
        Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
        return
    }

    foreach ($intuneLog in $intuneLogList) {
        $appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\] ExecManager: processing targeted app .+ id='$appId'" -Context 0, 2
        if ($appMatch) {
            foreach ($match in $appMatch) {
                $hash = ([regex]"\d+:Hash = ([^]]+)\]").Matches($match).captures.groups[1].value
                if ($hash) {
                    return $hash
                }
            }
        }
    }

    Write-Error "Unable to find App '$appId' GRS hash in any of the Intune log files. Redeploy will probably not work as expected"
}
