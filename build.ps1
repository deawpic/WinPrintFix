<#
.SYNOPSIS
    Deterministic compilation script for WinPrintFix.exe using native Windows csc.exe
#>

[CmdletBinding()]
param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$binDir = Join-Path $scriptDir "bin"
$srcDir = Join-Path $scriptDir "src\csharp"

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

# Locate native Windows csc.exe
$cscCandidates = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

$cscPath = $null
foreach ($cand in $cscCandidates) {
    if (Test-Path $cand) {
        $cscPath = $cand
        break
    }
}

if ($null -eq $cscPath) {
    Write-Error "[ERROR] csc.exe not found in Microsoft.NET Framework directories."
    exit 1
}

Write-Output "[INFO] Using C# Compiler: $cscPath"

$outputExe = Join-Path $binDir "WinPrintFix.exe"
$manifestPath = Join-Path $srcDir "app.manifest"
$sourceFiles = @(
    (Join-Path $srcDir "Program.cs"),
    (Join-Path $srcDir "MainForm.cs")
)

$references = @(
    "System.dll",
    "System.Windows.Forms.dll",
    "System.Drawing.dll",
    "System.ServiceProcess.dll",
    "System.Core.dll"
)

$refArgs = $references | ForEach-Object { "/r:$_" }

$compileArgs = @(
    "/target:winexe",
    "/optimize+",
    "/platform:anycpu",
    "/nologo",
    "/out:$outputExe",
    "/win32manifest:$manifestPath"
) + $refArgs + $sourceFiles

Write-Output "[INFO] Compiling WinPrintFix.exe..."
& $cscPath $compileArgs

if ($LASTEXITCODE -eq 0 -and (Test-Path $outputExe)) {
    $fileInfo = Get-Item $outputExe
    Write-Output "[OK] Compilation successful!"
    Write-Output "[OK] Binary: $($fileInfo.FullName) ($([math]::Round($fileInfo.Length / 1KB, 2)) KB)"
    exit 0
} else {
    Write-Error "[ERROR] Compilation failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}
