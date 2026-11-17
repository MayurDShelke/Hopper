<#
.SYNOPSIS
    Downloads and verifies Android Platform Tools and scrcpy for Hopper.
.DESCRIPTION
    Fetches the pinned versions defined in assets/bin/VERSIONS.md, computes their
    SHA-256 hashes, verifies integrity, and places them into assets/bin/.
#>

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$binDir = Join-Path $rootDir "assets\bin"

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

$tools = @(
    @{
        Name = "Platform Tools"
        FileName = "platform-tools-windows.zip"
        Url = "https://dl.google.com/android/repository/platform-tools_r35.0.2-windows.zip"
        ExpectedSha256 = "372097950c05763b3ea5954a1be2e6c888e2bfda48f3b60383ceb9f548d888f4"
    },
    @{
        Name = "scrcpy"
        FileName = "scrcpy-windows.zip"
        Url = "https://github.com/Genymobile/scrcpy/releases/download/v2.7/scrcpy-win64-v2.7.zip"
        ExpectedSha256 = "63c2c1a84f4dc80ad42203bfbe17965b822602165f61df7ebba72051db55d312"
    }
)

foreach ($tool in $tools) {
    $targetPath = Join-Path $binDir $tool.FileName
    Write-Host "Checking $($tool.Name) at $targetPath..." -ForegroundColor Cyan

    $needsDownload = $Force -or (-not (Test-Path $targetPath))

    if (-not $needsDownload) {
        $actualHash = (Get-FileHash -Path $targetPath -Algorithm SHA256).Hash.ToLower()
        if ($actualHash -ne $tool.ExpectedSha256.ToLower()) {
            Write-Warning "Checksum mismatch for existing $($tool.FileName). Re-downloading..."
            $needsDownload = $true
        } else {
            Write-Host "✓ $($tool.Name) is up-to-date and verified." -ForegroundColor Green
        }
    }

    if ($needsDownload) {
        Write-Host "Downloading $($tool.Name) from $($tool.Url)..." -ForegroundColor Yellow
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            Invoke-WebRequest -Uri $tool.Url -OutFile $tempFile -UseBasicParsing
            $actualHash = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLower()

            if ($actualHash -ne $tool.ExpectedSha256.ToLower()) {
                throw "SHA-256 verification failed for $($tool.Name)! Expected $($tool.ExpectedSha256) but got $actualHash."
            }

            Move-Item -Path $tempFile -Destination $targetPath -Force
            Write-Host "✓ Successfully downloaded and verified $($tool.Name)." -ForegroundColor Green
        }
        finally {
            if (Test-Path $tempFile) {
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host "Tool fetch & verification complete!" -ForegroundColor Green
