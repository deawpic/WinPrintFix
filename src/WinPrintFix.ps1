<#
.SYNOPSIS
    WinPrintFix - Windows Print Spooler & Network Sharing Fix (Pro Suite)
    Pure PowerShell WinForms Implementation
.DESCRIPTION
    Comprehensive GUI utility to resolve network printer sharing errors (0x0000011b, 
    0x00000709, 0x00000bc4, 0x80070035) across Windows 10 and Windows 11 (24H2 - 26H2+).
#>

# ----------------------------------------------------
# 1. Administrator Privilege Elevation Check
# ----------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # If not running in interactive GUI already, relaunch elevated
    $psPath = (Get-Process -Id $PID).Path
    Start-Process -FilePath $psPath -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ----------------------------------------------------
# 2. Assembly Loading & Visual Styles
# ----------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.ServiceProcess

[System.Windows.Forms.Application]::EnableVisualStyles()

# ----------------------------------------------------
# 3. Environment & Version Detection
# ----------------------------------------------------
$regCurrentVersion = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$osDisplayVersion = (Get-ItemProperty $regCurrentVersion).DisplayVersion
$osProductName = (Get-ItemProperty $regCurrentVersion).ProductName
$osBuildNumber = (Get-ItemProperty $regCurrentVersion).CurrentBuildNumber

$versionNum = 0
if ($osDisplayVersion -match "(\d+)") {
    $versionNum = [int]$matches[1]
}

$isModernWin11 = (($osProductName -like "*Windows 11*") -and ($versionNum -ge 24))

# ----------------------------------------------------
# 4. Registry Paths Definition
# ----------------------------------------------------
$PrintPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print"
$LanmanPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
$GroupPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
$PointPrintPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$RpcPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC"
$SpoolPrintersFolder = "$env:SystemRoot\System32\spool\PRINTERS"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$backupsDir = Join-Path $scriptDir "..\backups"
if (-not (Test-Path $backupsDir)) {
    New-Item -ItemType Directory -Path $backupsDir -Force | Out-Null
}

# ----------------------------------------------------
# 5. Core GUI Construction
# ----------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "WinPrintFix - Windows Print Spooler & Network Sharing Fix (Pro Suite v1.1.0)"
$form.Size = New-Object System.Drawing.Size(940, 910)
$form.MinimumSize = New-Object System.Drawing.Size(920, 870)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 250)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10.0)

# Colors
$cPrimary = [System.Drawing.Color]::FromArgb(0, 102, 204)
$cSuccess = [System.Drawing.Color]::FromArgb(40, 167, 69)
$cWarning = [System.Drawing.Color]::FromArgb(255, 153, 0)
$cDanger  = [System.Drawing.Color]::FromArgb(220, 53, 69)
$cDark    = [System.Drawing.Color]::FromArgb(33, 37, 41)
$cWhite   = [System.Drawing.Color]::White

# Header Panel
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock = [System.Windows.Forms.DockStyle]::Top
$pnlHeader.Height = 90
$pnlHeader.BackColor = [System.Drawing.Color]::FromArgb(22, 33, 62)
$form.Controls.Add($pnlHeader)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "WinPrintFix: Universal Print Spooler, Network Sharing & System Optimizer"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13.0, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cWhite
$lblTitle.Location = New-Object System.Drawing.Point(16, 12)
$lblTitle.AutoSize = $true
$pnlHeader.Controls.Add($lblTitle)

$lblSubTitle = New-Object System.Windows.Forms.Label
$modeText = if ($isModernWin11) { "Modern Security Architecture (24H2 - 26H2+ Mode Active)" } else { "Legacy Architecture (Windows 10/11 Compatible Mode)" }
$lblSubTitle.Text = "Detected: $osProductName ($osDisplayVersion, Build $osBuildNumber) | $modeText"
$lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblSubTitle.ForeColor = [System.Drawing.Color]::FromArgb(180, 205, 237)
$lblSubTitle.Location = New-Object System.Drawing.Point(18, 40)
$lblSubTitle.AutoSize = $true
$pnlHeader.Controls.Add($lblSubTitle)

# Status Badge in Header
$lblAdminBadge = New-Object System.Windows.Forms.Label
$lblAdminBadge.Text = "[ ADMINISTRATOR: ACTIVE ]"
$lblAdminBadge.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$lblAdminBadge.ForeColor = [System.Drawing.Color]::FromArgb(72, 239, 128)
$lblAdminBadge.Location = New-Object System.Drawing.Point(18, 63)
$lblAdminBadge.AutoSize = $true
$pnlHeader.Controls.Add($lblAdminBadge)

# Tab Control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(12, 98)
$tabControl.Size = New-Object System.Drawing.Size(900, 515)
$tabControl.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($tabControl)

$tab1 = New-Object System.Windows.Forms.TabPage
$tab1.Text = "1. Universal Fix"
$tab1.BackColor = $cWhite
$tabControl.TabPages.Add($tab1)

$tab2 = New-Object System.Windows.Forms.TabPage
$tab2.Text = "2. Network & Firewall"
$tab2.BackColor = $cWhite
$tabControl.TabPages.Add($tab2)

$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = "3. Driver v3 Helper"
$tab3.BackColor = $cWhite
$tabControl.TabPages.Add($tab3)

$tab4 = New-Object System.Windows.Forms.TabPage
$tab4.Text = "4. Spooler & Export"
$tab4.BackColor = $cWhite
$tabControl.TabPages.Add($tab4)

$tab5 = New-Object System.Windows.Forms.TabPage
$tab5.Text = "5. Windows Update"
$tab5.BackColor = $cWhite
$tabControl.TabPages.Add($tab5)

# Bottom Console Panel
$pnlBottom = New-Object System.Windows.Forms.Panel
$pnlBottom.Location = New-Object System.Drawing.Point(12, 620)
$pnlBottom.Size = New-Object System.Drawing.Size(900, 240)
$pnlBottom.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$form.Controls.Add($pnlBottom)

$lblConsoleTitle = New-Object System.Windows.Forms.Label
$lblConsoleTitle.Text = "Diagnostic Activity Log:"
$lblConsoleTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblConsoleTitle.Location = New-Object System.Drawing.Point(0, 0)
$lblConsoleTitle.AutoSize = $true
$pnlBottom.Controls.Add($lblConsoleTitle)

$btnCopyLog = New-Object System.Windows.Forms.Button
$btnCopyLog.Text = "Copy Log"
$btnCopyLog.Size = New-Object System.Drawing.Size(80, 24)
$btnCopyLog.Location = New-Object System.Drawing.Point(645, 0)
$btnCopyLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$pnlBottom.Controls.Add($btnCopyLog)

$btnExportLog = New-Object System.Windows.Forms.Button
$btnExportLog.Text = "Export..."
$btnExportLog.Size = New-Object System.Drawing.Size(80, 24)
$btnExportLog.Location = New-Object System.Drawing.Point(730, 0)
$btnExportLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$pnlBottom.Controls.Add($btnExportLog)

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Text = "Clear"
$btnClearLog.Size = New-Object System.Drawing.Size(75, 24)
$btnClearLog.Location = New-Object System.Drawing.Point(815, 0)
$btnClearLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$pnlBottom.Controls.Add($btnClearLog)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(0, 26)
$txtLog.Size = New-Object System.Drawing.Size(900, 205)
$txtLog.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)
$txtLog.ReadOnly = $true
$pnlBottom.Controls.Add($txtLog)

# ----------------------------------------------------
# 6. Helper Functions (Logging, Snapshots, Reg, SMB)
# ----------------------------------------------------
function Append-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $color = switch ($Level) {
        "OK"    { [System.Drawing.Color]::FromArgb(40, 167, 69) }
        "WARN"  { [System.Drawing.Color]::FromArgb(217, 119, 6) }
        "ERROR" { [System.Drawing.Color]::FromArgb(220, 53, 69) }
        default { [System.Drawing.Color]::FromArgb(33, 37, 41) }
    }
    
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionLength = 0
    $txtLog.SelectionColor = [System.Drawing.Color]::Gray
    $txtLog.AppendText("[$timestamp] ")
    
    $txtLog.SelectionColor = $color
    $txtLog.AppendText("[$Level] ")
    
    $txtLog.SelectionColor = [System.Drawing.Color]::FromArgb(33, 37, 41)
    $txtLog.AppendText("$Message`n")
    $txtLog.ScrollToCaret()
}

function Get-RegDwordValue {
    param([string]$Path, [string]$Name)
    try {
        if (Test-Path $Path) {
            $val = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            if ($null -ne $val) { return $val }
        }
    } catch {}
    return $null
}

function Set-RegDwordValue {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][int]$Value
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
    } catch {
        Append-Log "Error writing registry DWORD ($Name): $($_.Exception.Message)" "ERROR"
    }
}
Set-Alias -Name Set-RegistryDword -Value Set-RegDwordValue -ErrorAction SilentlyContinue

function Create-SystemSnapshot {
    try {
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $backupFile = Join-Path $backupsDir "print_backup_$timestamp.json"
        
        $smbClient = Get-SmbClientConfiguration -ErrorAction SilentlyContinue
        $smbServer = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
        
        $snap = [PSCustomObject]@{
            Timestamp = (Get-Date).ToString("s")
            OSVersion = $osDisplayVersion
            ProductName = $osProductName
            BuildNumber = $osBuildNumber
            SmbClient = [PSCustomObject]@{
                EnableInsecureGuestLogons = if ($smbClient) { $smbClient.EnableInsecureGuestLogons } else { $null }
                RequireSecuritySignature = if ($smbClient) { $smbClient.RequireSecuritySignature } else { $null }
            }
            SmbServer = [PSCustomObject]@{
                RequireSecuritySignature = if ($smbServer) { $smbServer.RequireSecuritySignature } else { $null }
            }
            Registry = [PSCustomObject]@{
                RpcAuthnLevelPrivacyEnabled = (Get-RegDwordValue $PrintPath "RpcAuthnLevelPrivacyEnabled")
                CopyFilesPolicy = (Get-RegDwordValue $GroupPolicyPath "CopyFilesPolicy")
                NoWarningNoElevationOnInstall = (Get-RegDwordValue $PointPrintPath "NoWarningNoElevationOnInstall")
                NoWarningNoElevationOnUpdate = (Get-RegDwordValue $PointPrintPath "NoWarningNoElevationOnUpdate")
                RestrictDriverInstallationToAdministrators = (Get-RegDwordValue $PointPrintPath "RestrictDriverInstallationToAdministrators")
                RpcClientProtocol = (Get-RegDwordValue $GroupPolicyPath "RpcClientProtocol")
                RpcOverNamedPipes = (Get-RegDwordValue $GroupPolicyPath "RpcOverNamedPipes")
                AllowInsecureGuestAuth = (Get-RegDwordValue $LanmanPath "AllowInsecureGuestAuth")
                RpcProtocols = (Get-RegDwordValue $RpcPolicyPath "RpcProtocols")
                ForceKerberosForRpc = (Get-RegDwordValue $RpcPolicyPath "ForceKerberosForRpc")
                RpcUseNamedPipeProtocol = (Get-RegDwordValue $RpcPolicyPath "RpcUseNamedPipeProtocol")
                RpcAuthentication = (Get-RegDwordValue $RpcPolicyPath "RpcAuthentication")
                RpcTcpPort = (Get-RegDwordValue $RpcPolicyPath "RpcTcpPort")
            }
        }
        
        $json = $snap | ConvertTo-Json -Depth 4
        Set-Content -Path $backupFile -Value $json -Encoding UTF8
        Append-Log "Safety snapshot saved: $backupFile" "OK"
        return $backupFile
    } catch {
        Append-Log "Failed to create snapshot: $($_.Exception.Message)" "WARN"
        return $null
    }
}

# ----------------------------------------------------
# 7. TAB 1: Universal Fix & Real-time Scanner Setup
# ----------------------------------------------------
# Scanner GroupBox
$grpScanner = New-Object System.Windows.Forms.GroupBox
$grpScanner.Text = "System Configuration & Diagnostics Scanner"
$grpScanner.Location = New-Object System.Drawing.Point(12, 10)
$grpScanner.Size = New-Object System.Drawing.Size(788, 205)
$grpScanner.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$tab1.Controls.Add($grpScanner)

# List of Diagnostic Items (ListView)
$lstDiag = New-Object System.Windows.Forms.ListView
$lstDiag.Location = New-Object System.Drawing.Point(12, 24)
$lstDiag.Size = New-Object System.Drawing.Size(762, 140)
$lstDiag.View = [System.Windows.Forms.View]::Details
$lstDiag.FullRowSelect = $true
$lstDiag.GridLines = $true
$lstDiag.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpScanner.Controls.Add($lstDiag)

$col1 = $lstDiag.Columns.Add("Parameter / Setting", 260)
$col2 = $lstDiag.Columns.Add("Current Value", 180)
$col3 = $lstDiag.Columns.Add("Recommended Target", 180)
$col4 = $lstDiag.Columns.Add("Status Badge", 200)

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan / Refresh Current System State"
$btnScan.Location = New-Object System.Drawing.Point(12, 175)
$btnScan.Size = New-Object System.Drawing.Size(260, 30)
$btnScan.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpScanner.Controls.Add($btnScan)

# Remediation Checkbox Options
$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "Select Fix & Optimization Modules to Apply"
$grpOptions.Location = New-Object System.Drawing.Point(12, 230)
$grpOptions.Size = New-Object System.Drawing.Size(875, 168)
$grpOptions.Font = New-Object System.Drawing.Font("Segoe UI", 10.0, [System.Drawing.FontStyle]::Bold)
$tab1.Controls.Add($grpOptions)

$chkSmb = New-Object System.Windows.Forms.CheckBox
$chkSmb.Text = "SMB Network Fix: Enable Insecure Guest Logons & Disable Signing (Client/Server)"
$chkSmb.Location = New-Object System.Drawing.Point(15, 24)
$chkSmb.Size = New-Object System.Drawing.Size(820, 24)
$chkSmb.Checked = $true
$chkSmb.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpOptions.Controls.Add($chkSmb)

$chkDriver = New-Object System.Windows.Forms.CheckBox
$chkDriver.Text = "Driver v3 Fix: Point and Print Policy (CopyFilesPolicy=1, Unrestrict Non-Admin)"
$chkDriver.Location = New-Object System.Drawing.Point(15, 50)
$chkDriver.Size = New-Object System.Drawing.Size(820, 24)
$chkDriver.Checked = $true
$chkDriver.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpOptions.Controls.Add($chkDriver)

$chkRpc = New-Object System.Windows.Forms.CheckBox
$rpcDesc = if ($isModernWin11) { "Windows 11 24H2+ RPC Fix: Disable RPC Privacy (0x11b) + Force RPC over Named Pipes (0xbc4)" } else { "Legacy RPC Fix: Disable RpcAuthnLevelPrivacy (0x11b) + AllowInsecureGuestAuth" }
$chkRpc.Text = $rpcDesc
$chkRpc.Location = New-Object System.Drawing.Point(15, 76)
$chkRpc.Size = New-Object System.Drawing.Size(820, 24)
$chkRpc.Checked = $true
$chkRpc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpOptions.Controls.Add($chkRpc)

$chkRestartSpooler = New-Object System.Windows.Forms.CheckBox
$chkRestartSpooler.Text = "Automatically Restart Print Spooler Service after applying fixes"
$chkRestartSpooler.Location = New-Object System.Drawing.Point(15, 102)
$chkRestartSpooler.Size = New-Object System.Drawing.Size(820, 24)
$chkRestartSpooler.Checked = $true
$chkRestartSpooler.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpOptions.Controls.Add($chkRestartSpooler)

$chkWinUpdate = New-Object System.Windows.Forms.CheckBox
$chkWinUpdate.Text = "Windows Update: Disable Auto-Update (Pause until 2051 - Default: Disabled)"
$chkWinUpdate.Location = New-Object System.Drawing.Point(15, 128)
$chkWinUpdate.Size = New-Object System.Drawing.Size(820, 24)
$chkWinUpdate.Checked = $true
$chkWinUpdate.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpOptions.Controls.Add($chkWinUpdate)

# Action Buttons Bar
$btnApplyAll = New-Object System.Windows.Forms.Button
$btnApplyAll.Text = ">>> APPLY ALL RECOMMENDED FIXES (ULTIMATE) <<<"
$btnApplyAll.Location = New-Object System.Drawing.Point(12, 415)
$btnApplyAll.Size = New-Object System.Drawing.Size(460, 46)
$btnApplyAll.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnApplyAll.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnApplyAll.ForeColor = $cWhite
$btnApplyAll.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$tab1.Controls.Add($btnApplyAll)

$btnApplySelected = New-Object System.Windows.Forms.Button
$btnApplySelected.Text = "Apply Selected"
$btnApplySelected.Location = New-Object System.Drawing.Point(480, 415)
$btnApplySelected.Size = New-Object System.Drawing.Size(150, 46)
$btnApplySelected.Font = New-Object System.Drawing.Font("Segoe UI", 10.0, [System.Drawing.FontStyle]::Bold)
$tab1.Controls.Add($btnApplySelected)

$btnSnapshot = New-Object System.Windows.Forms.Button
$btnSnapshot.Text = "Backup State"
$btnSnapshot.Location = New-Object System.Drawing.Point(638, 415)
$btnSnapshot.Size = New-Object System.Drawing.Size(125, 46)
$btnSnapshot.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$tab1.Controls.Add($btnSnapshot)

$btnRollback = New-Object System.Windows.Forms.Button
$btnRollback.Text = "Rollback / Restore"
$btnRollback.Location = New-Object System.Drawing.Point(770, 415)
$btnRollback.Size = New-Object System.Drawing.Size(125, 46)
$btnRollback.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$tab1.Controls.Add($btnRollback)

# Function to perform System State Scan
function Update-DiagnosticScan {
    $lstDiag.Items.Clear()
    Append-Log "Starting comprehensive diagnostic scan..." "INFO"
    
    # 1. SMB Insecure Guest Logons
    $smbClient = Get-SmbClientConfiguration -ErrorAction SilentlyContinue
    $guestVal = if ($smbClient) { $smbClient.EnableInsecureGuestLogons } else { "Unknown" }
    $guestStatus = if ($guestVal -eq $true) { "[OK] Enabled" } else { "[FIX NEEDED] Disabled" }
    $item1 = New-Object System.Windows.Forms.ListViewItem("SMB Insecure Guest Logons")
    [void]$item1.SubItems.Add([string]$guestVal)
    [void]$item1.SubItems.Add("True")
    [void]$item1.SubItems.Add($guestStatus)
    $lstDiag.Items.Add($item1)

    # 2. SMB Client RequireSecuritySignature
    $reqSig = if ($smbClient) { $smbClient.RequireSecuritySignature } else { "Unknown" }
    $sigStatus = if ($reqSig -eq $false) { "[OK] Disabled" } else { "[FIX NEEDED] Required" }
    $item2 = New-Object System.Windows.Forms.ListViewItem("SMB Client Signing Signature")
    [void]$item2.SubItems.Add([string]$reqSig)
    [void]$item2.SubItems.Add("False")
    [void]$item2.SubItems.Add($sigStatus)
    $lstDiag.Items.Add($item2)

    # 3. AllowInsecureGuestAuth
    $lanmanVal = Get-RegDwordValue $LanmanPath "AllowInsecureGuestAuth"
    $lanmanStatus = if ($lanmanVal -eq 1) { "[OK] Allowed (1)" } else { "[FIX NEEDED] Blocked (0/Not Set)" }
    $lanmanDisplay = if ($null -ne $lanmanVal) { "$lanmanVal" } else { "Not Set" }
    $item3 = New-Object System.Windows.Forms.ListViewItem("Lanman AllowInsecureGuestAuth")
    [void]$item3.SubItems.Add($lanmanDisplay)
    [void]$item3.SubItems.Add("1")
    [void]$item3.SubItems.Add($lanmanStatus)
    $lstDiag.Items.Add($item3)

    # 4. Point and Print RestrictDriverInstallationToAdministrators
    $pnpRestrict = Get-RegDwordValue $PointPrintPath "RestrictDriverInstallationToAdministrators"
    $pnpStatus = if ($pnpRestrict -eq 0) { "[OK] Unrestricted (0)" } else { "[FIX NEEDED] Restricted (1/Default)" }
    $pnpDisplay = if ($null -ne $pnpRestrict) { "$pnpRestrict" } else { "1 (Default)" }
    $item4 = New-Object System.Windows.Forms.ListViewItem("PointAndPrint Driver Restriction")
    [void]$item4.SubItems.Add($pnpDisplay)
    [void]$item4.SubItems.Add("0")
    [void]$item4.SubItems.Add($pnpStatus)
    $lstDiag.Items.Add($item4)

    # 5. CopyFilesPolicy
    $copyPolicy = Get-RegDwordValue $GroupPolicyPath "CopyFilesPolicy"
    $copyStatus = if ($copyPolicy -eq 1) { "[OK] Permitted (1)" } else { "[FIX NEEDED] Blocked (0/Not Set)" }
    $copyDisplay = if ($null -ne $copyPolicy) { "$copyPolicy" } else { "Not Set" }
    $item5 = New-Object System.Windows.Forms.ListViewItem("Printers CopyFilesPolicy")
    [void]$item5.SubItems.Add($copyDisplay)
    [void]$item5.SubItems.Add("1")
    [void]$item5.SubItems.Add($copyStatus)
    $lstDiag.Items.Add($item5)

    # 6. RpcAuthnLevelPrivacyEnabled
    $rpcPriv = Get-RegDwordValue $PrintPath "RpcAuthnLevelPrivacyEnabled"
    $rpcPrivStatus = if ($rpcPriv -eq 0) { "[OK] Disabled (0)" } else { "[FIX NEEDED] Enabled (1/Default)" }
    $rpcPrivDisplay = if ($null -ne $rpcPriv) { "$rpcPriv" } else { "1 (Default)" }
    $item6 = New-Object System.Windows.Forms.ListViewItem("RpcAuthnLevelPrivacy (0x11b)")
    [void]$item6.SubItems.Add($rpcPrivDisplay)
    [void]$item6.SubItems.Add("0")
    [void]$item6.SubItems.Add($rpcPrivStatus)
    $lstDiag.Items.Add($item6)

    # 7. RpcOverNamedPipes (if Win11 24H2+)
    $rpcPipes = Get-RegDwordValue $GroupPolicyPath "RpcOverNamedPipes"
    $rpcPipesStatus = if ($rpcPipes -eq 1) { "[OK] Enabled (1)" } else { if ($isModernWin11) { "[FIX NEEDED] Not Set" } else { "[INFO] Optional" } }
    $rpcPipesDisplay = if ($null -ne $rpcPipes) { "$rpcPipes" } else { "Not Set" }
    $item7 = New-Object System.Windows.Forms.ListViewItem("RpcOverNamedPipes (0xbc4)")
    [void]$item7.SubItems.Add($rpcPipesDisplay)
    [void]$item7.SubItems.Add("1")
    [void]$item7.SubItems.Add($rpcPipesStatus)
    $lstDiag.Items.Add($item7)

    # 7b. ForceKerberosForRpc (Workgroup NTLM fallback)
    $kerbVal = Get-RegDwordValue $RpcPolicyPath "ForceKerberosForRpc"
    $kerbStatus = if ($kerbVal -eq 0) { "[OK] Allowed NTLM (0)" } else { "[FIX NEEDED] Strict Kerberos" }
    $kerbDisplay = if ($null -ne $kerbVal) { "$kerbVal" } else { "1 (Default)" }
    $item7b = New-Object System.Windows.Forms.ListViewItem("RPC ForceKerberos (Workgroup)")
    [void]$item7b.SubItems.Add($kerbDisplay)
    [void]$item7b.SubItems.Add("0")
    [void]$item7b.SubItems.Add($kerbStatus)
    $lstDiag.Items.Add($item7b)

    # 7c. RpcProtocols (Listener Bitmask)
    $protVal = Get-RegDwordValue $RpcPolicyPath "RpcProtocols"
    $protStatus = if ($protVal -eq 7) { "[OK] All Protocols (7)" } else { "[FIX NEEDED] Limited" }
    $protDisplay = if ($null -ne $protVal) { "$protVal" } else { "Not Set" }
    $item7c = New-Object System.Windows.Forms.ListViewItem("RPC Protocols Listener (All)")
    [void]$item7c.SubItems.Add($protDisplay)
    [void]$item7c.SubItems.Add("7")
    [void]$item7c.SubItems.Add($protStatus)
    $lstDiag.Items.Add($item7c)

    # 8. Print Spooler Service
    $spooler = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
    $spoolStatus = if ($spooler -and $spooler.Status -eq 'Running') { "[OK] Running" } else { "[WARN] $($spooler.Status)" }
    $spoolDisplay = if ($spooler) { "$($spooler.Status)" } else { "Not Found" }
    $item8 = New-Object System.Windows.Forms.ListViewItem("Print Spooler Service Status")
    [void]$item8.SubItems.Add($spoolDisplay)
    [void]$item8.SubItems.Add("Running")
    [void]$item8.SubItems.Add($spoolStatus)
    $lstDiag.Items.Add($item8)

    # 9. Active Network Profile
    $netProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
    $isAllPrivate = $true
    $profilesText = @()
    if ($netProfiles) {
        foreach ($p in $netProfiles) {
            $profilesText += "$($p.Name): $($p.NetworkCategory)"
            if ($p.NetworkCategory -ne 'Private') { $isAllPrivate = $false }
        }
    }
    $netStatus = if ($isAllPrivate) { "[OK] Private Profile" } else { "[FIX NEEDED] Public Profile" }
    $item9 = New-Object System.Windows.Forms.ListViewItem("Network Connection Category")
    [void]$item9.SubItems.Add(($profilesText -join ", "))
    [void]$item9.SubItems.Add("Private")
    [void]$item9.SubItems.Add($netStatus)
    $lstDiag.Items.Add($item9)

    # 10. Windows Update Auto-Update Policy
    $wuVal = Get-RegDwordValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate"
    $wuStatus = if ($wuVal -eq 1) { "[OK] Paused/Disabled (1)" } else { "[ACTIVE] Auto-Update On (0/Not Set)" }
    $wuDisplay = if ($null -ne $wuVal) { "$wuVal" } else { "0 (Default)" }
    $item10 = New-Object System.Windows.Forms.ListViewItem("Windows Update AutoUpdate")
    [void]$item10.SubItems.Add($wuDisplay)
    [void]$item10.SubItems.Add("1 (Paused)")
    [void]$item10.SubItems.Add($wuStatus)
    $lstDiag.Items.Add($item10)

    Append-Log "Diagnostic scan completed successfully." "OK"
}

# Windows Update Control Functions (from C:\Users\User\Downloads\winupdate)
function Pause-WindowsUpdate {
    try {
        Append-Log "Pausing Windows Updates until 2051 (Default: Disabled)..." "INFO"
        
        $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        if (-not (Test-Path $uxPath)) { New-Item -Path $uxPath -Force | Out-Null }
        Set-ItemProperty -Path $uxPath -Name "PauseFeatureUpdatesStartTime" -Value "2025-01-01T00:00:00Z" -Force
        Set-ItemProperty -Path $uxPath -Name "PauseFeatureUpdatesEndTime" -Value "2051-12-31T00:00:00Z" -Force
        Set-ItemProperty -Path $uxPath -Name "PauseQualityUpdatesStartTime" -Value "2025-01-01T00:00:00Z" -Force
        Set-ItemProperty -Path $uxPath -Name "PauseQualityUpdatesEndTime" -Value "2051-12-31T00:00:00Z" -Force
        Set-ItemProperty -Path $uxPath -Name "PauseUpdatesStartTime" -Value "2025-01-01T00:00:00Z" -Force
        Set-ItemProperty -Path $uxPath -Name "PauseUpdatesExpiryTime" -Value "2051-12-31T00:00:00Z" -Force
        Set-RegDwordValue -Path $uxPath -Name "ActiveHoursStart" -Value 13
        Set-RegDwordValue -Path $uxPath -Name "ActiveHoursEnd" -Value 7
        Set-RegDwordValue -Path $uxPath -Name "FlightSettingsMaxPauseDays" -Value 10023

        $waasPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
        if (Test-Path $waasPath) {
            Set-RegDwordValue -Path $waasPath -Name "Start" -Value 4
        }

        $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        Set-RegDwordValue -Path $auPath -Name "NoAutoUpdate" -Value 1
        Set-RegDwordValue -Path $auPath -Name "NoAUShutdownOption" -Value 1
        Set-RegDwordValue -Path $auPath -Name "AlwaysAutoRebootAtScheduledTime" -Value 0
        Set-RegDwordValue -Path $auPath -Name "NoAutoRebootWithLoggedOnUsers" -Value 1
        Set-RegDwordValue -Path $auPath -Name "AutoInstallMinorUpdates" -Value 0

        $policySetPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
        Set-RegDwordValue -Path $policySetPath -Name "PausedFeatureStatus" -Value 1
        Set-RegDwordValue -Path $policySetPath -Name "PausedQualityStatus" -Value 1
        if (-not (Test-Path $policySetPath)) { New-Item -Path $policySetPath -Force | Out-Null }
        Set-ItemProperty -Path $policySetPath -Name "PausedQualityDate" -Value "2025-01-01T00:00:00Z" -Force
        Set-ItemProperty -Path $policySetPath -Name "PausedFeatureDate" -Value "2025-01-01T00:00:00Z" -Force

        Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

        Append-Log "Windows Updates successfully paused until 2051." "OK"
        Update-WindowsUpdateStatus
    } catch {
        Append-Log "Error pausing Windows Updates: $($_.Exception.Message)" "ERROR"
    }
}

function Unpause-WindowsUpdate {
    try {
        Append-Log "Re-enabling Windows Updates (Unpausing to normal)..." "INFO"

        $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        if (Test-Path $uxPath) {
            Remove-ItemProperty -Path $uxPath -Name "PauseFeatureUpdatesStartTime" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $uxPath -Name "PauseFeatureUpdatesEndTime" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $uxPath -Name "PauseQualityUpdatesStartTime" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $uxPath -Name "PauseQualityUpdatesEndTime" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $uxPath -Name "PauseUpdatesStartTime" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $uxPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
        }

        $waasPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
        if (Test-Path $waasPath) {
            Set-RegDwordValue -Path $waasPath -Name "Start" -Value 3
        }

        $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (Test-Path $auPath) {
            Set-RegDwordValue -Path $auPath -Name "NoAutoUpdate" -Value 0
            Set-RegDwordValue -Path $auPath -Name "NoAUShutdownOption" -Value 0
            Set-RegDwordValue -Path $auPath -Name "AutoInstallMinorUpdates" -Value 1
        }

        $policySetPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
        if (Test-Path $policySetPath) {
            Set-RegDwordValue -Path $policySetPath -Name "PausedFeatureStatus" -Value 0
            Set-RegDwordValue -Path $policySetPath -Name "PausedQualityStatus" -Value 0
            Remove-ItemProperty -Path $policySetPath -Name "PausedQualityDate" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $policySetPath -Name "PausedFeatureDate" -ErrorAction SilentlyContinue
        }

        Set-Service -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

        Append-Log "Windows Updates successfully unpaused and active." "OK"
        Update-WindowsUpdateStatus
    } catch {
        Append-Log "Error unpausing Windows Updates: $($_.Exception.Message)" "ERROR"
    }
}

function Update-WindowsUpdateStatus {
    $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $isPaused = $false

    if (Test-Path $uxPath) {
        $expiry = (Get-ItemProperty -Path $uxPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue).PauseUpdatesExpiryTime
        if ($expiry) { $isPaused = $true }
    }
    if (Test-Path $auPath) {
        $noAuto = (Get-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue).NoAutoUpdate
        if ($noAuto -eq 1) { $isPaused = $true }
    }

    if ($lblWuStatusBadge) {
        if ($isPaused) {
            $lblWuStatusBadge.Text = "[ PAUSED / DISABLED (Until 2051 - Default) ]"
            $lblWuStatusBadge.ForeColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
        } else {
            $lblWuStatusBadge.Text = "[ ACTIVE / NORMAL (Enabled) ]"
            $lblWuStatusBadge.ForeColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
        }
    }
}

# Apply Functions
function Apply-Remediations {
    param(
        [bool]$DoSmb = $true,
        [bool]$DoDriver = $true,
        [bool]$DoRpc = $true,
        [bool]$DoRestartSpooler = $true,
        [bool]$DoPauseWinUpdate = $true
    )

    Create-SystemSnapshot | Out-Null
    Append-Log "Applying selected remediations to system..." "INFO"

    # SMB Fix
    if ($DoSmb) {
        Append-Log "[SMB Network Fix] Configuring InsecureGuestLogons & SecuritySignature..." "INFO"
        try {
            Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force | Out-Null
            Append-Log "-> [OK] Executed: Set-SmbClientConfiguration -EnableInsecureGuestLogons `$true -Force" "OK"
        } catch {
            Append-Log "Warning executing Set-SmbClientConfiguration (Guest): $($_.Exception.Message)" "WARN"
        }

        try {
            Set-SmbClientConfiguration -RequireSecuritySignature $false -Force | Out-Null
            Append-Log "-> [OK] Executed: Set-SmbClientConfiguration -RequireSecuritySignature `$false -Force" "OK"
        } catch {
            Append-Log "Warning executing Set-SmbClientConfiguration (Signature): $($_.Exception.Message)" "WARN"
        }

        try {
            Set-SmbServerConfiguration -RequireSecuritySignature $false -Force | Out-Null
            Append-Log "-> [OK] Executed: Set-SmbServerConfiguration -RequireSecuritySignature `$false -Force" "OK"
        } catch {
            Append-Log "Warning executing Set-SmbServerConfiguration (Signature): $($_.Exception.Message)" "WARN"
        }

        # Direct registry fallback for LanmanWorkstation and LanmanServer
        Set-RegDwordValue -Path $LanmanPath -Name "AllowInsecureGuestAuth" -Value 1
        Set-RegDwordValue -Path $LanmanPath -Name "EnableInsecureGuestLogons" -Value 1
        Set-RegDwordValue -Path $LanmanPath -Name "RequireSecuritySignature" -Value 0
        Set-RegDwordValue -Path $LanmanPath -Name "EnableSecuritySignature" -Value 0
        $lanmanServerPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        Set-RegDwordValue -Path $lanmanServerPath -Name "requiresecuritysignature" -Value 0
        Set-RegDwordValue -Path $lanmanServerPath -Name "enablesecuritysignature" -Value 0
        Append-Log "-> [OK] LanmanWorkstation & LanmanServer registry policies set." "OK"
    }

    # Driver v3 Fix
    if ($DoDriver) {
        try {
            Append-Log "[Driver Fix] Configuring Point and Print & CopyFiles policies..." "INFO"
            if (-not (Test-Path $GroupPolicyPath)) { New-Item -Path $GroupPolicyPath -Force | Out-Null }
            if (-not (Test-Path $PointPrintPath)) { New-Item -Path $PointPrintPath -Force | Out-Null }

            New-ItemProperty -Path $GroupPolicyPath -Name "CopyFilesPolicy" -Value 1 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $PointPrintPath -Name "NoWarningNoElevationOnInstall" -Value 1 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $PointPrintPath -Name "NoWarningNoElevationOnUpdate" -Value 1 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $PointPrintPath -Name "RestrictDriverInstallationToAdministrators" -Value 0 -PropertyType DWORD -Force | Out-Null
            Append-Log "-> Point and Print restrictions lifted, driver v3 package install enabled." "OK"
        } catch {
            Append-Log "Error setting Driver policies: $($_.Exception.Message)" "ERROR"
        }
    }

    # RPC Protocol Fix
    if ($DoRpc) {
        try {
            if (-not (Test-Path $PrintPath)) { New-Item -Path $PrintPath -Force | Out-Null }
            if (-not (Test-Path $LanmanPath)) { New-Item -Path $LanmanPath -Force | Out-Null }

            New-ItemProperty -Path $PrintPath -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $LanmanPath -Name "AllowInsecureGuestAuth" -Value 1 -PropertyType DWORD -Force | Out-Null
            Append-Log "-> RpcAuthnLevelPrivacyEnabled set to 0 (fixes 0x0000011b)." "OK"
            Append-Log "-> LanmanWorkstation AllowInsecureGuestAuth set to 1 (fixes Access Denied)." "OK"

            # 2. Printers\RPC Policies (Workgroup / Listener / NTLM fallback)
            if (-not (Test-Path $RpcPolicyPath)) { New-Item -Path $RpcPolicyPath -Force | Out-Null }
            New-ItemProperty -Path $RpcPolicyPath -Name "RpcUseNamedPipeProtocol" -Value 1 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $RpcPolicyPath -Name "RpcAuthentication" -Value 0 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $RpcPolicyPath -Name "RpcProtocols" -Value 7 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $RpcPolicyPath -Name "ForceKerberosForRpc" -Value 0 -PropertyType DWORD -Force | Out-Null
            New-ItemProperty -Path $RpcPolicyPath -Name "RpcTcpPort" -Value 0 -PropertyType DWORD -Force | Out-Null
            Append-Log "-> Printers\RPC configured (RpcProtocols=7, ForceKerberosForRpc=0, RpcUseNamedPipeProtocol=1)." "OK"

            if ($isModernWin11) {
                if (-not (Test-Path $GroupPolicyPath)) { New-Item -Path $GroupPolicyPath -Force | Out-Null }
                New-ItemProperty -Path $GroupPolicyPath -Name "RpcClientProtocol" -Value 1 -PropertyType DWORD -Force | Out-Null
                New-ItemProperty -Path $GroupPolicyPath -Name "RpcOverNamedPipes" -Value 1 -PropertyType DWORD -Force | Out-Null
                Append-Log "-> Windows 11 24H2+ Mode: Forced RPC over named pipes (fixes 0x00000bc4)." "OK"
            }
        } catch {
            Append-Log "Error configuring RPC protocols: $($_.Exception.Message)" "ERROR"
        }
    }

    # Restart Spooler
    if ($DoRestartSpooler) {
        try {
            Append-Log "Restarting Print Spooler service..." "INFO"
            Restart-Service -Name "Spooler" -Force
            Append-Log "Print Spooler restarted successfully." "OK"
        } catch {
            Append-Log "Failed to restart Print Spooler: $($_.Exception.Message)" "ERROR"
        }
    }

    # Windows Update (Default: Pause until 2051)
    if ($DoPauseWinUpdate) {
        Pause-WindowsUpdate
    }

    Update-DiagnosticScan
    [System.Windows.Forms.MessageBox]::Show("Remediation completed successfully!`nIt is recommended to restart your computer once.", "WinPrintFix Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# ----------------------------------------------------
# 8. TAB 2: Network Profile & Firewall Tools
# ----------------------------------------------------
$grpNet = New-Object System.Windows.Forms.GroupBox
$grpNet.Text = "Network Adapter Category (Private vs Public)"
$grpNet.Location = New-Object System.Drawing.Point(15, 10)
$grpNet.Size = New-Object System.Drawing.Size(868, 105)
$grpNet.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$tab2.Controls.Add($grpNet)

$lblNetDesc = New-Object System.Windows.Forms.Label
$lblNetDesc.Text = "Windows 10/11 updates often reset active networks to 'Public', closing File & Printer sharing ports.`nClick below to change active connections to 'Private'."
$lblNetDesc.Location = New-Object System.Drawing.Point(15, 22)
$lblNetDesc.Size = New-Object System.Drawing.Size(820, 36)
$lblNetDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpNet.Controls.Add($lblNetDesc)

$btnSetPrivate = New-Object System.Windows.Forms.Button
$btnSetPrivate.Text = "Switch Active Network Profiles to Private"
$btnSetPrivate.Location = New-Object System.Drawing.Point(15, 62)
$btnSetPrivate.Size = New-Object System.Drawing.Size(320, 32)
$btnSetPrivate.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpNet.Controls.Add($btnSetPrivate)

$grpFw = New-Object System.Windows.Forms.GroupBox
$grpFw.Text = "Windows Defender Firewall: File & Printer Sharing"
$grpFw.Location = New-Object System.Drawing.Point(15, 122)
$grpFw.Size = New-Object System.Drawing.Size(868, 105)
$grpFw.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$tab2.Controls.Add($grpFw)

$lblFwDesc = New-Object System.Windows.Forms.Label
$lblFwDesc.Text = "Ensure incoming SMB (TCP 445), NetBIOS (TCP 139), and Spooler RPC rules are allowed."
$lblFwDesc.Location = New-Object System.Drawing.Point(15, 22)
$lblFwDesc.Size = New-Object System.Drawing.Size(820, 30)
$lblFwDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpFw.Controls.Add($lblFwDesc)

$btnEnableFw = New-Object System.Windows.Forms.Button
$btnEnableFw.Text = "Enable 'File and Printer Sharing' Firewall Rules"
$btnEnableFw.Location = New-Object System.Drawing.Point(15, 60)
$btnEnableFw.Size = New-Object System.Drawing.Size(340, 32)
$btnEnableFw.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpFw.Controls.Add($btnEnableFw)

$grpDisc = New-Object System.Windows.Forms.GroupBox
$grpDisc.Text = "Network Discovery Services (FDResPub & fdPHost)"
$grpDisc.Location = New-Object System.Drawing.Point(15, 234)
$grpDisc.Size = New-Object System.Drawing.Size(868, 105)
$grpDisc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$tab2.Controls.Add($grpDisc)

$lblDiscDesc = New-Object System.Windows.Forms.Label
$lblDiscDesc.Text = "Enables Function Discovery services so PCs and shared printers appear in File Explorer Network browser."
$lblDiscDesc.Location = New-Object System.Drawing.Point(15, 22)
$lblDiscDesc.Size = New-Object System.Drawing.Size(820, 30)
$lblDiscDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpDisc.Controls.Add($lblDiscDesc)

$btnEnableDisc = New-Object System.Windows.Forms.Button
$btnEnableDisc.Text = "Configure & Start Discovery Services"
$btnEnableDisc.Location = New-Object System.Drawing.Point(15, 60)
$btnEnableDisc.Size = New-Object System.Drawing.Size(320, 32)
$btnEnableDisc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpDisc.Controls.Add($btnEnableDisc)

$grpSmb = New-Object System.Windows.Forms.GroupBox
$grpSmb.Text = "SMB Protocol & Security Signing (Windows 10 / 11 24H2+)"
$grpSmb.Location = New-Object System.Drawing.Point(15, 346)
$grpSmb.Size = New-Object System.Drawing.Size(868, 115)
$grpSmb.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$tab2.Controls.Add($grpSmb)

$lblSmbDesc = New-Object System.Windows.Forms.Label
$lblSmbDesc.Text = "Configures SMB Client and Server policies: Enables Insecure Guest Logons and disables mandatory Signing.`nResolves 'Access Denied' and network path not found (0x80070035) on Windows 11 24H2+."
$lblSmbDesc.Location = New-Object System.Drawing.Point(15, 22)
$lblSmbDesc.Size = New-Object System.Drawing.Size(820, 36)
$lblSmbDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$grpSmb.Controls.Add($lblSmbDesc)

$btnConfigureSmb = New-Object System.Windows.Forms.Button
$btnConfigureSmb.Text = "Apply SMB Security Fix (Set-SmbClient/Server)"
$btnConfigureSmb.Location = New-Object System.Drawing.Point(15, 66)
$btnConfigureSmb.Size = New-Object System.Drawing.Size(360, 34)
$btnConfigureSmb.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpSmb.Controls.Add($btnConfigureSmb)

# ----------------------------------------------------
# 9. TAB 3: Driver v3 & Local Port Wizard
# ----------------------------------------------------
$grpV3Info = New-Object System.Windows.Forms.GroupBox
$grpV3Info.Text = "Driver v3 Architecture Dilemma & Workarounds"
$grpV3Info.Location = New-Object System.Drawing.Point(15, 15)
$grpV3Info.Size = New-Object System.Drawing.Size(785, 170)
$grpV3Info.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$tab3.Controls.Add($grpV3Info)

$txtV3Info = New-Object System.Windows.Forms.TextBox
$txtV3Info.Multiline = $true
$txtV3Info.ReadOnly = $true
$txtV3Info.BackColor = $cWhite
$txtV3Info.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$txtV3Info.Location = New-Object System.Drawing.Point(15, 25)
$txtV3Info.Size = New-Object System.Drawing.Size(755, 135)
$txtV3Info.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$txtV3Info.Text = @"
Windows 11 24H2+ phases out Type 3 (v3) printer drivers in favor of Type 4 (v4) / Mopria.
If the printer manufacturer has no v4 driver, clients connecting across the network see "No driver found" or hang.

Proven Workarounds:
1. Local Pre-Installation: Download and run the printer installer locally on the client machine first (as a USB/Local printer). When Windows connects to the network share, it finds the driver locally and succeeds.
2. Local Port Redirect: Redirect a local printer port directly to \\HostIP\PrinterName (bypassing Point & Print).
"@
$grpV3Info.Controls.Add($txtV3Info)

$grpPortWiz = New-Object System.Windows.Forms.GroupBox
$grpPortWiz.Text = "Local Port Redirect Wizard (Bypass v3 Driver Block)"
$grpPortWiz.Location = New-Object System.Drawing.Point(15, 195)
$grpPortWiz.Size = New-Object System.Drawing.Size(785, 135)
$grpPortWiz.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$tab3.Controls.Add($grpPortWiz)

$lblHostIp = New-Object System.Windows.Forms.Label
$lblHostIp.Text = "Host IP Address:"
$lblHostIp.Location = New-Object System.Drawing.Point(15, 30)
$lblHostIp.AutoSize = $true
$lblHostIp.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$grpPortWiz.Controls.Add($lblHostIp)

$txtHostIp = New-Object System.Windows.Forms.TextBox
$txtHostIp.Text = "192.168.1.50"
$txtHostIp.Location = New-Object System.Drawing.Point(140, 27)
$txtHostIp.Size = New-Object System.Drawing.Size(160, 24)
$grpPortWiz.Controls.Add($txtHostIp)

$lblShareName = New-Object System.Windows.Forms.Label
$lblShareName.Text = "Printer Share Name:"
$lblShareName.Location = New-Object System.Drawing.Point(320, 30)
$lblShareName.AutoSize = $true
$lblShareName.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$grpPortWiz.Controls.Add($lblShareName)

$txtShareName = New-Object System.Windows.Forms.TextBox
$txtShareName.Text = "CanonPrinter"
$txtShareName.Location = New-Object System.Drawing.Point(460, 27)
$txtShareName.Size = New-Object System.Drawing.Size(180, 24)
$grpPortWiz.Controls.Add($txtShareName)

$btnCreatePort = New-Object System.Windows.Forms.Button
$btnCreatePort.Text = "Create Local Port & Open Add Printer Wizard"
$btnCreatePort.Location = New-Object System.Drawing.Point(15, 75)
$btnCreatePort.Size = New-Object System.Drawing.Size(320, 35)
$btnCreatePort.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$grpPortWiz.Controls.Add($btnCreatePort)

$btnOpenPrnMgmt = New-Object System.Windows.Forms.Button
$btnOpenPrnMgmt.Text = "Print Management (printmanagement.msc)"
$btnOpenPrnMgmt.Location = New-Object System.Drawing.Point(15, 345)
$btnOpenPrnMgmt.Size = New-Object System.Drawing.Size(280, 32)
$tab3.Controls.Add($btnOpenPrnMgmt)

$btnOpenDevices = New-Object System.Windows.Forms.Button
$btnOpenDevices.Text = "Devices & Printers (control printers)"
$btnOpenDevices.Location = New-Object System.Drawing.Point(310, 345)
$btnOpenDevices.Size = New-Object System.Drawing.Size(260, 32)
$tab3.Controls.Add($btnOpenDevices)

# ----------------------------------------------------
# 10. TAB 4: Spooler Maintenance & Export
# ----------------------------------------------------
$grpSpoolOps = New-Object System.Windows.Forms.GroupBox
$grpSpoolOps.Text = "Print Spooler Service Control & Queue Purge"
$grpSpoolOps.Location = New-Object System.Drawing.Point(15, 15)
$grpSpoolOps.Size = New-Object System.Drawing.Size(785, 175)
$grpSpoolOps.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$tab4.Controls.Add($grpSpoolOps)

$btnRestartSpooler = New-Object System.Windows.Forms.Button
$btnRestartSpooler.Text = "Restart Spooler"
$btnRestartSpooler.Location = New-Object System.Drawing.Point(15, 35)
$btnRestartSpooler.Size = New-Object System.Drawing.Size(140, 35)
$grpSpoolOps.Controls.Add($btnRestartSpooler)

$btnStartSpooler = New-Object System.Windows.Forms.Button
$btnStartSpooler.Text = "Start Service"
$btnStartSpooler.Location = New-Object System.Drawing.Point(165, 35)
$btnStartSpooler.Size = New-Object System.Drawing.Size(120, 35)
$grpSpoolOps.Controls.Add($btnStartSpooler)

$btnStopSpooler = New-Object System.Windows.Forms.Button
$btnStopSpooler.Text = "Stop Service"
$btnStopSpooler.Location = New-Object System.Drawing.Point(295, 35)
$btnStopSpooler.Size = New-Object System.Drawing.Size(120, 35)
$grpSpoolOps.Controls.Add($btnStopSpooler)

$btnPurgeQueue = New-Object System.Windows.Forms.Button
$btnPurgeQueue.Text = "Deep Purge Stuck Print Queue (.spl / .shd files)"
$btnPurgeQueue.Location = New-Object System.Drawing.Point(15, 95)
$btnPurgeQueue.Size = New-Object System.Drawing.Size(350, 42)
$btnPurgeQueue.BackColor = [System.Drawing.Color]::FromArgb(254, 243, 199)
$btnPurgeQueue.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$grpSpoolOps.Controls.Add($btnPurgeQueue)

$grpExport = New-Object System.Windows.Forms.GroupBox
$grpExport.Text = "Offline Mass Deployment (.reg File Export)"
$grpExport.Location = New-Object System.Drawing.Point(15, 205)
$grpExport.Size = New-Object System.Drawing.Size(785, 140)
$grpExport.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$tab4.Controls.Add($grpExport)

$lblExportDesc = New-Object System.Windows.Forms.Label
$lblExportDesc.Text = "Generate a standalone .reg file containing all exact registry modifications for offline deployment via GPO or USB drive."
$lblExportDesc.Location = New-Object System.Drawing.Point(15, 28)
$lblExportDesc.Size = New-Object System.Drawing.Size(750, 30)
$lblExportDesc.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$grpExport.Controls.Add($lblExportDesc)

$btnExportReg = New-Object System.Windows.Forms.Button
$btnExportReg.Text = "Export All Fix Rules to WinPrintFix_Rules.reg"
$btnExportReg.Location = New-Object System.Drawing.Point(15, 75)
$btnExportReg.Size = New-Object System.Drawing.Size(350, 38)
$btnExportReg.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Bold)
$grpExport.Controls.Add($btnExportReg)

# ----------------------------------------------------
# 10b. TAB 5: Windows Update Control (Default: Disabled)
# ----------------------------------------------------
$grpWuStatus = New-Object System.Windows.Forms.GroupBox
$grpWuStatus.Text = "Windows Update Status & Control (Default: Disabled)"
$grpWuStatus.Location = New-Object System.Drawing.Point(15, 15)
$grpWuStatus.Size = New-Object System.Drawing.Size(860, 115)
$grpWuStatus.Font = New-Object System.Drawing.Font("Segoe UI", 10.0, [System.Drawing.FontStyle]::Bold)
$tab5.Controls.Add($grpWuStatus)

$lblWuStatusLabel = New-Object System.Windows.Forms.Label
$lblWuStatusLabel.Text = "Current Windows Update Status:"
$lblWuStatusLabel.Location = New-Object System.Drawing.Point(20, 32)
$lblWuStatusLabel.Size = New-Object System.Drawing.Size(250, 25)
$lblWuStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10.0)
$grpWuStatus.Controls.Add($lblWuStatusLabel)

$lblWuStatusBadge = New-Object System.Windows.Forms.Label
$lblWuStatusBadge.Text = "[ CHECKING STATUS... ]"
$lblWuStatusBadge.Location = New-Object System.Drawing.Point(280, 28)
$lblWuStatusBadge.Size = New-Object System.Drawing.Size(420, 28)
$lblWuStatusBadge.Font = New-Object System.Drawing.Font("Segoe UI", 11.0, [System.Drawing.FontStyle]::Bold)
$grpWuStatus.Controls.Add($lblWuStatusBadge)

$lblWuDesc = New-Object System.Windows.Forms.Label
$lblWuDesc.Text = "Default: Disabled (Paused until 2051) to prevent automatic updates from breaking shared printers and SMB ports."
$lblWuDesc.Location = New-Object System.Drawing.Point(20, 68)
$lblWuDesc.Size = New-Object System.Drawing.Size(820, 35)
$lblWuDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$lblWuDesc.ForeColor = [System.Drawing.Color]::FromArgb(108, 117, 125)
$grpWuStatus.Controls.Add($lblWuDesc)

$btnCheckWu = New-Object System.Windows.Forms.Button
$btnCheckWu.Text = "Refresh Status"
$btnCheckWu.Location = New-Object System.Drawing.Point(690, 26)
$btnCheckWu.Size = New-Object System.Drawing.Size(150, 32)
$btnCheckWu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpWuStatus.Controls.Add($btnCheckWu)

$grpWuActions = New-Object System.Windows.Forms.GroupBox
$grpWuActions.Text = "Windows Update Actions (Pause / Unpause Toggle)"
$grpWuActions.Location = New-Object System.Drawing.Point(15, 140)
$grpWuActions.Size = New-Object System.Drawing.Size(860, 160)
$grpWuActions.Font = New-Object System.Drawing.Font("Segoe UI", 10.0, [System.Drawing.FontStyle]::Bold)
$tab5.Controls.Add($grpWuActions)

$btnPauseWu = New-Object System.Windows.Forms.Button
$btnPauseWu.Text = "PAUSE WINDOWS UPDATE UNTIL 2051 (DEFAULT: DISABLED)"
$btnPauseWu.Location = New-Object System.Drawing.Point(20, 32)
$btnPauseWu.Size = New-Object System.Drawing.Size(400, 52)
$btnPauseWu.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$btnPauseWu.ForeColor = $cWhite
$btnPauseWu.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnPauseWu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpWuActions.Controls.Add($btnPauseWu)

$btnUnpauseWu = New-Object System.Windows.Forms.Button
$btnUnpauseWu.Text = "UNPAUSE & RESTORE NORMAL WINDOWS UPDATE"
$btnUnpauseWu.Location = New-Object System.Drawing.Point(440, 32)
$btnUnpauseWu.Size = New-Object System.Drawing.Size(400, 52)
$btnUnpauseWu.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnUnpauseWu.ForeColor = $cWhite
$btnUnpauseWu.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnUnpauseWu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$grpWuActions.Controls.Add($btnUnpauseWu)

$btnOpenWuSettings = New-Object System.Windows.Forms.Button
$btnOpenWuSettings.Text = "Open Windows Update Settings Panel (ms-settings)"
$btnOpenWuSettings.Location = New-Object System.Drawing.Point(20, 100)
$btnOpenWuSettings.Size = New-Object System.Drawing.Size(350, 36)
$btnOpenWuSettings.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$grpWuActions.Controls.Add($btnOpenWuSettings)

$grpWuDetails = New-Object System.Windows.Forms.GroupBox
$grpWuDetails.Text = "Windows Update Configuration Details"
$grpWuDetails.Location = New-Object System.Drawing.Point(15, 310)
$grpWuDetails.Size = New-Object System.Drawing.Size(860, 150)
$grpWuDetails.Font = New-Object System.Drawing.Font("Segoe UI", 10.0, [System.Drawing.FontStyle]::Bold)
$tab5.Controls.Add($grpWuDetails)

$txtWuDetails = New-Object System.Windows.Forms.TextBox
$txtWuDetails.Multiline = $true
$txtWuDetails.ReadOnly = $true
$txtWuDetails.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtWuDetails.Location = New-Object System.Drawing.Point(15, 25)
$txtWuDetails.Size = New-Object System.Drawing.Size(830, 110)
$txtWuDetails.Font = New-Object System.Drawing.Font("Consolas", 9.0)
$txtWuDetails.Text = @"
[Windows Update Pause / Unpause Policy]
- UX Settings: PauseFeatureUpdatesStartTime/EndTime & PauseQualityUpdates (2025 -> 2051)
- WaaSMedicSvc: Start = 4 (Disabled when Paused) / Start = 3 (Manual when Active)
- AU Policy: NoAutoUpdate = 1, NoAUShutdownOption = 1, AutoInstallMinorUpdates = 0
- UpdatePolicy Settings: PausedFeatureStatus = 1, PausedQualityStatus = 1
- Service wuauserv: Disabled & Stopped when Paused / Manual when Active
"@
$grpWuDetails.Controls.Add($txtWuDetails)

# ----------------------------------------------------
# 11. Event Handlers Attachment
# ----------------------------------------------------
$btnScan.Add_Click({ Update-DiagnosticScan })

$btnApplyAll.Add_Click({
    Apply-Remediations -DoSmb $true -DoDriver $true -DoRpc $true -DoRestartSpooler $true -DoPauseWinUpdate $true
})

$btnApplySelected.Add_Click({
    Apply-Remediations -DoSmb $chkSmb.Checked -DoDriver $chkDriver.Checked -DoRpc $chkRpc.Checked -DoRestartSpooler $chkRestartSpooler.Checked -DoPauseWinUpdate $chkWinUpdate.Checked
})

# Tab 5 Windows Update Handlers
$btnPauseWu.Add_Click({ Pause-WindowsUpdate })
$btnUnpauseWu.Add_Click({ Unpause-WindowsUpdate })
$btnCheckWu.Add_Click({ Update-WindowsUpdateStatus })
$btnOpenWuSettings.Add_Click({ Start-Process "ms-settings:windowsupdate" })

$btnSnapshot.Add_Click({
    $bk = Create-SystemSnapshot
    if ($bk) {
        [System.Windows.Forms.MessageBox]::Show("Snapshot created successfully!`nFile: $bk", "Snapshot Saved", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$btnRollback.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.InitialDirectory = (Resolve-Path $backupsDir).Path
    $dlg.Filter = "Snapshot Files (*.json)|*.json|All Files (*.*)|*.*"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $content = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            Append-Log "Restoring settings from snapshot: $($dlg.FileName)" "INFO"
            
            # Restore Registry
            if ($content.Registry) {
                # 1. Print Path
                if ($null -ne $content.Registry.RpcAuthnLevelPrivacyEnabled) {
                    Set-ItemProperty -Path $PrintPath -Name "RpcAuthnLevelPrivacyEnabled" -Value $content.Registry.RpcAuthnLevelPrivacyEnabled -Force
                } else {
                    Remove-ItemProperty -Path $PrintPath -Name "RpcAuthnLevelPrivacyEnabled" -ErrorAction SilentlyContinue
                }
                
                # 2. Lanman
                if ($null -ne $content.Registry.AllowInsecureGuestAuth) {
                    Set-ItemProperty -Path $LanmanPath -Name "AllowInsecureGuestAuth" -Value $content.Registry.AllowInsecureGuestAuth -Force
                }
                
                # 3. Group Policy
                if ($null -ne $content.Registry.CopyFilesPolicy) {
                    Set-ItemProperty -Path $GroupPolicyPath -Name "CopyFilesPolicy" -Value $content.Registry.CopyFilesPolicy -Force
                } else {
                    Remove-ItemProperty -Path $GroupPolicyPath -Name "CopyFilesPolicy" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.RpcClientProtocol) {
                    Set-ItemProperty -Path $GroupPolicyPath -Name "RpcClientProtocol" -Value $content.Registry.RpcClientProtocol -Force
                } else {
                    Remove-ItemProperty -Path $GroupPolicyPath -Name "RpcClientProtocol" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.RpcOverNamedPipes) {
                    Set-ItemProperty -Path $GroupPolicyPath -Name "RpcOverNamedPipes" -Value $content.Registry.RpcOverNamedPipes -Force
                } else {
                    Remove-ItemProperty -Path $GroupPolicyPath -Name "RpcOverNamedPipes" -ErrorAction SilentlyContinue
                }

                # 4. Point and Print
                if ($null -ne $content.Registry.NoWarningNoElevationOnInstall) {
                    Set-ItemProperty -Path $PointPrintPath -Name "NoWarningNoElevationOnInstall" -Value $content.Registry.NoWarningNoElevationOnInstall -Force
                } else {
                    Remove-ItemProperty -Path $PointPrintPath -Name "NoWarningNoElevationOnInstall" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.NoWarningNoElevationOnUpdate) {
                    Set-ItemProperty -Path $PointPrintPath -Name "NoWarningNoElevationOnUpdate" -Value $content.Registry.NoWarningNoElevationOnUpdate -Force
                } else {
                    Remove-ItemProperty -Path $PointPrintPath -Name "NoWarningNoElevationOnUpdate" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.RestrictDriverInstallationToAdministrators) {
                    Set-ItemProperty -Path $PointPrintPath -Name "RestrictDriverInstallationToAdministrators" -Value $content.Registry.RestrictDriverInstallationToAdministrators -Force
                } else {
                    Remove-ItemProperty -Path $PointPrintPath -Name "RestrictDriverInstallationToAdministrators" -ErrorAction SilentlyContinue
                }

                # 5. Printers\RPC Policies
                if ($null -ne $content.Registry.RpcProtocols) {
                    Set-ItemProperty -Path $RpcPolicyPath -Name "RpcProtocols" -Value $content.Registry.RpcProtocols -Force
                } else {
                    Remove-ItemProperty -Path $RpcPolicyPath -Name "RpcProtocols" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.ForceKerberosForRpc) {
                    Set-ItemProperty -Path $RpcPolicyPath -Name "ForceKerberosForRpc" -Value $content.Registry.ForceKerberosForRpc -Force
                } else {
                    Remove-ItemProperty -Path $RpcPolicyPath -Name "ForceKerberosForRpc" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.RpcUseNamedPipeProtocol) {
                    Set-ItemProperty -Path $RpcPolicyPath -Name "RpcUseNamedPipeProtocol" -Value $content.Registry.RpcUseNamedPipeProtocol -Force
                } else {
                    Remove-ItemProperty -Path $RpcPolicyPath -Name "RpcUseNamedPipeProtocol" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.RpcAuthentication) {
                    Set-ItemProperty -Path $RpcPolicyPath -Name "RpcAuthentication" -Value $content.Registry.RpcAuthentication -Force
                } else {
                    Remove-ItemProperty -Path $RpcPolicyPath -Name "RpcAuthentication" -ErrorAction SilentlyContinue
                }

                if ($null -ne $content.Registry.RpcTcpPort) {
                    Set-ItemProperty -Path $RpcPolicyPath -Name "RpcTcpPort" -Value $content.Registry.RpcTcpPort -Force
                } else {
                    Remove-ItemProperty -Path $RpcPolicyPath -Name "RpcTcpPort" -ErrorAction SilentlyContinue
                }
            }
            
            # Restart Spooler
            Restart-Service -Name "Spooler" -Force
            Update-DiagnosticScan
            Append-Log "Rollback restored successfully." "OK"
            [System.Windows.Forms.MessageBox]::Show("Rollback completed from snapshot!", "Restoration Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Append-Log "Rollback error: $($_.Exception.Message)" "ERROR"
        }
    }
})

$btnSetPrivate.Add_Click({
    try {
        Append-Log "Setting all active network adapter profiles to Private..." "INFO"
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
        Append-Log "Active network profiles set to Private successfully." "OK"
        Update-DiagnosticScan
    } catch {
        Append-Log "Error setting network profile: $($_.Exception.Message)" "ERROR"
    }
})

$btnEnableFw.Add_Click({
    try {
        Append-Log "Enabling Windows Firewall rules for 'File and Printer Sharing'..." "INFO"
        Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"
        Append-Log "Firewall rules enabled successfully." "OK"
    } catch {
        Append-Log "Error enabling firewall rules: $($_.Exception.Message)" "ERROR"
    }
})

$btnEnableDisc.Add_Click({
    try {
        Append-Log "Configuring Function Discovery Resource Publication & Host services..." "INFO"
        Set-Service -Name "FDResPub" -StartupType Automatic
        Set-Service -Name "fdPHost" -StartupType Automatic
        Start-Service -Name "FDResPub" -ErrorAction SilentlyContinue
        Start-Service -Name "fdPHost" -ErrorAction SilentlyContinue
        Append-Log "Discovery services set to Automatic and running." "OK"
    } catch {
        Append-Log "Error configuring discovery services: $($_.Exception.Message)" "ERROR"
    }
})

$btnConfigureSmb.Add_Click({
    Append-Log "Running SMB Client & Server configuration..." "INFO"
    try {
        Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force | Out-Null
        Append-Log "-> [OK] Executed: Set-SmbClientConfiguration -EnableInsecureGuestLogons `$true -Force" "OK"
    } catch {
        Append-Log "Notice on Set-SmbClientConfiguration (Guest): $($_.Exception.Message)" "WARN"
    }

    try {
        Set-SmbClientConfiguration -RequireSecuritySignature $false -Force | Out-Null
        Append-Log "-> [OK] Executed: Set-SmbClientConfiguration -RequireSecuritySignature `$false -Force" "OK"
    } catch {
        Append-Log "Notice on Set-SmbClientConfiguration (Signature): $($_.Exception.Message)" "WARN"
    }

    try {
        Set-SmbServerConfiguration -RequireSecuritySignature $false -Force | Out-Null
        Append-Log "-> [OK] Executed: Set-SmbServerConfiguration -RequireSecuritySignature `$false -Force" "OK"
    } catch {
        Append-Log "Notice on Set-SmbServerConfiguration (Signature): $($_.Exception.Message)" "WARN"
    }

    Set-RegDwordValue -Path $LanmanPath -Name "AllowInsecureGuestAuth" -Value 1
    Set-RegDwordValue -Path $LanmanPath -Name "EnableInsecureGuestLogons" -Value 1
    Set-RegDwordValue -Path $LanmanPath -Name "RequireSecuritySignature" -Value 0
    Set-RegDwordValue -Path $LanmanPath -Name "EnableSecuritySignature" -Value 0
    $lanmanServerPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    Set-RegDwordValue -Path $lanmanServerPath -Name "requiresecuritysignature" -Value 0
    Set-RegDwordValue -Path $lanmanServerPath -Name "enablesecuritysignature" -Value 0
    Append-Log "-> [OK] SMB Client & Server configured successfully." "OK"
    Update-DiagnosticScan
    [System.Windows.Forms.MessageBox]::Show("SMB Client & Server configuration applied successfully!`nInsecure Guest Logons: Enabled`nSecurity Signatures: Disabled", "SMB Configuration", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

$btnCreatePort.Add_Click({
    $ip = $txtHostIp.Text.Trim()
    $share = $txtShareName.Text.Trim()
    if (-not $ip -or -not $share) {
        [System.Windows.Forms.MessageBox]::Show("Please enter both Host IP and Printer Share Name!", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    $portName = "\\$ip\$share"
    try {
        Append-Log "Creating Local Port: $portName..." "INFO"
        Add-PrinterPort -Name $portName -ErrorAction Stop
        Append-Log "Local Port $portName created successfully!" "OK"
        Start-Process "control.exe" "printers"
    } catch {
        Append-Log "Add-PrinterPort returned: $($_.Exception.Message)" "WARN"
        Start-Process "control.exe" "printers"
    }
})

$btnOpenPrnMgmt.Add_Click({ Start-Process "printmanagement.msc" })
$btnOpenDevices.Add_Click({ Start-Process "control.exe" "printers" })

$btnRestartSpooler.Add_Click({
    try {
        Append-Log "Restarting Spooler service..." "INFO"
        Restart-Service -Name "Spooler" -Force
        Append-Log "Spooler restarted." "OK"
        Update-DiagnosticScan
    } catch {
        Append-Log "Spooler restart failed: $($_.Exception.Message)" "ERROR"
    }
})

$btnStartSpooler.Add_Click({
    try {
        Start-Service -Name "Spooler"
        Append-Log "Spooler service started." "OK"
        Update-DiagnosticScan
    } catch {
        Append-Log "Failed to start spooler: $($_.Exception.Message)" "ERROR"
    }
})

$btnStopSpooler.Add_Click({
    try {
        Stop-Service -Name "Spooler" -Force
        Append-Log "Spooler service stopped." "WARN"
        Update-DiagnosticScan
    } catch {
        Append-Log "Failed to stop spooler: $($_.Exception.Message)" "ERROR"
    }
})

$btnPurgeQueue.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to stop the Spooler and purge all pending print files (.spl / .shd)?", "Confirm Queue Purge", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            Append-Log "Stopping Spooler to purge queue..." "INFO"
            Stop-Service -Name "Spooler" -Force
            if (Test-Path $SpoolPrintersFolder) {
                $files = Get-ChildItem -Path "$SpoolPrintersFolder\*.*" -File
                $count = $files.Count
                $files | Remove-Item -Force
                Append-Log "Purged $count corrupted print job files from spool queue." "OK"
            }
            Start-Service -Name "Spooler"
            Append-Log "Spooler service restarted with clean print queue." "OK"
            Update-DiagnosticScan
            [System.Windows.Forms.MessageBox]::Show("Print queue purged and Spooler restarted cleanly!", "Purge Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            Append-Log "Failed to purge queue: $($_.Exception.Message)" "ERROR"
            Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
        }
    }
})

$btnExportReg.Add_Click({
    try {
        $regFile = Join-Path $scriptDir "..\WinPrintFix_Rules.reg"
        $regContent = @"
Windows Registry Editor Version 5.00

; ========================================================
; WinPrintFix - Universal Windows Print & SMB Sharing Fix
; ========================================================

; 1. PrintNightmare RPC Privacy Fix (0x0000011b)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print]
"RpcAuthnLevelPrivacyEnabled"=dword:00000000

; 2. Point and Print Driver v3 Policies (0x00000709)
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers]
"CopyFilesPolicy"=dword:00000001
"RpcClientProtocol"=dword:00000001
"RpcOverNamedPipes"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint]
"NoWarningNoElevationOnInstall"=dword:00000001
"NoWarningNoElevationOnUpdate"=dword:00000001
"RestrictDriverInstallationToAdministrators"=dword:00000000

; 3. Windows Print Spooler RPC Policies & NTLM Workgroup Fallback (0x00000bc4)
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC]
"RpcUseNamedPipeProtocol"=dword:00000001
"RpcAuthentication"=dword:00000000
"RpcProtocols"=dword:00000007
"ForceKerberosForRpc"=dword:00000000
"RpcTcpPort"=dword:00000000

; 4. Lanman SMB Insecure Guest & Disable Signing (0x80070035 / Access Denied Fix)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters]
"AllowInsecureGuestAuth"=dword:00000001
"EnableInsecureGuestLogons"=dword:00000001
"RequireSecuritySignature"=dword:00000000
"EnableSecuritySignature"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters]
"requiresecuritysignature"=dword:00000000
"enablesecuritysignature"=dword:00000000
"@
        Set-Content -Path $regFile -Value $regContent -Encoding ASCII
        Append-Log "Exported registry rules file: $regFile" "OK"
        [System.Windows.Forms.MessageBox]::Show("Registry file exported successfully!`nFile: $regFile", "Export Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Append-Log "Export .reg failed: $($_.Exception.Message)" "ERROR"
    }
})

$btnCopyLog.Add_Click({
    if ($txtLog.Text) {
        [System.Windows.Forms.Clipboard]::SetText($txtLog.Text)
        [System.Windows.Forms.MessageBox]::Show("Log copied to clipboard!", "Copied", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$btnExportLog.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.FileName = "WinPrintFix_Log_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".txt"
    $dlg.Filter = "Text Files (*.txt)|*.txt"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Set-Content -Path $dlg.FileName -Value $txtLog.Text -Encoding UTF8
        Append-Log "Log exported to $($dlg.FileName)" "OK"
    }
})

$btnClearLog.Add_Click({ $txtLog.Clear() })

# Initial population
$form.Add_Shown({
    Append-Log "WinPrintFix Pro Suite v1.1.0 initialized on $osProductName ($osDisplayVersion)." "INFO"
    Append-Log "Running with elevated Administrator privileges." "OK"
    Update-DiagnosticScan
    Update-WindowsUpdateStatus
})

# Show the GUI
[void]$form.ShowDialog()
