<#
.SYNOPSIS
    Shortcut to run build_runner for code generation in Hopper.
#>

[CmdletBinding()]
param(
    [switch]$Watch
)

$ErrorActionPreference = 'Stop'

if ($Watch) {
    Write-Host "Running build_runner in watch mode..." -ForegroundColor Cyan
    dart run build_runner watch --delete-conflicting-outputs
} else {
    Write-Host "Running build_runner build..." -ForegroundColor Cyan
    dart run build_runner build --delete-conflicting-outputs
}
