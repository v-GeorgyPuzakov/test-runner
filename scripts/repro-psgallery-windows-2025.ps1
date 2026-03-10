param(
    [Parameter(Mandatory = $true)]
    [string]$Attempt
)

$ErrorActionPreference = 'Stop'
$logPath = Join-Path $PWD "psgallery-repro-attempt-$Attempt.log"

function Write-Section {
    param([string]$Title)
    "`n========== $Title ==========" | Tee-Object -FilePath $logPath -Append
}

function Write-Line {
    param([string]$Text)
    $Text | Tee-Object -FilePath $logPath -Append
}

function Run-And-Log {
    param(
        [string]$Title,
        [scriptblock]$Script,
        [switch]$ContinueOnError
    )

    Write-Section $Title
    try {
        & $Script 2>&1 | Tee-Object -FilePath $logPath -Append
    }
    catch {
        Write-Line "ERROR: $($_.Exception.Message)"
        if (-not $ContinueOnError) {
            throw
        }
    }
}

Set-Content -Path $logPath -Value "PSGallery repro log. Attempt=$Attempt" -Encoding utf8

Write-Section 'Environment'
Write-Line "Attempt: $Attempt"
Write-Line "Runner: $env:RUNNER_NAME"
Write-Line "ImageOS: $env:ImageOS"
Write-Line "ImageVersion: $env:ImageVersion"
Write-Line "PowerShell: $($PSVersionTable.PSVersion)"
Write-Line "Timestamp (UTC): $(Get-Date -AsUTC -Format 'yyyy-MM-ddTHH:mm:ssZ')"

Run-And-Log -Title 'Get-PSRepository (before install)' -ContinueOnError -Script {
    Get-PSRepository | Format-List *
}

Run-And-Log -Title 'Get-PackageSource (before install)' -ContinueOnError -Script {
    Get-PackageSource | Format-Table -AutoSize
}

Run-And-Log -Title 'Installed PowerShell modules/providers' -ContinueOnError -Script {
    Get-Module -ListAvailable PowerShellGet, PackageManagement | Sort-Object Name, Version | Format-Table Name, Version, Path -AutoSize
    Get-PackageProvider | Format-Table Name, Version, ProviderPath -AutoSize
}

Run-And-Log -Title 'Install-Module (expected to fail when PSGallery missing)' -Script {
    Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force
}

Write-Section 'Result'
Write-Line 'Install-Module succeeded. PSGallery was available on this runner.'