# WinPrintFix: Windows Print Spooler, Network Sharing & System Optimizer (Pro Suite)

> **Universal desktop utility (GUI WinForms) to resolve Windows network printer sharing errors (`0x0000011b`, `0x00000709`, `0x00000bc4`, `0x80070035`) and control Windows Update policies across Windows 10 and Windows 11 (including 24H2, 25H2, and 26H2+).**

---

## 🇹🇭 คู่มือการใช้งานภาษาไทย (Thai User Guide)

### 📌 ภาพรวมและสาเหตุของปัญหาการแชร์ปริ้นเตอร์ใน Windows ยุคใหม่
การแชร์ปริ้นเตอร์ผ่านระบบวงแลน (Workgroup / Local Network) ใน Windows 10 และ Windows 11 (โดยเฉพาะเวอร์ชัน 24H2, 25H2 และ 26H2+) มักจะล้มเหลวเนื่องจากระบบความปลอดภัยที่ Microsoft ปรับปรุงใหม่หลายชั้น:

1. **PrintNightmare RPC Encryption (`0x0000011b`)**: Windows บังคับการเข้ารหัส RPC ระดับสูง ทำให้เครื่องลูกที่ไม่มีระบบ Domain หรือสิทธิ์ตรงกันเชื่อมต่อไม่ได้
2. **Point and Print Driver v3 Restriction (`0x00000709`, "No driver found")**: Windows ไม่อนุญาตให้ผู้ใช้ทั่วไปดึงไดรเวอร์เครื่องพิมพ์ Type 3 (v3) จากเครื่องแม่ข่ายข้ามเครือข่าย
3. **SMB Guest Logons & Mandatory Signing (`0x80070035`, Access Denied)**: ตั้งแต่ Windows 11 24H2 ระบบจะบังคับ SMB Signing และปิดการเข้าใช้งานแบบ Guest ทำให้ไม่สามารถเข้าถึงแชร์โฟลเดอร์หรือแชร์ปริ้นเตอร์ได้
4. **RPC Transport Protocol Mismatch (`0x00000bc4`)**: Windows 11 24H2+ พยายามค้นหาปริ้นเตอร์ผ่าน RPC over TCP เป็นค่าเริ่มต้น หากเครื่องแม่ฟังผ่าน Named Pipes เครื่องลูกจะมองไม่เห็น
5. **Network Profile ถูกเปลี่ยนเป็น Public**: การอัปเดต Windows มักจะรีเซ็ตการ์ดแลน/ไวไฟกลับเป็นแบบ "Public" ซึ่งบล็อกพอร์ตการแชร์ไฟล์และเครื่องพิมพ์ทั้งหมด (TCP 445, 139, Spooler RPC)
6. **Network Discovery ปิดอยู่**: บริการ `FDResPub` ถูกปิดไว้ ทำให้เครื่องในวงแลนมองไม่เห็นกันใน File Explorer Network
7. **Windows Update แทรกแซง**: Windows Update มักจะแอบคืนค่า Registry ของระบบความปลอดภัยกลับมา ทำให้แชร์ปริ้นเตอร์หลุดซ้ำซาก

**WinPrintFix (Pro Suite v1.1.0)** รวมการแก้ไขทั้งหมดไว้ในโปรแกรมหน้าต่างเดียว ใช้งานง่ายและปลอดภัย

---

### 🚀 ฟังก์ชันหลักทั้ง 5 แท็บ

* **แท็บ 1: Universal Fix & Scanner (สแกนและแก้ไขแบบครอบจักรวาล)**:
  - ตารางวิเคราะห์สถานะระบบแบบ Real-time พร้อมแถบสี (`[OK]` สีเขียว / `[FIX NEEDED]` สีส้ม)
  - กล่องเลือกโมดูลแก้ไข (SMB, Driver v3 GPO, RPC Named Pipes, Spooler, Windows Update)
  - ปุ่ม **`>>> APPLY ALL RECOMMENDED FIXES (ULTIMATE) <<<`**: คลิกเดียวแก้ไขปัญหาแชร์ปริ้นเตอร์ทั้งหมด
  - ระบบสำรองค่าอัตโนมัติ (Safety Snapshot) และปุ่มกู้คืนค่าเดิม (Rollback)
* **แท็บ 2: Network & Firewall (จัดการเครือข่ายและไฟร์วอลล์)**:
  - ปุ่มสลับสถานะการ์ดเครือข่ายที่ใช้งานอยู่ให้เป็น **Private** ทันที
  - ปุ่มเปิดกฎไฟร์วอลล์ Windows Defender สำหรับกลุ่ม *File and Printer Sharing*
  - ปุ่มตั้งค่าและเริ่มบริการ Network Discovery (`FDResPub`, `fdPHost`) ให้อัตโนมัติ
* **แท็บ 3: Driver v3 Helper (แก้ปัญหาไดรเวอร์รุ่นเก่าด้วย Local Port)**:
  - ช่วยสร้าง Local Port ชี้ตรงไปยัง `\\HostIP\ShareName` ข้ามขั้นตอนการดึงไดรเวอร์ผ่าน Point & Print สำหรับปริ้นเตอร์รุ่นเก่าที่ไม่มีไดรเวอร์ v4
  - ปุ่มลัดเปิด *Devices and Printers* และ *Print Management*
* **แท็บ 4: Spooler & Export (จัดการบริการคิวพิมพ์และส่งออก Registry)**:
  - สั่ง Restart, Start หรือ Stop บริการ Print Spooler ได้โดยตรง
  - **Deep Purge**: สั่งล้างคิวงานพิมพ์ที่ค้าง ลบไฟล์ขยะ `.spl` และ `.shd` ในโฟลเดอร์ระบบและรีสตาร์ต Spooler ใหม่อย่างสะอาด
  - ส่งออกไฟล์ Registry รวมกฎทั้งหมดเป็น `WinPrintFix_Rules.reg` สำหรับนำไปติดตั้งเครื่องอื่นแบบออฟไลน์
* **แท็บ 5: Windows Update (ปิด-เปิดการอัปเดต Windows - ค่าเริ่มต้น: ปิด)**:
  - ตรวจสอบสถานะการอัปเดตของเครื่องสด
  - ปุ่ม **`[ PAUSE WINDOWS UPDATE UNTIL 2051 (DEFAULT: DISABLED) ]`**: ปิดและหยุดการอัปเดตอัตโนมัติยาวจนถึงปี 2051 พร้อมปิด Service `wuauserv` และ `WaaSMedicSvc` ป้องกันไม่ให้ Windows อัปเดตมารีเซ็ตค่าแชร์ปริ้นเตอร์
  - ปุ่ม **`[ UNPAUSE & RESTORE NORMAL WINDOWS UPDATE ]`**: คืนค่าการอัปเดตกลับมาเป็นปกติได้ทุกเมื่อใน 1 คลิก
  - ปุ่มเปิดหน้าต่าง Windows Update Settings ของระบบ

---

### 📖 วิธีการเปิดใช้งาน

1. **เปิดด้วยไฟล์โปรแกรม `.exe` (แนะนำที่สุด)**:
   - เข้าไปที่โฟลเดอร์ `bin/` แล้วดับเบิลคลิกไฟล์ [`bin/WinPrintFix.exe`](file:///C:/Ai_code/WinPrintFix/bin/WinPrintFix.exe)
   - กด **Yes** ยืนยันสิทธิ์ Administrator (UAC)
   - ในแท็บแรก กดปุ่มสีเขียว **`>>> APPLY ALL RECOMMENDED FIXES (ULTIMATE) <<<`**
   - รีสตาร์ตคอมพิวเตอร์ 1 ครั้งเพื่อใช้งาน
2. **เปิดด้วย PowerShell Script**:
   - ดับเบิลคลิกไฟล์ [`WinPrintFix.bat`](file:///C:/Ai_code/WinPrintFix/WinPrintFix.bat) หรือคลิกขวาที่ [`src/WinPrintFix.ps1`](file:///C:/Ai_code/WinPrintFix/src/WinPrintFix.ps1) แล้วเลือก *Run with PowerShell*
3. **ติดตั้งแบบรวดเร็วด้วยไฟล์ Registry (.reg)**:
   - ดับเบิลคลิกไฟล์ [`WinPrintFix_Rules.reg`](file:///C:/Ai_code/WinPrintFix/WinPrintFix_Rules.reg) แล้วกดตอบ Yes เพื่อ Import ค่าลงระบบทันที

---

## 📌 Executive Summary & Root Causes (English)

Sharing printers in peer-to-peer (Workgroup) local networks on modern Windows machines often fails due to multiple overlapping security mitigations introduced by Microsoft:

1. **PrintNightmare RPC Encryption (`0x0000011b`)**:
   - Spooler requires strict RPC privacy authentication levels (`RpcAuthnLevelPrivacyEnabled`). Peer machines lacking matching credentials or domain trust fail with access denied.
2. **Point and Print Driver v3 Restriction (`0x00000709`, "No driver found")**:
   - Modern Windows blocks non-administrators from pulling Type 3 (v3) printer drivers across the network, hanging during the driver download stage.
3. **Windows 11 24H2+ SMB Hardening (`0x80070035`, Access Denied)**:
   - Starting with 24H2, Windows mandates **SMB Signing** on both client and server and blocks **Insecure Guest Logons** by default, cutting off unauthenticated share access.
4. **RPC Transport Protocol Shift (`0x00000bc4`)**:
   - Windows 11 24H2+ client machines default to RPC over TCP. If the print server only listens on Named Pipes, discovery fails.
5. **Network Profile & Firewall Dormancy**:
   - Windows Update frequently resets the active network adapter from `Private` to `Public`, automatically blocking ports 445, 139, and Spooler RPC.
6. **Network Discovery Inactivity**:
   - `FDResPub` (Function Discovery Resource Publication) is disabled by default, hiding the printer host PC in File Explorer.
7. **Windows Update Interference**:
   - Automatic background updates frequently overwrite or reset Spooler RPC registry parameters and SMB policies, re-breaking network sharing.

**WinPrintFix (Pro Suite v1.1.0)** resolves all of these issues in one unified, high-DPI GUI utility.

---

## 🚀 Key Features (Pro Suite v1.1.0)

* **⚡ Universal 1-Click Fix (Ultimate Mode)**:
  - Applies all required SMB, Point and Print GPO, and RPC Named Pipes remediations matching [`FixPrint.txt`](file:///C:/Ai_code/WinPrintFix/FixPrint.txt).
* **🔍 Real-Time Diagnostic Scanner**:
  - Live table scanning current registry values, SMB signing, network profiles, Windows Update AU policy, and Spooler service status with color-coded status badges (`[OK]` Green / `[FIX NEEDED]` Amber).
* **🌐 Network Profile & Firewall Automator**:
  - 1-click button to switch active network adapters to `Private` and open the Windows Defender Firewall rules for *File and Printer Sharing*.
* **📡 Network Discovery Enabler**:
  - Automatically sets `FDResPub` and `fdPHost` services to `Automatic` and starts them so PCs appear in the network browser.
* **🖨️ Driver v3 Local Port Wizard**:
  - Interactive assistant to create a Local Port (`\\HostIP\ShareName`), completely bypassing Point & Print driver download restrictions for older printers.
* **🛑 Tab 5: Windows Update Controller (Default: Paused/Disabled)**:
  - Comprehensive registry-based update management.
  - **Default: Disabled** — Pauses Quality & Feature updates until **2051**, sets `NoAutoUpdate = 1`, and disables `WaaSMedicSvc` & `wuauserv` to protect print configurations.
  - 1-click **Unpause & Restore** button to re-enable normal Windows Updates whenever needed.
* **🔠 Enhanced Typography & Layout**:
  - Enlarged Segoe UI typography (9.5pt base, 12.5pt bold headers) and spacious 940 x 910 window for comfortable reading on high-resolution displays.
* **🧹 Deep Spooler Queue Cleaner**:
  - Forcibly stops the Spooler, wipes corrupt `.spl` and `.shd` files from `C:\Windows\System32\spool\PRINTERS`, and restarts the service cleanly.
* **💾 Safety Snapshot & 1-Click Rollback**:
  - Automatically creates a JSON snapshot in `backups/print_backup_<timestamp>.json` before any modification, allowing full state restoration.
* **📦 Offline `.reg` File Generator**:
  - Exports all exact registry keys to `WinPrintFix_Rules.reg` for instant deployment via GPO or USB drive.

---

## 🏗️ Architecture & Dual Implementation

WinPrintFix provides two complementary implementations:

| Variant | Executable / File | Description |
| :--- | :--- | :--- |
| **Standalone C# Binary** | [`bin/WinPrintFix.exe`](file:///C:/Ai_code/WinPrintFix/bin/WinPrintFix.exe) | Portable 52.5 KB executable compiled with native Windows `csc.exe` (.NET 4.8), zero third-party dependencies, high-DPI aware, embedded UAC administrator manifest. |
| **Pure PowerShell Script** | [`src/WinPrintFix.ps1`](file:///C:/Ai_code/WinPrintFix/src/WinPrintFix.ps1) | Native WinForms script that runs directly in PowerShell 5.1 / 7+ without prior compilation. |
| **Batch Launcher** | [`WinPrintFix.bat`](file:///C:/Ai_code/WinPrintFix/WinPrintFix.bat) | Convenient double-click launcher for `src/WinPrintFix.ps1` with automated UAC self-elevation. |

---

## 📋 Registry & Policy Reference Matrix

| Registry Path / Cmdlet | Value Name | Recommended Target | Default / Rollback | Error / Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `HKLM:\SYSTEM\CurrentControlSet\Control\Print` | `RpcAuthnLevelPrivacyEnabled` | `0` (DWORD) | `1` (or delete) | `0x0000011b` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers` | `CopyFilesPolicy` | `1` (DWORD) | `0` (or delete) | Driver v3 Block |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers` | `RpcClientProtocol` | `1` (DWORD) | `0` (or delete) | `0x00000bc4` |
| `HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers` | `RpcOverNamedPipes` | `1` (DWORD) | `0` (or delete) | `0x00000bc4` |
| `HKLM:\SOFTWARE\Policies\...\Printers\RPC` | `ForceKerberosForRpc` | `0` (DWORD) | `1` (or delete) | Workgroup NTLM fallback |
| `HKLM:\SOFTWARE\Policies\...\Printers\RPC` | `RpcProtocols` | `7` (DWORD) | `0` (or delete) | RPC Listener Bitmask (Named Pipes + TCP + Local) |
| `HKLM:\SOFTWARE\Policies\...\Printers\RPC` | `RpcUseNamedPipeProtocol` | `1` (DWORD) | `0` (or delete) | Named Pipes RPC Policy |
| `HKLM:\SOFTWARE\Policies\...\Printers\RPC` | `RpcAuthentication` | `0` (DWORD) | `1` (or delete) | RPC Authentication Level |
| `HKLM:\SOFTWARE\Policies\...\Printers\RPC` | `RpcTcpPort` | `0` (DWORD) | `0` (or delete) | Dynamic Port Allocation |
| `HKLM:\SOFTWARE\Policies\...\PointAndPrint` | `NoWarningNoElevationOnInstall` | `1` (DWORD) | `0` (or delete) | UAC Prompt on Install |
| `HKLM:\SOFTWARE\Policies\...\PointAndPrint` | `NoWarningNoElevationOnUpdate` | `1` (DWORD) | `0` (or delete) | UAC Prompt on Update |
| `HKLM:\SOFTWARE\Policies\...\PointAndPrint` | `RestrictDriverInstallationToAdministrators` | `0` (DWORD) | `1` (DWORD) | `0x00000709` |
| `HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters` | `AllowInsecureGuestAuth` | `1` (DWORD) | `0` (DWORD) | `0x80070035` / Access Denied |
| `Set-SmbClientConfiguration` | `EnableInsecureGuestLogons` | `$true` | `$false` | Anonymous Guest Access |
| `Set-SmbClientConfiguration` | `RequireSecuritySignature` | `$false` | `$true` | SMB Signing Incompatibility |
| `Set-SmbServerConfiguration` | `RequireSecuritySignature` | `$false` | `$true` | Server SMB Signing Overhead |
| `HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` | `PauseUpdatesExpiryTime` | `"2051-12-31T00:00:00Z"` | Deleted | Windows Update Pause |
| `HKLM:\SOFTWARE\Policies\...\WindowsUpdate\AU` | `NoAutoUpdate` | `1` (DWORD) | `0` (DWORD) | Disable Auto-Update |

---

## 🛠️ Usage Instructions (English)

### Method 1: Launch Standalone Executable (Recommended)
1. Navigate to `bin/` and double-click [`WinPrintFix.exe`](file:///C:/Ai_code/WinPrintFix/bin/WinPrintFix.exe).
2. Accept the Windows UAC elevation prompt.
3. Review the diagnostic scan and click **`>>> APPLY ALL RECOMMENDED FIXES (ULTIMATE) <<<`**.
4. Check Tab 5 (*Windows Update*) to verify updates are paused until 2051.
5. Restart the computer once.

### Method 2: Launch via PowerShell Script
1. Double-click [`WinPrintFix.bat`](file:///C:/Ai_code/WinPrintFix/WinPrintFix.bat) or right-click [`src/WinPrintFix.ps1`](file:///C:/Ai_code/WinPrintFix/src/WinPrintFix.ps1) -> *Run with PowerShell*.
2. Accept the UAC elevation prompt.
3. The WinForms interface will launch immediately.

### Method 3: Instant Registry Import (.reg file)
For unattended mass deployment or fast offline setups:
1. Double-click [`WinPrintFix_Rules.reg`](file:///C:/Ai_code/WinPrintFix/WinPrintFix_Rules.reg) and confirm the registry import prompt.
2. Restart the Print Spooler service or restart your computer.

### Rebuilding from Source
To deterministically compile `WinPrintFix.exe` using native Windows tools:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```


