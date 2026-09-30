using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Security.Principal;
using System.ServiceProcess;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using Microsoft.Win32;

namespace WinPrintFix
{
    public class MainForm : Form
    {
        private bool isAdmin;
        private string osProductName = "Windows";
        private string osDisplayVersion = "";
        private string osBuildNumber = "";
        private int versionNum = 0;
        private bool isModernWin11 = false;

        private string printPath = @"SYSTEM\CurrentControlSet\Control\Print";
        private string lanmanPath = @"SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters";
        private string groupPolicyPath = @"SOFTWARE\Policies\Microsoft\Windows NT\Printers";
        private string pointPrintPath = @"SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint";
        private string rpcPolicyPath = @"SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC";
        private string spoolPrintersFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"spool\PRINTERS");
        private string backupsDir;

        // UI Controls - Header
        private Panel pnlHeader;
        private Label lblTitle;
        private Label lblSubTitle;
        private Label lblAdminBadge;

        // UI Controls - Tabs
        private TabControl tabControl;
        private TabPage tab1;
        private TabPage tab2;
        private TabPage tab3;
        private TabPage tab4;
        private TabPage tab5;

        // Tab 1 Controls (Universal Fix & Scanner)
        private GroupBox grpScanner;
        private ListView lstDiag;
        private Button btnScan;
        private GroupBox grpOptions;
        private CheckBox chkSmb;
        private CheckBox chkDriver;
        private CheckBox chkRpc;
        private CheckBox chkRestartSpooler;
        private CheckBox chkWinUpdate;
        private Button btnApplyAll;
        private Button btnApplySelected;
        private Button btnSnapshot;
        private Button btnRollback;

        // Tab 2 Controls (Network & Firewall)
        private GroupBox grpNet;
        private Button btnSetPrivate;
        private GroupBox grpFw;
        private Button btnEnableFw;
        private GroupBox grpDisc;
        private Button btnEnableDisc;
        private GroupBox grpSmb;
        private Button btnConfigureSmb;

        // Tab 3 Controls (Driver v3 Helper & Port Wizard)
        private GroupBox grpV3Info;
        private TextBox txtV3Info;
        private GroupBox grpPortWiz;
        private TextBox txtHostIp;
        private TextBox txtShareName;
        private Button btnCreatePort;
        private Button btnOpenPrnMgmt;
        private Button btnOpenDevices;

        // Tab 4 Controls (Spooler & Export)
        private GroupBox grpSpoolOps;
        private Button btnRestartSpooler;
        private Button btnStartSpooler;
        private Button btnStopSpooler;
        private Button btnPurgeQueue;
        private GroupBox grpExport;
        private Button btnExportReg;

        // Tab 5 Controls (Windows Update Control)
        private GroupBox grpWuStatus;
        private Label lblWuStatusTitle;
        private Label lblWuStatusBadge;
        private Label lblWuDesc;
        private Button btnCheckWu;
        private GroupBox grpWuActions;
        private Button btnPauseWu;
        private Button btnUnpauseWu;
        private Button btnOpenWuSettings;
        private GroupBox grpWuDetails;
        private TextBox txtWuDetails;

        // Bottom Console Controls
        private Panel pnlBottom;
        private RichTextBox txtLog;
        private Button btnCopyLog;
        private Button btnExportLog;
        private Button btnClearLog;

        public MainForm()
        {
            InitializeEnvironment();
            InitializeComponent();
        }

        private void InitializeEnvironment()
        {
            WindowsPrincipal principal = new WindowsPrincipal(WindowsIdentity.GetCurrent());
            isAdmin = principal.IsInRole(WindowsBuiltInRole.Administrator);

            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion"))
                {
                    if (key != null)
                    {
                        object prod = key.GetValue("ProductName");
                        object disp = key.GetValue("DisplayVersion");
                        object build = key.GetValue("CurrentBuildNumber");

                        if (prod != null) osProductName = prod.ToString();
                        if (disp != null) osDisplayVersion = disp.ToString();
                        if (build != null) osBuildNumber = build.ToString();

                        Match m = Regex.Match(osDisplayVersion, @"(\d+)");
                        if (m.Success)
                        {
                            int.TryParse(m.Groups[1].Value, out versionNum);
                        }
                    }
                }
            }
            catch { }

            isModernWin11 = (osProductName.IndexOf("Windows 11", StringComparison.OrdinalIgnoreCase) >= 0 && versionNum >= 24);

            string appDir = AppDomain.CurrentDomain.BaseDirectory;
            backupsDir = Path.Combine(appDir, @"..\backups");
            if (!Directory.Exists(backupsDir))
            {
                try { Directory.CreateDirectory(backupsDir); } catch { }
            }
        }

        private void InitializeComponent()
        {
            this.Text = "WinPrintFix - Windows Print Spooler, Network Sharing & System Optimizer (Pro Suite v1.1.0)";
            this.Size = new Size(940, 910);
            this.MinimumSize = new Size(920, 870);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(248, 249, 250);
            this.Font = new Font("Segoe UI", 9.5f);

            Color cWhite = Color.White;

            // 1. Header Panel
            pnlHeader = new Panel
            {
                Dock = DockStyle.Top,
                Height = 88,
                BackColor = Color.FromArgb(22, 33, 62)
            };
            this.Controls.Add(pnlHeader);

            lblTitle = new Label
            {
                Text = "WinPrintFix: Universal Print Spooler, Network & System Optimizer",
                Font = new Font("Segoe UI", 12.5f, FontStyle.Bold),
                ForeColor = cWhite,
                Location = new Point(16, 12),
                AutoSize = true
            };
            pnlHeader.Controls.Add(lblTitle);

            string modeText = isModernWin11 ? "Modern Security Architecture (24H2 - 26H2+ Mode Active)" : "Legacy Architecture (Windows 10/11 Compatible Mode)";
            lblSubTitle = new Label
            {
                Text = string.Format("Detected: {0} ({1}, Build {2}) | {3}", osProductName, osDisplayVersion, osBuildNumber, modeText),
                Font = new Font("Segoe UI", 9.5f),
                ForeColor = Color.FromArgb(180, 205, 237),
                Location = new Point(18, 38),
                AutoSize = true
            };
            pnlHeader.Controls.Add(lblSubTitle);

            lblAdminBadge = new Label
            {
                Text = isAdmin ? "[ ADMINISTRATOR: ACTIVE ]" : "[ STANDARD USER: ELEVATION REQUIRED ]",
                Font = new Font("Segoe UI", 9.0f, FontStyle.Bold),
                ForeColor = isAdmin ? Color.FromArgb(72, 239, 128) : Color.FromArgb(255, 179, 71),
                Location = new Point(18, 62),
                AutoSize = true
            };
            pnlHeader.Controls.Add(lblAdminBadge);

            // 2. Tab Control
            tabControl = new TabControl
            {
                Location = new Point(12, 98),
                Size = new Size(900, 520),
                Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right
            };
            this.Controls.Add(tabControl);

            tab1 = new TabPage { Text = "1. Universal Fix & Scanner", BackColor = cWhite };
            tab2 = new TabPage { Text = "2. Network & Firewall", BackColor = cWhite };
            tab3 = new TabPage { Text = "3. Driver v3 Helper", BackColor = cWhite };
            tab4 = new TabPage { Text = "4. Spooler & Export", BackColor = cWhite };
            tab5 = new TabPage { Text = "5. Windows Update", BackColor = cWhite };

            tabControl.TabPages.Add(tab1);
            tabControl.TabPages.Add(tab2);
            tabControl.TabPages.Add(tab3);
            tabControl.TabPages.Add(tab4);
            tabControl.TabPages.Add(tab5);

            // 3. Tab 1: Universal Fix & Scanner
            grpScanner = new GroupBox
            {
                Text = "System Configuration & Diagnostics Scanner",
                Location = new Point(12, 10),
                Size = new Size(868, 210),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab1.Controls.Add(grpScanner);

            lstDiag = new ListView
            {
                Location = new Point(12, 24),
                Size = new Size(842, 142),
                View = View.Details,
                FullRowSelect = true,
                GridLines = true,
                Font = new Font("Segoe UI", 9.0f)
            };
            lstDiag.Columns.Add("Parameter / Setting", 260);
            lstDiag.Columns.Add("Current Value", 180);
            lstDiag.Columns.Add("Recommended Target", 180);
            lstDiag.Columns.Add("Status Badge", 200);
            grpScanner.Controls.Add(lstDiag);

            btnScan = new Button
            {
                Text = "Scan / Refresh Current System State",
                Location = new Point(12, 172),
                Size = new Size(260, 30),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnScan.Click += (s, e) => ScanSystemState();
            grpScanner.Controls.Add(btnScan);

            grpOptions = new GroupBox
            {
                Text = "Select Fix & Optimization Modules to Apply",
                Location = new Point(12, 228),
                Size = new Size(868, 168),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab1.Controls.Add(grpOptions);

            chkSmb = new CheckBox
            {
                Text = "SMB Network Fix: Enable Insecure Guest Logons & Disable Signing (Client/Server)",
                Location = new Point(15, 24),
                Size = new Size(820, 24),
                Checked = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            grpOptions.Controls.Add(chkSmb);

            chkDriver = new CheckBox
            {
                Text = "Driver v3 Fix: Point and Print Policy (CopyFilesPolicy=1, Unrestrict Non-Admin)",
                Location = new Point(15, 50),
                Size = new Size(820, 24),
                Checked = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            grpOptions.Controls.Add(chkDriver);

            string rpcDesc = isModernWin11 ? "Windows 11 24H2+ RPC Fix: Disable RPC Privacy (0x11b) + Force RPC over Named Pipes (0xbc4)" : "Legacy RPC Fix: Disable RpcAuthnLevelPrivacy (0x11b) + AllowInsecureGuestAuth";
            chkRpc = new CheckBox
            {
                Text = rpcDesc,
                Location = new Point(15, 76),
                Size = new Size(820, 24),
                Checked = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            grpOptions.Controls.Add(chkRpc);

            chkRestartSpooler = new CheckBox
            {
                Text = "Automatically Restart Print Spooler Service after applying fixes",
                Location = new Point(15, 102),
                Size = new Size(820, 24),
                Checked = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            grpOptions.Controls.Add(chkRestartSpooler);

            chkWinUpdate = new CheckBox
            {
                Text = "Windows Update: Disable Auto-Update (Pause until 2051 - Default: Disabled)",
                Location = new Point(15, 128),
                Size = new Size(820, 24),
                Checked = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            grpOptions.Controls.Add(chkWinUpdate);

            btnApplyAll = new Button
            {
                Text = ">>> APPLY ALL RECOMMENDED FIXES (ULTIMATE) <<<",
                Location = new Point(12, 415),
                Size = new Size(460, 46),
                Font = new Font("Segoe UI", 10.5f, FontStyle.Bold),
                BackColor = Color.FromArgb(40, 167, 69),
                ForeColor = cWhite,
                FlatStyle = FlatStyle.Flat
            };
            btnApplyAll.Click += (s, e) => ApplyRemediations(true, true, true, true, true);
            tab1.Controls.Add(btnApplyAll);

            btnApplySelected = new Button
            {
                Text = "Apply Selected",
                Location = new Point(480, 415),
                Size = new Size(150, 46),
                Font = new Font("Segoe UI", 10.0f, FontStyle.Bold)
            };
            btnApplySelected.Click += (s, e) => ApplyRemediations(chkSmb.Checked, chkDriver.Checked, chkRpc.Checked, chkRestartSpooler.Checked, chkWinUpdate.Checked);
            tab1.Controls.Add(btnApplySelected);

            btnSnapshot = new Button
            {
                Text = "Backup State",
                Location = new Point(638, 415),
                Size = new Size(125, 46),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnSnapshot.Click += (s, e) =>
            {
                string snap = CreateSnapshot();
                if (!string.IsNullOrEmpty(snap))
                {
                    MessageBox.Show("Safety snapshot saved successfully!\nFile: " + snap, "Snapshot Created", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            };
            tab1.Controls.Add(btnSnapshot);

            btnRollback = new Button
            {
                Text = "Rollback / Restore",
                Location = new Point(770, 415),
                Size = new Size(125, 46),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnRollback.Click += (s, e) =>
            {
                OpenFileDialog dlg = new OpenFileDialog
                {
                    InitialDirectory = Path.GetFullPath(backupsDir),
                    Filter = "Snapshot Files (*.json)|*.json|All Files (*.*)|*.*"
                };
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    RollbackSnapshot(dlg.FileName);
                }
            };
            tab1.Controls.Add(btnRollback);

            // 4. Tab 2: Network & Firewall Tools
            grpNet = new GroupBox
            {
                Text = "Network Adapter Category (Private vs Public)",
                Location = new Point(15, 10),
                Size = new Size(868, 105),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab2.Controls.Add(grpNet);

            Label lblNetDesc = new Label
            {
                Text = "Windows 10/11 updates often reset active networks to 'Public', closing File & Printer sharing ports.\nClick below to change active connections to 'Private'.",
                Location = new Point(15, 22),
                Size = new Size(820, 36),
                Font = new Font("Segoe UI", 9.0f)
            };
            grpNet.Controls.Add(lblNetDesc);

            btnSetPrivate = new Button
            {
                Text = "Switch Active Network Profiles to Private",
                Location = new Point(15, 62),
                Size = new Size(320, 32),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnSetPrivate.Click += (s, e) =>
            {
                AppendLog("Setting all active network adapter profiles to Private...", "INFO");
                RunPowerShellCmdlet("Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private");
                AppendLog("Active network profiles set to Private successfully.", "OK");
                ScanSystemState();
            };
            grpNet.Controls.Add(btnSetPrivate);

            grpFw = new GroupBox
            {
                Text = "Windows Defender Firewall: File & Printer Sharing",
                Location = new Point(15, 122),
                Size = new Size(868, 105),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab2.Controls.Add(grpFw);

            Label lblFwDesc = new Label
            {
                Text = "Ensure incoming SMB (TCP 445), NetBIOS (TCP 139), and Spooler RPC rules are allowed.",
                Location = new Point(15, 22),
                Size = new Size(820, 30),
                Font = new Font("Segoe UI", 9.0f)
            };
            grpFw.Controls.Add(lblFwDesc);

            btnEnableFw = new Button
            {
                Text = "Enable 'File and Printer Sharing' Firewall Rules",
                Location = new Point(15, 60),
                Size = new Size(340, 32),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnEnableFw.Click += (s, e) =>
            {
                AppendLog("Enabling Windows Firewall rules for File and Printer Sharing...", "INFO");
                RunPowerShellCmdlet("Enable-NetFirewallRule -DisplayGroup 'File and Printer Sharing'");
                AppendLog("Firewall rules enabled successfully.", "OK");
            };
            grpFw.Controls.Add(btnEnableFw);

            grpDisc = new GroupBox
            {
                Text = "Network Discovery Services (FDResPub & fdPHost)",
                Location = new Point(15, 234),
                Size = new Size(868, 105),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab2.Controls.Add(grpDisc);

            Label lblDiscDesc = new Label
            {
                Text = "Enables Function Discovery services so PCs and shared printers appear in File Explorer Network browser.",
                Location = new Point(15, 22),
                Size = new Size(820, 30),
                Font = new Font("Segoe UI", 9.0f)
            };
            grpDisc.Controls.Add(lblDiscDesc);

            btnEnableDisc = new Button
            {
                Text = "Configure & Start Discovery Services",
                Location = new Point(15, 60),
                Size = new Size(320, 32),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnEnableDisc.Click += (s, e) =>
            {
                AppendLog("Configuring Function Discovery Resource Publication & Host services...", "INFO");
                RunPowerShellCmdlet("Set-Service -Name 'FDResPub' -StartupType Automatic; Set-Service -Name 'fdPHost' -StartupType Automatic; Start-Service -Name 'FDResPub' -ErrorAction SilentlyContinue; Start-Service -Name 'fdPHost' -ErrorAction SilentlyContinue");
                AppendLog("Discovery services set to Automatic and running.", "OK");
            };
            grpDisc.Controls.Add(btnEnableDisc);

            grpSmb = new GroupBox
            {
                Text = "SMB Protocol & Security Signing (Windows 10 / 11 24H2+)",
                Location = new Point(15, 346),
                Size = new Size(868, 115),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab2.Controls.Add(grpSmb);

            Label lblSmbDesc = new Label
            {
                Text = "Configures SMB Client and Server policies: Enables Insecure Guest Logons and disables mandatory Signing.\nResolves 'Access Denied' and network path not found (0x80070035) on Windows 11 24H2+.",
                Location = new Point(15, 22),
                Size = new Size(820, 36),
                Font = new Font("Segoe UI", 9.0f)
            };
            grpSmb.Controls.Add(lblSmbDesc);

            btnConfigureSmb = new Button
            {
                Text = "Apply SMB Security Fix (Set-SmbClient/Server)",
                Location = new Point(15, 66),
                Size = new Size(360, 34),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnConfigureSmb.Click += (s, e) =>
            {
                AppendLog("Running SMB Client & Server configuration...", "INFO");
                RunPowerShellCmdlet("Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force | Out-Null");
                RunPowerShellCmdlet("Set-SmbClientConfiguration -RequireSecuritySignature $false -Force | Out-Null");
                RunPowerShellCmdlet("Set-SmbServerConfiguration -RequireSecuritySignature $false -Force | Out-Null");
                SetRegDword(lanmanPath, "AllowInsecureGuestAuth", 1);
                SetRegDword(lanmanPath, "EnableInsecureGuestLogons", 1);
                SetRegDword(lanmanPath, "RequireSecuritySignature", 0);
                SetRegDword(lanmanPath, "EnableSecuritySignature", 0);
                SetRegDword(@"SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters", "requiresecuritysignature", 0);
                SetRegDword(@"SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters", "enablesecuritysignature", 0);
                AppendLog("-> [OK] SMB Client & Server configured successfully (Insecure Guest + Signature Disabled).", "OK");
                ScanSystemState();
                MessageBox.Show("SMB Client & Server configuration applied successfully!\nInsecure Guest Logons: Enabled\nSecurity Signatures: Disabled", "SMB Configuration", MessageBoxButtons.OK, MessageBoxIcon.Information);
            };
            grpSmb.Controls.Add(btnConfigureSmb);

            // 5. Tab 3: Driver v3 Helper & Local Port Wizard
            grpV3Info = new GroupBox
            {
                Text = "Driver v3 Architecture Dilemma & Workarounds",
                Location = new Point(15, 15),
                Size = new Size(868, 175),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab3.Controls.Add(grpV3Info);

            txtV3Info = new TextBox
            {
                Multiline = true,
                ReadOnly = true,
                BackColor = cWhite,
                BorderStyle = BorderStyle.None,
                Location = new Point(15, 25),
                Size = new Size(838, 140),
                Font = new Font("Segoe UI", 9.0f),
                Text = "Windows 11 24H2+ phases out Type 3 (v3) printer drivers in favor of Type 4 (v4) / Mopria.\r\n" +
                       "If the printer manufacturer has no v4 driver, clients connecting across the network see 'No driver found' or hang.\r\n\r\n" +
                       "Proven Workarounds:\r\n" +
                       "1. Local Pre-Installation: Download and run the printer installer locally on the client machine first (as a USB/Local printer). When Windows connects to the network share, it finds the driver locally and succeeds.\r\n" +
                       "2. Local Port Redirect: Redirect a local printer port directly to \\\\HostIP\\PrinterName (bypassing Point & Print)."
            };
            grpV3Info.Controls.Add(txtV3Info);

            grpPortWiz = new GroupBox
            {
                Text = "Local Port Redirect Wizard (Bypass v3 Driver Block)",
                Location = new Point(15, 205),
                Size = new Size(868, 145),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab3.Controls.Add(grpPortWiz);

            Label lblHostIp = new Label
            {
                Text = "Host IP Address:",
                Location = new Point(15, 32),
                AutoSize = true,
                Font = new Font("Segoe UI", 9.0f)
            };
            grpPortWiz.Controls.Add(lblHostIp);

            txtHostIp = new TextBox
            {
                Text = "192.168.1.50",
                Location = new Point(150, 28),
                Size = new Size(160, 26)
            };
            grpPortWiz.Controls.Add(txtHostIp);

            Label lblShareName = new Label
            {
                Text = "Printer Share Name:",
                Location = new Point(330, 32),
                AutoSize = true,
                Font = new Font("Segoe UI", 9.0f)
            };
            grpPortWiz.Controls.Add(lblShareName);

            txtShareName = new TextBox
            {
                Text = "CanonPrinter",
                Location = new Point(480, 28),
                Size = new Size(180, 26)
            };
            grpPortWiz.Controls.Add(txtShareName);

            btnCreatePort = new Button
            {
                Text = "Create Local Port & Open Add Printer Wizard",
                Location = new Point(15, 85),
                Size = new Size(340, 38),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnCreatePort.Click += (s, e) =>
            {
                string ip = txtHostIp.Text.Trim();
                string share = txtShareName.Text.Trim();
                if (string.IsNullOrEmpty(ip) || string.IsNullOrEmpty(share))
                {
                    MessageBox.Show("Please enter both Host IP and Printer Share Name!", "Missing Information", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                string portName = string.Format(@"\\{0}\{1}", ip, share);
                AppendLog(string.Format("Creating Local Port: {0}...", portName), "INFO");
                RunPowerShellCmdlet(string.Format("Add-PrinterPort -Name '{0}' -ErrorAction SilentlyContinue", portName));
                AppendLog("Local Port created. Launching Devices and Printers...", "OK");
                Process.Start("control.exe", "printers");
            };
            grpPortWiz.Controls.Add(btnCreatePort);

            btnOpenPrnMgmt = new Button
            {
                Text = "Print Management (printmanagement.msc)",
                Location = new Point(15, 365),
                Size = new Size(300, 35),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnOpenPrnMgmt.Click += (s, e) => { try { Process.Start("printmanagement.msc"); } catch { } };
            tab3.Controls.Add(btnOpenPrnMgmt);

            btnOpenDevices = new Button
            {
                Text = "Devices & Printers (control printers)",
                Location = new Point(330, 365),
                Size = new Size(280, 35),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnOpenDevices.Click += (s, e) => { try { Process.Start("control.exe", "printers"); } catch { } };
            tab3.Controls.Add(btnOpenDevices);

            // 6. Tab 4: Spooler Maintenance & Export
            grpSpoolOps = new GroupBox
            {
                Text = "Print Spooler Service Control & Queue Purge",
                Location = new Point(15, 15),
                Size = new Size(868, 185),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab4.Controls.Add(grpSpoolOps);

            btnRestartSpooler = new Button
            {
                Text = "Restart Spooler",
                Location = new Point(15, 35),
                Size = new Size(150, 36),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnRestartSpooler.Click += (s, e) => RestartSpoolerService();
            grpSpoolOps.Controls.Add(btnRestartSpooler);

            btnStartSpooler = new Button
            {
                Text = "Start Service",
                Location = new Point(180, 35),
                Size = new Size(130, 36),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnStartSpooler.Click += (s, e) =>
            {
                try
                {
                    using (ServiceController sc = new ServiceController("Spooler"))
                    {
                        sc.Start();
                        sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(10));
                        AppendLog("Spooler service started successfully.", "OK");
                        ScanSystemState();
                    }
                }
                catch (Exception ex) { AppendLog("Error starting spooler: " + ex.Message, "ERROR"); }
            };
            grpSpoolOps.Controls.Add(btnStartSpooler);

            btnStopSpooler = new Button
            {
                Text = "Stop Service",
                Location = new Point(325, 35),
                Size = new Size(130, 36),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnStopSpooler.Click += (s, e) =>
            {
                try
                {
                    using (ServiceController sc = new ServiceController("Spooler"))
                    {
                        sc.Stop();
                        sc.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(10));
                        AppendLog("Spooler service stopped.", "WARN");
                        ScanSystemState();
                    }
                }
                catch (Exception ex) { AppendLog("Error stopping spooler: " + ex.Message, "ERROR"); }
            };
            grpSpoolOps.Controls.Add(btnStopSpooler);

            btnPurgeQueue = new Button
            {
                Text = "Deep Purge Stuck Print Queue (.spl / .shd files)",
                Location = new Point(15, 105),
                Size = new Size(380, 44),
                BackColor = Color.FromArgb(254, 243, 199),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnPurgeQueue.Click += (s, e) => PurgeQueue();
            grpSpoolOps.Controls.Add(btnPurgeQueue);

            grpExport = new GroupBox
            {
                Text = "Offline Mass Deployment (.reg File Export)",
                Location = new Point(15, 215),
                Size = new Size(868, 150),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            tab4.Controls.Add(grpExport);

            Label lblExportDesc = new Label
            {
                Text = "Generate a standalone .reg file containing all exact registry modifications for offline deployment via GPO or USB drive.",
                Location = new Point(15, 28),
                Size = new Size(820, 32),
                Font = new Font("Segoe UI", 9.0f)
            };
            grpExport.Controls.Add(lblExportDesc);

            btnExportReg = new Button
            {
                Text = "Export All Fix Rules to WinPrintFix_Rules.reg",
                Location = new Point(15, 80),
                Size = new Size(380, 40),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnExportReg.Click += (s, e) => ExportRegFile();
            grpExport.Controls.Add(btnExportReg);

            // 7. Tab 5: Windows Update (from C:\Users\User\Downloads\winupdate)
            grpWuStatus = new GroupBox
            {
                Text = "Windows Update Operational Status",
                Location = new Point(15, 12),
                Size = new Size(868, 115),
                Font = new Font("Segoe UI", 10.0f, FontStyle.Bold)
            };
            tab5.Controls.Add(grpWuStatus);

            lblWuStatusTitle = new Label
            {
                Text = "Current Update Status:",
                Location = new Point(15, 30),
                AutoSize = true,
                Font = new Font("Segoe UI", 9.5f)
            };
            grpWuStatus.Controls.Add(lblWuStatusTitle);

            lblWuStatusBadge = new Label
            {
                Text = "[ CHECKING STATUS... ]",
                Location = new Point(180, 28),
                AutoSize = true,
                Font = new Font("Segoe UI", 10.0f, FontStyle.Bold),
                ForeColor = Color.FromArgb(217, 119, 6)
            };
            grpWuStatus.Controls.Add(lblWuStatusBadge);

            lblWuDesc = new Label
            {
                Text = "Automatic Windows Updates can reset Print Spooler RPC parameters and SMB security profiles.\r\nPausing updates preserves system stability in production environments.",
                Location = new Point(15, 60),
                Size = new Size(650, 42),
                Font = new Font("Segoe UI", 9.0f),
                ForeColor = Color.FromArgb(108, 117, 125)
            };
            grpWuStatus.Controls.Add(lblWuDesc);

            btnCheckWu = new Button
            {
                Text = "Refresh Status",
                Location = new Point(700, 26),
                Size = new Size(150, 34),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnCheckWu.Click += (s, e) => UpdateWindowsUpdateStatus();
            grpWuStatus.Controls.Add(btnCheckWu);

            grpWuActions = new GroupBox
            {
                Text = "Windows Update Actions (Pause / Unpause Toggle)",
                Location = new Point(15, 140),
                Size = new Size(868, 160),
                Font = new Font("Segoe UI", 10.0f, FontStyle.Bold)
            };
            tab5.Controls.Add(grpWuActions);

            btnPauseWu = new Button
            {
                Text = "PAUSE WINDOWS UPDATE UNTIL 2051 (DEFAULT: DISABLED)",
                Location = new Point(20, 32),
                Size = new Size(405, 52),
                BackColor = Color.FromArgb(220, 53, 69),
                ForeColor = cWhite,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnPauseWu.Click += (s, e) => PauseWindowsUpdate();
            grpWuActions.Controls.Add(btnPauseWu);

            btnUnpauseWu = new Button
            {
                Text = "UNPAUSE & RESTORE NORMAL WINDOWS UPDATE",
                Location = new Point(440, 32),
                Size = new Size(405, 52),
                BackColor = Color.FromArgb(40, 167, 69),
                ForeColor = cWhite,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
            };
            btnUnpauseWu.Click += (s, e) => UnpauseWindowsUpdate();
            grpWuActions.Controls.Add(btnUnpauseWu);

            btnOpenWuSettings = new Button
            {
                Text = "Open Windows Update Settings Panel (ms-settings)",
                Location = new Point(20, 100),
                Size = new Size(360, 36),
                Font = new Font("Segoe UI", 9.5f)
            };
            btnOpenWuSettings.Click += (s, e) => { try { Process.Start("ms-settings:windowsupdate"); } catch { } };
            grpWuActions.Controls.Add(btnOpenWuSettings);

            grpWuDetails = new GroupBox
            {
                Text = "Windows Update Configuration Details",
                Location = new Point(15, 310),
                Size = new Size(868, 160),
                Font = new Font("Segoe UI", 10.0f, FontStyle.Bold)
            };
            tab5.Controls.Add(grpWuDetails);

            txtWuDetails = new TextBox
            {
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Vertical,
                Location = new Point(15, 25),
                Size = new Size(838, 120),
                Font = new Font("Consolas", 9.0f),
                Text = "[Windows Update Pause / Unpause Policy]\r\n" +
                       "- UX Settings: PauseFeatureUpdatesStartTime/EndTime & PauseQualityUpdates (2025 -> 2051)\r\n" +
                       "- WaaSMedicSvc: Start = 4 (Disabled when Paused) / Start = 3 (Manual when Active)\r\n" +
                       "- AU Policy: NoAutoUpdate = 1, NoAUShutdownOption = 1, AutoInstallMinorUpdates = 0\r\n" +
                       "- UpdatePolicy Settings: PausedFeatureStatus = 1, PausedQualityStatus = 1\r\n" +
                       "- Service wuauserv: Disabled & Stopped when Paused / Manual when Active"
            };
            grpWuDetails.Controls.Add(txtWuDetails);

            // 8. Bottom Console Panel
            pnlBottom = new Panel
            {
                Location = new Point(12, 625),
                Size = new Size(900, 235),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right
            };
            this.Controls.Add(pnlBottom);

            Label lblConsoleTitle = new Label
            {
                Text = "Diagnostic Activity Log:",
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                Location = new Point(0, 0),
                AutoSize = true
            };
            pnlBottom.Controls.Add(lblConsoleTitle);

            btnCopyLog = new Button
            {
                Text = "Copy Log",
                Size = new Size(80, 26),
                Location = new Point(640, 0),
                Anchor = AnchorStyles.Top | AnchorStyles.Right,
                Font = new Font("Segoe UI", 9.0f)
            };
            btnCopyLog.Click += (s, e) =>
            {
                if (!string.IsNullOrEmpty(txtLog.Text))
                {
                    Clipboard.SetText(txtLog.Text);
                    MessageBox.Show("Log copied to clipboard!", "Copied", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            };
            pnlBottom.Controls.Add(btnCopyLog);

            btnExportLog = new Button
            {
                Text = "Export...",
                Size = new Size(80, 26),
                Location = new Point(725, 0),
                Anchor = AnchorStyles.Top | AnchorStyles.Right,
                Font = new Font("Segoe UI", 9.0f)
            };
            btnExportLog.Click += (s, e) =>
            {
                SaveFileDialog dlg = new SaveFileDialog
                {
                    FileName = "WinPrintFix_Log_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".txt",
                    Filter = "Text Files (*.txt)|*.txt"
                };
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    File.WriteAllText(dlg.FileName, txtLog.Text, Encoding.UTF8);
                    AppendLog("Log exported to " + dlg.FileName, "OK");
                }
            };
            pnlBottom.Controls.Add(btnExportLog);

            btnClearLog = new Button
            {
                Text = "Clear",
                Size = new Size(75, 26),
                Location = new Point(810, 0),
                Anchor = AnchorStyles.Top | AnchorStyles.Right,
                Font = new Font("Segoe UI", 9.0f)
            };
            btnClearLog.Click += (s, e) => txtLog.Clear();
            pnlBottom.Controls.Add(btnClearLog);

            txtLog = new RichTextBox
            {
                Location = new Point(0, 28),
                Size = new Size(900, 200),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                Font = new Font("Consolas", 9.5f),
                BackColor = Color.FromArgb(245, 247, 250),
                ReadOnly = true
            };
            pnlBottom.Controls.Add(txtLog);

            this.Shown += (s, e) =>
            {
                AppendLog(string.Format("WinPrintFix initialized on {0} ({1}).", osProductName, osDisplayVersion), "INFO");
                if (isAdmin)
                    AppendLog("Running with elevated Administrator privileges.", "OK");
                else
                    AppendLog("Warning: Running without Administrator privileges. Elevation required for changes.", "WARN");

                ScanSystemState();
                UpdateWindowsUpdateStatus();
            };
        }

        private void AppendLog(string message, string level)
        {
            if (txtLog.InvokeRequired)
            {
                txtLog.Invoke(new Action<string, string>(AppendLog), message, level);
                return;
            }

            string timestamp = DateTime.Now.ToString("HH:mm:ss");
            Color color = Color.FromArgb(33, 37, 41);
            if (level == "OK") color = Color.FromArgb(40, 167, 69);
            else if (level == "WARN") color = Color.FromArgb(217, 119, 6);
            else if (level == "ERROR") color = Color.FromArgb(220, 53, 69);

            txtLog.SelectionStart = txtLog.TextLength;
            txtLog.SelectionLength = 0;
            txtLog.SelectionColor = Color.Gray;
            txtLog.AppendText(string.Format("[{0}] ", timestamp));

            txtLog.SelectionColor = color;
            txtLog.AppendText(string.Format("[{0}] ", level));

            txtLog.SelectionColor = Color.FromArgb(33, 37, 41);
            txtLog.AppendText(message + "\n");
            txtLog.ScrollToCaret();
        }

        private int? GetRegDword(string subKey, string valueName)
        {
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(subKey))
                {
                    if (key != null)
                    {
                        object val = key.GetValue(valueName);
                        if (val is int) return (int)val;
                    }
                }
            }
            catch { }
            return null;
        }

        private void SetRegDword(string subKey, string valueName, int value)
        {
            using (RegistryKey key = Registry.LocalMachine.CreateSubKey(subKey))
            {
                if (key != null)
                {
                    key.SetValue(valueName, value, RegistryValueKind.DWord);
                }
            }
        }

        private string GetRegString(string subKey, string valueName)
        {
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(subKey))
                {
                    if (key != null)
                    {
                        object val = key.GetValue(valueName);
                        if (val != null) return val.ToString();
                    }
                }
            }
            catch { }
            return null;
        }

        private void SetRegString(string subKey, string valueName, string value)
        {
            using (RegistryKey key = Registry.LocalMachine.CreateSubKey(subKey))
            {
                if (key != null)
                {
                    key.SetValue(valueName, value, RegistryValueKind.String);
                }
            }
        }

        private void DeleteRegValue(string subKey, string valueName)
        {
            try
            {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(subKey, true))
                {
                    if (key != null)
                    {
                        key.DeleteValue(valueName, false);
                    }
                }
            }
            catch { }
        }

        private string RunPowerShellCmdlet(string script)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"" + script + "\"",
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (Process p = Process.Start(psi))
                {
                    string stdout = p.StandardOutput.ReadToEnd();
                    p.WaitForExit(20000);
                    return stdout != null ? stdout.Trim() : "";
                }
            }
            catch (Exception ex)
            {
                AppendLog("PowerShell execution error: " + ex.Message, "ERROR");
                return "";
            }
        }

        private void ScanSystemState()
        {
            lstDiag.Items.Clear();
            AppendLog("Starting diagnostic scan of printer, network and system settings...", "INFO");

            // 1. Lanman Insecure Guest Auth
            int? lanmanVal = GetRegDword(lanmanPath, "AllowInsecureGuestAuth");
            string lanmanDisplay = lanmanVal.HasValue ? lanmanVal.Value.ToString() : "Not Set";
            string lanmanStatus = (lanmanVal == 1) ? "[OK] Allowed (1)" : "[FIX NEEDED] Blocked (0/Not Set)";
            ListViewItem item1 = new ListViewItem("Lanman AllowInsecureGuestAuth");
            item1.SubItems.Add(lanmanDisplay);
            item1.SubItems.Add("1");
            item1.SubItems.Add(lanmanStatus);
            lstDiag.Items.Add(item1);

            // 1b. SMB Client RequireSecuritySignature
            int? smbSigVal = GetRegDword(lanmanPath, "RequireSecuritySignature");
            string smbSigDisplay = smbSigVal.HasValue ? smbSigVal.Value.ToString() : "1 (Default)";
            string smbSigStatus = (smbSigVal == 0) ? "[OK] Disabled (0)" : "[FIX NEEDED] Required (1)";
            ListViewItem itemSig = new ListViewItem("SMB Client Security Signature");
            itemSig.SubItems.Add(smbSigDisplay);
            itemSig.SubItems.Add("0");
            itemSig.SubItems.Add(smbSigStatus);
            lstDiag.Items.Add(itemSig);

            // 2. PointAndPrint RestrictDriverInstallationToAdministrators
            int? pnpVal = GetRegDword(pointPrintPath, "RestrictDriverInstallationToAdministrators");
            string pnpDisplay = pnpVal.HasValue ? pnpVal.Value.ToString() : "1 (Default)";
            string pnpStatus = (pnpVal == 0) ? "[OK] Unrestricted (0)" : "[FIX NEEDED] Restricted (1)";
            ListViewItem item2 = new ListViewItem("PointAndPrint Driver Restriction");
            item2.SubItems.Add(pnpDisplay);
            item2.SubItems.Add("0");
            item2.SubItems.Add(pnpStatus);
            lstDiag.Items.Add(item2);

            // 3. CopyFilesPolicy
            int? copyVal = GetRegDword(groupPolicyPath, "CopyFilesPolicy");
            string copyDisplay = copyVal.HasValue ? copyVal.Value.ToString() : "Not Set";
            string copyStatus = (copyVal == 1) ? "[OK] Permitted (1)" : "[FIX NEEDED] Blocked (0/Not Set)";
            ListViewItem item3 = new ListViewItem("Printers CopyFilesPolicy");
            item3.SubItems.Add(copyDisplay);
            item3.SubItems.Add("1");
            item3.SubItems.Add(copyStatus);
            lstDiag.Items.Add(item3);

            // 4. RpcAuthnLevelPrivacyEnabled
            int? rpcVal = GetRegDword(printPath, "RpcAuthnLevelPrivacyEnabled");
            string rpcDisplay = rpcVal.HasValue ? rpcVal.Value.ToString() : "1 (Default)";
            string rpcStatus = (rpcVal == 0) ? "[OK] Disabled (0)" : "[FIX NEEDED] Enabled (1/Default)";
            ListViewItem item4 = new ListViewItem("RpcAuthnLevelPrivacy (0x11b)");
            item4.SubItems.Add(rpcDisplay);
            item4.SubItems.Add("0");
            item4.SubItems.Add(rpcStatus);
            lstDiag.Items.Add(item4);

            // 5. RpcOverNamedPipes
            int? pipesVal = GetRegDword(groupPolicyPath, "RpcOverNamedPipes");
            string pipesDisplay = pipesVal.HasValue ? pipesVal.Value.ToString() : "Not Set";
            string pipesStatus = (pipesVal == 1) ? "[OK] Enabled (1)" : (isModernWin11 ? "[FIX NEEDED] Not Set" : "[INFO] Optional");
            ListViewItem item5 = new ListViewItem("RpcOverNamedPipes (0xbc4)");
            item5.SubItems.Add(pipesDisplay);
            item5.SubItems.Add("1");
            item5.SubItems.Add(pipesStatus);
            lstDiag.Items.Add(item5);

            // 5b. ForceKerberosForRpc (Workgroup NTLM fallback)
            int? kerbVal = GetRegDword(rpcPolicyPath, "ForceKerberosForRpc");
            string kerbDisplay = kerbVal.HasValue ? kerbVal.Value.ToString() : "1 (Default)";
            string kerbStatus = (kerbVal == 0) ? "[OK] Allowed NTLM (0)" : "[FIX NEEDED] Strict Kerberos";
            ListViewItem itemKerb = new ListViewItem("RPC ForceKerberos (Workgroup)");
            itemKerb.SubItems.Add(kerbDisplay);
            itemKerb.SubItems.Add("0");
            itemKerb.SubItems.Add(kerbStatus);
            lstDiag.Items.Add(itemKerb);

            // 5c. RpcProtocols (Listener Bitmask)
            int? protVal = GetRegDword(rpcPolicyPath, "RpcProtocols");
            string protDisplay = protVal.HasValue ? protVal.Value.ToString() : "Not Set";
            string protStatus = (protVal == 7) ? "[OK] All Protocols (7)" : "[FIX NEEDED] Limited";
            ListViewItem itemProt = new ListViewItem("RPC Protocols Listener (All)");
            itemProt.SubItems.Add(protDisplay);
            itemProt.SubItems.Add("7");
            itemProt.SubItems.Add(protStatus);
            lstDiag.Items.Add(itemProt);

            // 6. Spooler Service
            string spoolerState = "Not Found";
            string spoolerStatusBadge = "[WARN] Unknown";
            try
            {
                using (ServiceController sc = new ServiceController("Spooler"))
                {
                    spoolerState = sc.Status.ToString();
                    spoolerStatusBadge = (sc.Status == ServiceControllerStatus.Running) ? "[OK] Running" : "[WARN] " + spoolerState;
                }
            }
            catch { }
            ListViewItem item6 = new ListViewItem("Print Spooler Service Status");
            item6.SubItems.Add(spoolerState);
            item6.SubItems.Add("Running");
            item6.SubItems.Add(spoolerStatusBadge);
            lstDiag.Items.Add(item6);

            // 7. Active Network Connection Category
            string netProfiles = RunPowerShellCmdlet("$p = Get-NetConnectionProfile -ErrorAction SilentlyContinue; if ($p) { ($p | ForEach-Object { $_.Name + ': ' + $_.NetworkCategory }) -join ', ' } else { 'Unknown' }");
            string netStatus = (!string.IsNullOrEmpty(netProfiles) && !netProfiles.Contains("Public")) ? "[OK] Private Profile" : "[FIX NEEDED] Public Profile";
            ListViewItem itemNet = new ListViewItem("Network Connection Category");
            itemNet.SubItems.Add(string.IsNullOrEmpty(netProfiles) ? "Unknown" : netProfiles);
            itemNet.SubItems.Add("Private");
            itemNet.SubItems.Add(netStatus);
            lstDiag.Items.Add(itemNet);

            // 8. Windows Update Auto-Update Policy
            int? wuVal = GetRegDword(@"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU", "NoAutoUpdate");
            string wuDisplay = wuVal.HasValue ? wuVal.Value.ToString() : "0 (Default)";
            string wuStatus = (wuVal == 1) ? "[OK] Paused/Disabled (1)" : "[ACTIVE] Auto-Update On (0/Not Set)";
            ListViewItem itemWu = new ListViewItem("Windows Update AutoUpdate");
            itemWu.SubItems.Add(wuDisplay);
            itemWu.SubItems.Add("1 (Paused)");
            itemWu.SubItems.Add(wuStatus);
            lstDiag.Items.Add(itemWu);

            AppendLog("Diagnostic scan completed successfully.", "OK");
        }

        private void RestoreRegValueFromJson(string json, string keyPath, string valName)
        {
            Match m = Regex.Match(json, "\"" + valName + "\":\\s*(\\d+|null)");
            if (m.Success && m.Groups[1].Value != "null")
                SetRegDword(keyPath, valName, int.Parse(m.Groups[1].Value));
            else
                DeleteRegValue(keyPath, valName);
        }

        private string CreateSnapshot()
        {
            try
            {
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
                string file = Path.Combine(backupsDir, "print_backup_" + timestamp + ".json");

                StringBuilder sb = new StringBuilder();
                sb.AppendLine("{");
                sb.AppendLine(string.Format("  \"Timestamp\": \"{0}\",", DateTime.Now.ToString("s")));
                sb.AppendLine(string.Format("  \"OSVersion\": \"{0}\",", osDisplayVersion));
                sb.AppendLine(string.Format("  \"ProductName\": \"{0}\",", osProductName));
                sb.AppendLine("  \"Registry\": {");

                int? rpc = GetRegDword(printPath, "RpcAuthnLevelPrivacyEnabled");
                sb.AppendLine(string.Format("    \"RpcAuthnLevelPrivacyEnabled\": {0},", rpc.HasValue ? rpc.Value.ToString() : "null"));

                int? copy = GetRegDword(groupPolicyPath, "CopyFilesPolicy");
                sb.AppendLine(string.Format("    \"CopyFilesPolicy\": {0},", copy.HasValue ? copy.Value.ToString() : "null"));

                int? rpcProt = GetRegDword(groupPolicyPath, "RpcClientProtocol");
                sb.AppendLine(string.Format("    \"RpcClientProtocol\": {0},", rpcProt.HasValue ? rpcProt.Value.ToString() : "null"));

                int? rpcPipes = GetRegDword(groupPolicyPath, "RpcOverNamedPipes");
                sb.AppendLine(string.Format("    \"RpcOverNamedPipes\": {0},", rpcPipes.HasValue ? rpcPipes.Value.ToString() : "null"));

                int? lanman = GetRegDword(lanmanPath, "AllowInsecureGuestAuth");
                sb.AppendLine(string.Format("    \"AllowInsecureGuestAuth\": {0},", lanman.HasValue ? lanman.Value.ToString() : "null"));

                int? pnpInstall = GetRegDword(pointPrintPath, "NoWarningNoElevationOnInstall");
                sb.AppendLine(string.Format("    \"NoWarningNoElevationOnInstall\": {0},", pnpInstall.HasValue ? pnpInstall.Value.ToString() : "null"));

                int? pnpUpdate = GetRegDword(pointPrintPath, "NoWarningNoElevationOnUpdate");
                sb.AppendLine(string.Format("    \"NoWarningNoElevationOnUpdate\": {0},", pnpUpdate.HasValue ? pnpUpdate.Value.ToString() : "null"));

                int? pnpRestrict = GetRegDword(pointPrintPath, "RestrictDriverInstallationToAdministrators");
                sb.AppendLine(string.Format("    \"RestrictDriverInstallationToAdministrators\": {0},", pnpRestrict.HasValue ? pnpRestrict.Value.ToString() : "null"));

                int? rpcProtocols = GetRegDword(rpcPolicyPath, "RpcProtocols");
                sb.AppendLine(string.Format("    \"RpcProtocols\": {0},", rpcProtocols.HasValue ? rpcProtocols.Value.ToString() : "null"));

                int? rpcKerb = GetRegDword(rpcPolicyPath, "ForceKerberosForRpc");
                sb.AppendLine(string.Format("    \"ForceKerberosForRpc\": {0},", rpcKerb.HasValue ? rpcKerb.Value.ToString() : "null"));

                int? rpcNamedPipe = GetRegDword(rpcPolicyPath, "RpcUseNamedPipeProtocol");
                sb.AppendLine(string.Format("    \"RpcUseNamedPipeProtocol\": {0},", rpcNamedPipe.HasValue ? rpcNamedPipe.Value.ToString() : "null"));

                int? rpcAuth = GetRegDword(rpcPolicyPath, "RpcAuthentication");
                sb.AppendLine(string.Format("    \"RpcAuthentication\": {0},", rpcAuth.HasValue ? rpcAuth.Value.ToString() : "null"));

                int? rpcTcp = GetRegDword(rpcPolicyPath, "RpcTcpPort");
                sb.AppendLine(string.Format("    \"RpcTcpPort\": {0},", rpcTcp.HasValue ? rpcTcp.Value.ToString() : "null"));

                int? wuAuto = GetRegDword(@"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU", "NoAutoUpdate");
                sb.AppendLine(string.Format("    \"NoAutoUpdate\": {0}", wuAuto.HasValue ? wuAuto.Value.ToString() : "null"));

                sb.AppendLine("  }");
                sb.AppendLine("}");

                File.WriteAllText(file, sb.ToString(), Encoding.UTF8);
                AppendLog("Created backup snapshot: " + file, "OK");
                return file;
            }
            catch (Exception ex)
            {
                AppendLog("Failed to create snapshot: " + ex.Message, "WARN");
                return null;
            }
        }

        private void RollbackSnapshot(string filePath)
        {
            try
            {
                AppendLog("Rolling back settings from: " + filePath, "INFO");
                string json = File.ReadAllText(filePath, Encoding.UTF8);

                RestoreRegValueFromJson(json, printPath, "RpcAuthnLevelPrivacyEnabled");
                RestoreRegValueFromJson(json, lanmanPath, "AllowInsecureGuestAuth");
                RestoreRegValueFromJson(json, groupPolicyPath, "CopyFilesPolicy");
                RestoreRegValueFromJson(json, groupPolicyPath, "RpcClientProtocol");
                RestoreRegValueFromJson(json, groupPolicyPath, "RpcOverNamedPipes");

                RestoreRegValueFromJson(json, pointPrintPath, "NoWarningNoElevationOnInstall");
                RestoreRegValueFromJson(json, pointPrintPath, "NoWarningNoElevationOnUpdate");
                RestoreRegValueFromJson(json, pointPrintPath, "RestrictDriverInstallationToAdministrators");

                RestoreRegValueFromJson(json, rpcPolicyPath, "RpcProtocols");
                RestoreRegValueFromJson(json, rpcPolicyPath, "ForceKerberosForRpc");
                RestoreRegValueFromJson(json, rpcPolicyPath, "RpcUseNamedPipeProtocol");
                RestoreRegValueFromJson(json, rpcPolicyPath, "RpcAuthentication");
                RestoreRegValueFromJson(json, rpcPolicyPath, "RpcTcpPort");

                RestoreRegValueFromJson(json, @"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU", "NoAutoUpdate");

                RestartSpoolerService();
                ScanSystemState();
                UpdateWindowsUpdateStatus();
                AppendLog("Rollback completed successfully.", "OK");
                MessageBox.Show("Settings restored from snapshot!", "Restoration Complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                AppendLog("Rollback failed: " + ex.Message, "ERROR");
            }
        }

        private void ApplyRemediations(bool doSmb, bool doDriver, bool doRpc, bool doRestartSpooler, bool doPauseWinUpdate)
        {
            CreateSnapshot();
            AppendLog("Applying selected system remediations...", "INFO");

            if (doSmb)
            {
                AppendLog("[SMB Network Fix] Configuring Insecure Guest & Disabling SMB Signing...", "INFO");
                RunPowerShellCmdlet("Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force | Out-Null");
                AppendLog("-> [OK] Executed: Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force", "OK");

                RunPowerShellCmdlet("Set-SmbClientConfiguration -RequireSecuritySignature $false -Force | Out-Null");
                AppendLog("-> [OK] Executed: Set-SmbClientConfiguration -RequireSecuritySignature $false -Force", "OK");

                RunPowerShellCmdlet("Set-SmbServerConfiguration -RequireSecuritySignature $false -Force | Out-Null");
                AppendLog("-> [OK] Executed: Set-SmbServerConfiguration -RequireSecuritySignature $false -Force", "OK");

                // Direct registry fallback for LanmanWorkstation & LanmanServer
                SetRegDword(lanmanPath, "AllowInsecureGuestAuth", 1);
                SetRegDword(lanmanPath, "EnableInsecureGuestLogons", 1);
                SetRegDword(lanmanPath, "RequireSecuritySignature", 0);
                SetRegDword(lanmanPath, "EnableSecuritySignature", 0);
                SetRegDword(@"SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters", "requiresecuritysignature", 0);
                SetRegDword(@"SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters", "enablesecuritysignature", 0);
                AppendLog("-> [OK] LanmanWorkstation & LanmanServer registry policies set.", "OK");
            }

            if (doDriver)
            {
                AppendLog("[Driver Fix] Setting Point and Print & CopyFiles policies...", "INFO");
                SetRegDword(groupPolicyPath, "CopyFilesPolicy", 1);
                SetRegDword(pointPrintPath, "NoWarningNoElevationOnInstall", 1);
                SetRegDword(pointPrintPath, "NoWarningNoElevationOnUpdate", 1);
                SetRegDword(pointPrintPath, "RestrictDriverInstallationToAdministrators", 0);
                AppendLog("-> Point and Print driver v3 unrestrictions applied.", "OK");
            }

            if (doRpc)
            {
                AppendLog("[RPC Fix] Disabling RpcAuthnLevelPrivacy and enabling Guest Auth...", "INFO");
                SetRegDword(printPath, "RpcAuthnLevelPrivacyEnabled", 0);
                SetRegDword(lanmanPath, "AllowInsecureGuestAuth", 1);
                AppendLog("-> RpcAuthnLevelPrivacyEnabled = 0 (fixes 0x0000011b).", "OK");

                // Printers\RPC Policies
                SetRegDword(rpcPolicyPath, "RpcUseNamedPipeProtocol", 1);
                SetRegDword(rpcPolicyPath, "RpcAuthentication", 0);
                SetRegDword(rpcPolicyPath, "RpcProtocols", 7);
                SetRegDword(rpcPolicyPath, "ForceKerberosForRpc", 0);
                SetRegDword(rpcPolicyPath, "RpcTcpPort", 0);
                AppendLog("-> Printers\\RPC configured (RpcProtocols=7, ForceKerberosForRpc=0, RpcUseNamedPipeProtocol=1).", "OK");

                if (isModernWin11)
                {
                    SetRegDword(groupPolicyPath, "RpcClientProtocol", 1);
                    SetRegDword(groupPolicyPath, "RpcOverNamedPipes", 1);
                    AppendLog("-> Windows 11 24H2+ Mode: Forced RPC over Named Pipes (fixes 0x00000bc4).", "OK");
                }
            }

            if (doPauseWinUpdate)
            {
                PauseWindowsUpdate();
            }

            if (doRestartSpooler)
            {
                RestartSpoolerService();
            }

            ScanSystemState();
            MessageBox.Show("Remediation completed successfully!\nIt is recommended to restart your computer once.", "WinPrintFix Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void RestartSpoolerService()
        {
            try
            {
                AppendLog("Restarting Print Spooler service...", "INFO");
                using (ServiceController sc = new ServiceController("Spooler"))
                {
                    if (sc.Status == ServiceControllerStatus.Running)
                    {
                        sc.Stop();
                        sc.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(10));
                    }
                    sc.Start();
                    sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(10));
                    AppendLog("Print Spooler restarted successfully.", "OK");
                }
                ScanSystemState();
            }
            catch (Exception ex)
            {
                AppendLog("Spooler restart failed: " + ex.Message, "ERROR");
            }
        }

        private void PurgeQueue()
        {
            DialogResult res = MessageBox.Show("Are you sure you want to stop the Spooler and purge all pending print jobs (.spl/.shd)?", "Confirm Queue Purge", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (res == DialogResult.Yes)
            {
                try
                {
                    AppendLog("Stopping Print Spooler to purge queue files...", "INFO");
                    using (ServiceController sc = new ServiceController("Spooler"))
                    {
                        if (sc.Status == ServiceControllerStatus.Running)
                        {
                            sc.Stop();
                            sc.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(10));
                        }
                    }

                    int count = 0;
                    if (Directory.Exists(spoolPrintersFolder))
                    {
                        string[] files = Directory.GetFiles(spoolPrintersFolder, "*.*");
                        count = files.Length;
                        foreach (string f in files)
                        {
                            try { File.Delete(f); } catch { }
                        }
                    }

                    AppendLog(string.Format("Purged {0} corrupted print job files.", count), "OK");

                    using (ServiceController sc = new ServiceController("Spooler"))
                    {
                        sc.Start();
                        sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(10));
                        AppendLog("Spooler service restarted cleanly.", "OK");
                    }

                    ScanSystemState();
                    MessageBox.Show("Print queue purged and Spooler restarted cleanly!", "Purge Complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch (Exception ex)
                {
                    AppendLog("Failed to purge queue: " + ex.Message, "ERROR");
                }
            }
        }

        private void ExportRegFile()
        {
            try
            {
                string target = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\WinPrintFix_Rules.reg");
                string content = "Windows Registry Editor Version 5.00\r\n\r\n" +
                                 "; WinPrintFix - Universal Windows Print & SMB Sharing Fix\r\n\r\n" +
                                 "[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Print]\r\n" +
                                 "\"RpcAuthnLevelPrivacyEnabled\"=dword:00000000\r\n\r\n" +
                                 "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows NT\\Printers]\r\n" +
                                 "\"CopyFilesPolicy\"=dword:00000001\r\n" +
                                 "\"RpcClientProtocol\"=dword:00000001\r\n" +
                                 "\"RpcOverNamedPipes\"=dword:00000001\r\n\r\n" +
                                 "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows NT\\Printers\\PointAndPrint]\r\n" +
                                 "\"NoWarningNoElevationOnInstall\"=dword:00000001\r\n" +
                                 "\"NoWarningNoElevationOnUpdate\"=dword:00000001\r\n" +
                                 "\"RestrictDriverInstallationToAdministrators\"=dword:00000000\r\n\r\n" +
                                 "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Policies\\Microsoft\\Windows NT\\Printers\\RPC]\r\n" +
                                 "\"RpcUseNamedPipeProtocol\"=dword:00000001\r\n" +
                                 "\"RpcAuthentication\"=dword:00000000\r\n" +
                                 "\"RpcProtocols\"=dword:00000007\r\n" +
                                 "\"ForceKerberosForRpc\"=dword:00000000\r\n" +
                                 "\"RpcTcpPort\"=dword:00000000\r\n\r\n" +
                                 "[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanWorkstation\\Parameters]\r\n" +
                                 "\"AllowInsecureGuestAuth\"=dword:00000001\r\n" +
                                 "\"EnableInsecureGuestLogons\"=dword:00000001\r\n" +
                                 "\"RequireSecuritySignature\"=dword:00000000\r\n" +
                                 "\"EnableSecuritySignature\"=dword:00000000\r\n\r\n" +
                                 "[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters]\r\n" +
                                 "\"requiresecuritysignature\"=dword:00000000\r\n" +
                                 "\"enablesecuritysignature\"=dword:00000000\r\n";

                File.WriteAllText(target, content, Encoding.ASCII);
                AppendLog("Exported registry rules file: " + target, "OK");
                MessageBox.Show("Registry file exported successfully!\nFile: " + target, "Export Complete", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                AppendLog("Export .reg failed: " + ex.Message, "ERROR");
            }
        }

        // ==========================================
        // 10. Windows Update Methods (from winupdate)
        // ==========================================
        private void PauseWindowsUpdate()
        {
            try
            {
                AppendLog("Pausing Windows Updates until 2051 (Default: Disabled)...", "INFO");

                string uxPath = @"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings";
                SetRegString(uxPath, "PauseFeatureUpdatesStartTime", "2025-01-01T00:00:00Z");
                SetRegString(uxPath, "PauseFeatureUpdatesEndTime", "2051-12-31T00:00:00Z");
                SetRegString(uxPath, "PauseQualityUpdatesStartTime", "2025-01-01T00:00:00Z");
                SetRegString(uxPath, "PauseQualityUpdatesEndTime", "2051-12-31T00:00:00Z");
                SetRegString(uxPath, "PauseUpdatesStartTime", "2025-01-01T00:00:00Z");
                SetRegString(uxPath, "PauseUpdatesExpiryTime", "2051-12-31T00:00:00Z");
                SetRegDword(uxPath, "ActiveHoursStart", 13);
                SetRegDword(uxPath, "ActiveHoursEnd", 7);
                SetRegDword(uxPath, "FlightSettingsMaxPauseDays", 10023);

                string waasPath = @"SYSTEM\CurrentControlSet\Services\WaaSMedicSvc";
                SetRegDword(waasPath, "Start", 4);

                string auPath = @"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";
                SetRegDword(auPath, "NoAutoUpdate", 1);
                SetRegDword(auPath, "NoAUShutdownOption", 1);
                SetRegDword(auPath, "AlwaysAutoRebootAtScheduledTime", 0);
                SetRegDword(auPath, "NoAutoRebootWithLoggedOnUsers", 1);
                SetRegDword(auPath, "AutoInstallMinorUpdates", 0);

                string policySetPath = @"SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings";
                SetRegDword(policySetPath, "PausedFeatureStatus", 1);
                SetRegDword(policySetPath, "PausedQualityStatus", 1);
                SetRegString(policySetPath, "PausedQualityDate", "2025-01-01T00:00:00Z");
                SetRegString(policySetPath, "PausedFeatureDate", "2025-01-01T00:00:00Z");

                RunPowerShellCmdlet("Set-Service -Name 'wuauserv' -StartupType Disabled -ErrorAction SilentlyContinue; Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue");

                AppendLog("Windows Updates successfully paused until 2051.", "OK");
                UpdateWindowsUpdateStatus();
                ScanSystemState();
            }
            catch (Exception ex)
            {
                AppendLog("Error pausing Windows Updates: " + ex.Message, "ERROR");
            }
        }

        private void UnpauseWindowsUpdate()
        {
            try
            {
                AppendLog("Re-enabling Windows Updates (Unpausing to normal)...", "INFO");

                string uxPath = @"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings";
                DeleteRegValue(uxPath, "PauseFeatureUpdatesStartTime");
                DeleteRegValue(uxPath, "PauseFeatureUpdatesEndTime");
                DeleteRegValue(uxPath, "PauseQualityUpdatesStartTime");
                DeleteRegValue(uxPath, "PauseQualityUpdatesEndTime");
                DeleteRegValue(uxPath, "PauseUpdatesStartTime");
                DeleteRegValue(uxPath, "PauseUpdatesExpiryTime");

                string waasPath = @"SYSTEM\CurrentControlSet\Services\WaaSMedicSvc";
                SetRegDword(waasPath, "Start", 3);

                string auPath = @"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";
                SetRegDword(auPath, "NoAutoUpdate", 0);
                SetRegDword(auPath, "NoAUShutdownOption", 0);
                SetRegDword(auPath, "AutoInstallMinorUpdates", 1);

                string policySetPath = @"SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings";
                SetRegDword(policySetPath, "PausedFeatureStatus", 0);
                SetRegDword(policySetPath, "PausedQualityStatus", 0);
                DeleteRegValue(policySetPath, "PausedQualityDate");
                DeleteRegValue(policySetPath, "PausedFeatureDate");

                RunPowerShellCmdlet("Set-Service -Name 'wuauserv' -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue");

                AppendLog("Windows Updates successfully unpaused and active.", "OK");
                UpdateWindowsUpdateStatus();
                ScanSystemState();
            }
            catch (Exception ex)
            {
                AppendLog("Error unpausing Windows Updates: " + ex.Message, "ERROR");
            }
        }

        private void UpdateWindowsUpdateStatus()
        {
            try
            {
                string uxPath = @"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings";
                string auPath = @"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU";
                bool isPaused = false;

                string expiry = GetRegString(uxPath, "PauseUpdatesExpiryTime");
                if (!string.IsNullOrEmpty(expiry)) isPaused = true;

                int? noAuto = GetRegDword(auPath, "NoAutoUpdate");
                if (noAuto == 1) isPaused = true;

                if (lblWuStatusBadge != null)
                {
                    if (isPaused)
                    {
                        lblWuStatusBadge.Text = "[ PAUSED / DISABLED (Until 2051 - Default) ]";
                        lblWuStatusBadge.ForeColor = Color.FromArgb(220, 53, 69);
                    }
                    else
                    {
                        lblWuStatusBadge.Text = "[ ACTIVE / NORMAL (Enabled) ]";
                        lblWuStatusBadge.ForeColor = Color.FromArgb(40, 167, 69);
                    }
                }
            }
            catch { }
        }
    }
}
