# Account Status Checker - Administrator Guide

**Complete guide for IT administrators deploying and managing the Account Status Checker tool**

---

## Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Deployment Planning](#deployment-planning)
- [Installation Methods](#installation-methods)
- [Configuration Management](#configuration-management)
- [Group Policy Deployment](#group-policy-deployment)
- [Security & Permissions](#security--permissions)
- [Performance Tuning](#performance-tuning)
- [Monitoring & Auditing](#monitoring--auditing)
- [Troubleshooting](#troubleshooting)
- [Advanced Customization](#advanced-customization)
- [Maintenance](#maintenance)

---

## Overview

### Purpose

The Account Status Checker is designed to help IT administrators quickly diagnose and resolve Active Directory account lockout issues across multiple domain controllers. This guide covers enterprise deployment, configuration, and management.

### Key Administrative Features

- **Centralized Configuration** - JSON-based config for easy management
- **DC Exclusion Management** - Persistent exclusion lists
- **Portable Deployment** - Runs from any location (UNC paths supported)
- **No Admin Rights Required** - Standard domain user permissions for viewing
- **Audit Trail** - Console logging for tracking operations
- **Customizable** - Open source PowerShell script

---

## System Requirements

### Client Requirements

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **Operating System** | Windows 10/11, Server 2016+ | Any edition |
| **PowerShell** | 5.1 or higher | Pre-installed on modern Windows |
| **.NET Framework** | 4.5 or higher | Pre-installed on Windows 8+ |
| **RSAT Tools** | Active Directory module | Must be installed |
| **Memory** | 100 MB available | Typical usage |
| **Disk Space** | 10 MB | For executable + config |
| **Network** | Domain connectivity | Access to all DCs |

### Active Directory Requirements

- **Domain Functional Level**: Windows Server 2008 or higher
- **Forest Functional Level**: Windows Server 2008 or higher
- **LDAP Access**: Client must reach all DCs on port 389 (LDAP)
- **Replication**: Healthy AD replication recommended

### User Permissions

| Operation | Required Permission |
|-----------|---------------------|
| View Status | Domain Users (read access) |
| Reset Password | Account Operators or Domain Admins |
| Unlock Account | Account Operators or Domain Admins |
| Exclude DCs | Any user (local config only) |

---

## Deployment Planning

### Deployment Scenarios

#### **Scenario 1: IT Help Desk Deployment**

**Target Users**: 5-50 help desk technicians

**Recommended Approach**:
- Deploy executable via Group Policy
- Centralized config on network share
- Create dedicated service account with Account Operators rights
- Enable audit logging
- Provide training materials

**Benefits**: Centralized management, consistent configuration

#### **Scenario 2: System Administrator Toolkit**

**Target Users**: 5-20 system administrators

**Recommended Approach**:
- Place in admin tools folder
- Individual config files
- Use existing admin credentials
- Keep as PowerShell script for customization

**Benefits**: Maximum flexibility, easy to modify

#### **Scenario 3: Enterprise Self-Service**

**Target Users**: 100+ users (delegated permissions)

**Recommended Approach**:
- Deploy via SCCM or Intune
- Locked-down executable
- Mandatory DC exclusions (slow/remote DCs)
- Limited to unlock operations only (remove password reset)
- Comprehensive monitoring

**Benefits**: Reduces help desk load, empowers users

### Deployment Checklist

- [ ] Identify target user group
- [ ] Verify RSAT AD module on all client machines
- [ ] Test on pilot group
- [ ] Create standardized config file
- [ ] Document deployment procedure
- [ ] Prepare training materials
- [ ] Set up monitoring/auditing (if required)
- [ ] Create support documentation
- [ ] Plan rollback procedure
- [ ] Schedule deployment window

---

## Installation Methods

### Method 1: Manual Installation

**Best for**: Small deployments, pilot testing

```powershell
# Create directory
New-Item -Path "C:\Tools\AccountStatus" -ItemType Directory -Force

# Copy files
Copy-Item "\\fileserver\share\AccountStatusChecker.exe" "C:\Tools\AccountStatus\"
Copy-Item "\\fileserver\share\config.json" "C:\Tools\AccountStatus\"

# Create desktop shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:Public\Desktop\Account Status Checker.lnk")
$Shortcut.TargetPath = "C:\Tools\AccountStatus\AccountStatusChecker.exe"
$Shortcut.Save()
```

### Method 2: Group Policy Deployment

**Best for**: Medium to large deployments, centralized management

#### Step 1: Prepare Distribution Point

```powershell
# Create network share
New-Item -Path "\\fileserver\Software\AccountStatusChecker" -ItemType Directory
New-SmbShare -Name "AccountStatusChecker" -Path "\\fileserver\Software\AccountStatusChecker" -ReadAccess "Domain Users"

# Copy files
Copy-Item ".\AccountStatusChecker.exe" "\\fileserver\Software\AccountStatusChecker\"
Copy-Item ".\config.json" "\\fileserver\Software\AccountStatusChecker\"
```

#### Step 2: Create Installation Script

Create `Install-AccountStatusChecker.ps1`:

```powershell
# Installation script for Account Status Checker
$installPath = "C:\Program Files\AccountStatusChecker"
$sourcePath = "\\fileserver\Software\AccountStatusChecker"

# Create directory
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory -Force | Out-Null
}

# Copy executable
Copy-Item "$sourcePath\AccountStatusChecker.exe" $installPath -Force

# Copy config if doesn't exist
if (-not (Test-Path "$installPath\config.json")) {
    Copy-Item "$sourcePath\config.json" $installPath -Force
}

# Create start menu shortcut
$WshShell = New-Object -ComObject WScript.Shell
$startMenu = [Environment]::GetFolderPath('CommonPrograms')
$Shortcut = $WshShell.CreateShortcut("$startMenu\Account Status Checker.lnk")
$Shortcut.TargetPath = "$installPath\AccountStatusChecker.exe"
$Shortcut.Description = "Check AD account status and troubleshoot lockouts"
$Shortcut.Save()

# Log installation
Add-Content "C:\Windows\Temp\AccountStatusChecker-Install.log" "$(Get-Date) - Installed to $installPath"
```

#### Step 3: Create GPO

1. **Open Group Policy Management**
2. **Create new GPO**: "Deploy Account Status Checker"
3. **Link to target OU** (e.g., IT Staff)
4. **Configure**:
   - Computer Configuration → Policies → Windows Settings → Scripts → Startup
   - Add: `\\fileserver\Software\AccountStatusChecker\Install-AccountStatusChecker.ps1`
   - Run as: PowerShell script
5. **Update clients**: `gpupdate /force`

### Method 3: SCCM/Intune Deployment

**Best for**: Large enterprise deployments

#### SCCM Package Creation

```powershell
# Create package directory structure
New-Item -Path "\\sccm\packages\AccountStatusChecker\1.0" -ItemType Directory -Force

# Copy files
Copy-Item ".\AccountStatusChecker.exe" "\\sccm\packages\AccountStatusChecker\1.0\"
Copy-Item ".\config.json" "\\sccm\packages\AccountStatusChecker\1.0\"

# Create install script
$installScript = @'
# SCCM Installation Script
$appPath = "C:\Program Files\AccountStatusChecker"
New-Item -Path $appPath -ItemType Directory -Force
Copy-Item "$PSScriptRoot\AccountStatusChecker.exe" $appPath -Force
Copy-Item "$PSScriptRoot\config.json" $appPath -Force
exit 0
'@
$installScript | Out-File "\\sccm\packages\AccountStatusChecker\1.0\Install.ps1" -Encoding UTF8

# Create uninstall script
$uninstallScript = @'
Remove-Item "C:\Program Files\AccountStatusChecker" -Recurse -Force -ErrorAction SilentlyContinue
exit 0
'@
$uninstallScript | Out-File "\\sccm\packages\AccountStatusChecker\1.0\Uninstall.ps1" -Encoding UTF8
```

**SCCM Application Configuration**:
- **Install command**: `powershell.exe -ExecutionPolicy Bypass -File Install.ps1`
- **Uninstall command**: `powershell.exe -ExecutionPolicy Bypass -File Uninstall.ps1`
- **Detection method**: File exists - `C:\Program Files\AccountStatusChecker\AccountStatusChecker.exe`

#### Intune Win32 App

```powershell
# Create .intunewin package
.\IntuneWinAppUtil.exe `
    -c ".\AccountStatusChecker" `
    -s "AccountStatusChecker.exe" `
    -o ".\Output"

# Upload to Intune and configure:
# Install command: powershell.exe -ExecutionPolicy Bypass -File Install.ps1
# Uninstall command: powershell.exe -ExecutionPolicy Bypass -File Uninstall.ps1
# Detection rule: File - C:\Program Files\AccountStatusChecker\AccountStatusChecker.exe
```

### Method 4: Network Share Deployment

**Best for**: Quick deployment, no installation required

```powershell
# Create shared location
New-Item -Path "\\fileserver\Tools\AccountStatusChecker" -ItemType Directory
New-SmbShare -Name "AccountStatusChecker" -Path "\\fileserver\Tools\AccountStatusChecker" -ReadAccess "Domain Users"

# Copy files
Copy-Item ".\AccountStatusChecker.exe" "\\fileserver\Tools\AccountStatusChecker\"
Copy-Item ".\config.json" "\\fileserver\Tools\AccountStatusChecker\"

# Users can run directly from: \\fileserver\Tools\AccountStatusChecker\AccountStatusChecker.exe
```

**Advantages**:
- ✅ No client installation required
- ✅ Instant updates (replace file on share)
- ✅ Centralized configuration
- ✅ Easy to manage

**Disadvantages**:
- ❌ Requires network connectivity
- ❌ Slower startup over network
- ❌ Each user loads a copy into memory

---

## Configuration Management

### Default Configuration

The tool creates `config.json` automatically on first run:

```json
{
  "ExcludedDCs": [
    "STLDP-CP-DC1"
  ],
  "LastUpdated": "2025-10-15 14:30:00"
}
```

### Centralized Configuration

For enterprise deployments, use a centralized config:

#### Option A: Modify Script for Centralized Config

Edit `Account-Status.ps1` before building:

```powershell
# Replace the configuration path section with:
$script:configPath = "\\fileserver\IT\AccountStatusChecker\config.json"
```

#### Option B: Use Environment Variable

```powershell
# Set via Group Policy or logon script
[Environment]::SetEnvironmentVariable("ACCT_STATUS_CONFIG", "\\fileserver\IT\AccountStatusChecker", "Machine")

# Modify script to use:
$configDir = $env:ACCT_STATUS_CONFIG ?? $PSScriptRoot
$script:configPath = Join-Path -Path $configDir -ChildPath "config.json"
```

#### Option C: Registry-Based Configuration

```powershell
# Set via Group Policy Preferences or script
New-Item -Path "HKLM:\SOFTWARE\AccountStatusChecker" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\AccountStatusChecker" -Name "ConfigPath" -Value "\\fileserver\IT\config.json" -Force

# Modify script to read:
$regPath = "HKLM:\SOFTWARE\AccountStatusChecker"
if (Test-Path $regPath) {
    $configFromReg = Get-ItemProperty -Path $regPath -Name "ConfigPath" -ErrorAction SilentlyContinue
    if ($configFromReg) {
        $script:configPath = $configFromReg.ConfigPath
    }
}
```

### Configuration Best Practices

#### Exclude Slow/Remote DCs

```json
{
  "ExcludedDCs": [
    "REMOTE-DC-01",
    "BRANCH-DC-*",
    "OLD-DC-2008",
    "SLOW-DC"
  ],
  "LastUpdated": "2025-10-15 14:30:00"
}
```

**Reasons to exclude**:
- Remote sites with slow WAN links
- Decommissioned DCs still in AD
- RODCs (Read-Only Domain Controllers)
- Test/lab DCs
- DCs undergoing maintenance

#### Monitoring Configuration Changes

Create a file watcher script:

```powershell
# Monitor-ConfigChanges.ps1
$configPath = "\\fileserver\IT\AccountStatusChecker\config.json"
$previousHash = $null

while ($true) {
    if (Test-Path $configPath) {
        $currentHash = (Get-FileHash $configPath -Algorithm SHA256).Hash
        
        if ($previousHash -and $currentHash -ne $previousHash) {
            # Config changed - notify
            $config = Get-Content $configPath | ConvertFrom-Json
            $message = "Config changed at $(Get-Date)`nExcluded DCs: $($config.ExcludedDCs -join ', ')"
            
            # Log to event viewer
            Write-EventLog -LogName Application -Source "AccountStatusChecker" -EventId 1001 -Message $message
            
            # Send email (optional)
            # Send-MailMessage -To "it-admins@company.com" -Subject "Account Status Checker Config Changed" -Body $message
        }
        
        $previousHash = $currentHash
    }
    
    Start-Sleep -Seconds 300  # Check every 5 minutes
}
```

### Deploying Configuration Updates

```powershell
# Update-Config.ps1 - Push config to all clients

$newConfig = @{
    ExcludedDCs = @(
        "REMOTE-DC-01",
        "BRANCH-DC-WEST",
        "OLD-DC-2008"
    )
    LastUpdated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

# Save to central location
$newConfig | ConvertTo-Json | Set-Content "\\fileserver\IT\AccountStatusChecker\config.json"

# If using local configs, push to all client machines
$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows 10*"} -SearchBase "OU=IT,DC=contoso,DC=com"

foreach ($computer in $computers) {
    $destPath = "\\$($computer.Name)\C$\Program Files\AccountStatusChecker\config.json"
    if (Test-Path (Split-Path $destPath -Parent)) {
        $newConfig | ConvertTo-Json | Set-Content $destPath -Force
        Write-Host "Updated config on $($computer.Name)" -ForegroundColor Green
    }
}
```

---

## Group Policy Deployment

### Method 1: Software Installation Policy

1. **Create MSI Installer** (using tools like WiX or Advanced Installer)
2. **Configure GPO**:
   ```
   Computer Configuration → Policies → Software Settings → Software Installation
   → New → Package → Select MSI
   ```
3. **Deployment Type**: Assigned
4. **Installation Options**: Basic
5. **Link GPO** to target OU

### Method 2: Startup Script Deployment

See [Installation Methods → Method 2](#method-2-group-policy-deployment) above

### Method 3: Scheduled Task Deployment

Deploy via GPO with scheduled task that ensures latest version:

```xml
<!-- Save as AccountStatusChecker-Update.xml -->
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "\\fileserver\IT\Scripts\Update-AccountStatusChecker.ps1"</Arguments>
    </Exec>
  </Actions>
  <Settings>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
  </Settings>
</Task>
```

Deploy via GPO:
```
Computer Configuration → Preferences → Control Panel Settings → Scheduled Tasks
→ New → Scheduled Task → Import XML
```

---

## Security & Permissions

### Principle of Least Privilege

#### Read-Only Deployment

For users who should only **view** status (no unlock/reset):

Modify the script to disable certain features:

```powershell
# Add at the top of the script
$script:ReadOnlyMode = $true

# Modify menu handlers to check:
$menuResetPassword.Add_Click({
    if ($script:ReadOnlyMode) {
        [System.Windows.Forms.MessageBox]::Show("Password reset is disabled in read-only mode.", "Access Denied")
        return
    }
    # ... rest of code
})

$menuUnlockAccount.Add_Click({
    if ($script:ReadOnlyMode) {
        [System.Windows.Forms.MessageBox]::Show("Account unlock is disabled in read-only mode.", "Access Denied")
        return
    }
    # ... rest of code
})

$unlockAllButton.Visible = -not $script:ReadOnlyMode
```

#### Delegated Permissions Model

Create specific groups with limited permissions:

```powershell
# Create dedicated groups
New-ADGroup -Name "AccountStatus-Viewers" -GroupScope DomainLocal -GroupCategory Security
New-ADGroup -Name "AccountStatus-Unlockers" -GroupScope DomainLocal -GroupCategory Security
New-ADGroup -Name "AccountStatus-FullAccess" -GroupScope DomainLocal -GroupCategory Security

# Delegate unlock permissions
# (Manual via AD Users and Computers delegation wizard or dsacls)

# Viewers: Domain Users (default read access)
# Unlockers: Delegate "Unlock Account" permission
# FullAccess: Add to Account Operators group
```

### Audit Logging

Enable enhanced logging by modifying the script:

```powershell
# Add logging function
function Write-AuditLog {
    param(
        [string]$Action,
        [string]$TargetUser,
        [string]$Details
    )
    
    $logPath = "\\fileserver\Logs\AccountStatusChecker"
    $logFile = Join-Path $logPath "$(Get-Date -Format 'yyyy-MM').log"
    
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $env:USERNAME | $env:COMPUTERNAME | $Action | $TargetUser | $Details"
    Add-Content -Path $logFile -Value $logEntry
    
    # Also write to Event Log
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists("AccountStatusChecker")) {
            New-EventLog -LogName Application -Source "AccountStatusChecker"
        }
        Write-EventLog -LogName Application -Source "AccountStatusChecker" -EventId 1000 -EntryType Information -Message $logEntry
    } catch {
        # Silent fail if can't write to event log
    }
}

# Add to password reset handler:
Write-AuditLog -Action "PasswordReset" -TargetUser $script:selectedUsername -Details "Password reset by $env:USERNAME"

# Add to unlock handlers:
Write-AuditLog -Action "AccountUnlock" -TargetUser $script:selectedUsername -Details "Unlocked on $dcName by $env:USERNAME"
```

### Code Signing

For enterprise security, sign the executable:

```powershell
# Get code signing certificate
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1

# Sign the executable
Set-AuthenticodeSignature -FilePath ".\AccountStatusChecker.exe" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"

# Verify signature
Get-AuthenticodeSignature ".\AccountStatusChecker.exe"
```

Deploy signature requirement via GPO:
```
Computer Configuration → Policies → Windows Settings → Security Settings → Software Restriction Policies
→ Additional Rules → New Certificate Rule → Select certificate
```

### Protecting Configuration Files

Set proper NTFS permissions on config files:

```powershell
# Centralized config - read-only for users
$configPath = "\\fileserver\IT\AccountStatusChecker"
$acl = Get-Acl $configPath

# Remove inheritance
$acl.SetAccessRuleProtection($true, $false)

# Add explicit permissions
$readRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain Users", "Read", "Allow")
$fullRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain Admins", "FullControl", "Allow")

$acl.SetAccessRule($readRule)
$acl.SetAccessRule($fullRule)

Set-Acl -Path $configPath -AclObject $acl
```

---

## Performance Tuning

### Adjusting Query Timeout

Default is 5 seconds. Adjust based on environment:

```powershell
# In Get-ADUserStatus function, modify:
$timeoutSeconds = 10  # Increase for slow networks
$timeoutSeconds = 3   # Decrease for fast, local DCs
```

### Runspace Pool Size

Default: 1-20 concurrent threads. Adjust based on:
- Number of DCs
- Network bandwidth
- Client machine resources

```powershell
# In Get-ADUserStatus function, modify:
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 30)  # More threads
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)  # Fewer threads
```

**Recommendations**:
- **Small environments (< 10 DCs)**: 10 threads
- **Medium environments (10-30 DCs)**: 20 threads
- **Large environments (> 30 DCs)**: 30 threads

### Network Optimization

Ensure efficient connectivity:

```powershell
# Test DC connectivity before deployment
$dcs = (Get-ADDomain).ReplicaDirectoryServers
foreach ($dc in $dcs) {
    $result = Test-NetConnection -ComputerName $dc -Port 389 -InformationLevel Quiet
    if (-not $result) {
        Write-Warning "$dc is not reachable on port 389 (LDAP)"
    }
}

# Test query performance
Measure-Command {
    Get-ADUser -Identity "testuser" -Server $dc -Properties *
}
```

---

## Monitoring & Auditing

### Event Log Monitoring

Create event log source:

```powershell
# Run as Administrator on each client
New-EventLog -LogName Application -Source "AccountStatusChecker"
```

Monitor for events:

```powershell
# Monitor-EventLogs.ps1
$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows 10*"} -SearchBase "OU=IT,DC=contoso,DC=com"

foreach ($computer in $computers) {
    $events = Get-WinEvent -ComputerName $computer.Name -FilterHashtable @{
        LogName = 'Application'
        ProviderName = 'AccountStatusChecker'
        StartTime = (Get-Date).AddHours(-24)
    } -ErrorAction SilentlyContinue
    
    foreach ($event in $events) {
        [PSCustomObject]@{
            Computer = $computer.Name
            Time = $event.TimeCreated
            EventID = $event.Id
            Message = $event.Message
        }
    }
}
```

### Usage Analytics

Track usage patterns:

```powershell
# Add to script
$metricsPath = "\\fileserver\IT\Metrics\AccountStatusChecker"
$metricsFile = Join-Path $metricsPath "usage-$(Get-Date -Format 'yyyy-MM').csv"

function Write-Metric {
    param($Action)
    
    if (-not (Test-Path $metricsPath)) {
        New-Item -Path $metricsPath -ItemType Directory -Force
    }
    
    [PSCustomObject]@{
        Timestamp = Get-Date
        User = $env:USERNAME
        Computer = $env:COMPUTERNAME
        Action = $Action
    } | Export-Csv $metricsFile -Append -NoTypeInformation
}

# Call at various points:
Write-Metric -Action "AppLaunched"
Write-Metric -Action "UserSearched"
Write-Metric -Action "PasswordReset"
Write-Metric -Action "AccountUnlocked"
```

Generate monthly reports:

```powershell
# Generate-UsageReport.ps1
$metrics = Import-Csv "\\fileserver\IT\Metrics\AccountStatusChecker\usage-2025-10.csv"

$summary = $metrics | Group-Object Action | Select-Object Name, Count | Sort-Object Count -Descending

$summary | Format-Table -AutoSize

# Top users
$metrics | Group-Object User | Sort-Object Count -Descending | Select-Object -First 10
```

---

## Troubleshooting

### Deployment Issues

#### Script Execution Policy

**Problem**: "Execution of scripts is disabled"

**Solution**: Set via GPO
```
Computer Configuration → Policies → Windows Settings → Security Settings → PowerShell → Turn on Script Execution
→ Set to "Allow local scripts and remote signed scripts"
```

#### RSAT Module Missing

**Problem**: "ActiveDirectory module not found"

**Solution**: Deploy via GPO
```powershell
# Create installation script
$script = @'
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
'@

# Deploy via GPO startup script
```

Or via SCCM/Intune as prerequisite

#### Network Path Issues

**Problem**: UNC paths not resolving

**Solutions**:
- Verify DNS is working
- Check firewall rules
- Test with IP address
- Use DFS namespace for redundancy

### Performance Issues

#### Slow Startup

**Causes**:
- Running from network share
- Large number of DCs
- Slow network

**Solutions**:
- Install locally instead of network share
- Exclude slow/remote DCs
- Increase timeout threshold
- Reduce runspace pool size

#### High Memory Usage

**Causes**:
- Many concurrent queries
- Memory leak in runspaces

**Solutions**:
- Reduce runspace pool size
- Close and reopen application periodically
- Monitor with: `Get-Process | Where-Object {$_.ProcessName -eq "AccountStatusChecker"}`

### Functional Issues

#### Inconsistent Results

**Causes**:
- Replication lag between DCs
- Timing issues

**Solutions**:
- Check AD replication health: `repadmin /replsummary`
- Wait and refresh
- Focus on PDC results
- Increase query timeout

#### Can't Unlock/Reset Password

**Causes**:
- Insufficient permissions
- Target user in protected group
- Network connectivity to DC

**Solutions**:
- Verify group membership: `Get-ADGroupMember "Account Operators"`
- Check if user is in "Protected Users" group
- Try on PDC specifically
- Check DC accessibility

---

## Advanced Customization

### Adding Custom Columns

To add additional data to the grid:

```powershell
# In Get-ADUserStatus function, modify the scriptblock to retrieve:
$user = Get-ADUser -Identity $username -Server $dcName -Properties *

# Add to return hashtable:
return @{
    Success = $true
    DCName = $dcName
    DCSite = $dcSite
    IsPDC = $isPDC
    IsLockedOut = $isLockedOut
    BadPwdCount = $badPwdCount
    BadPwdTime = $badPwdTime
    LockoutTime = $lockoutTime
    LastLogon = if ($user.LastLogonDate) { $user.LastLogonDate.ToString('yyyy-MM-dd HH:mm:ss') } else { 'Never' }  # NEW
    PasswordAge = if ($user.PasswordLastSet) { ((Get-Date) - $user.PasswordLastSet).Days } else { 'N/A' }  # NEW
}

# Add columns to grid:
$statusGrid.Columns.Add("LastLogon", "Last Logon")
$statusGrid.Columns.Add("PasswordAge", "Pwd Age (Days)")

# Update grid callback to populate:
$row.Cells[6].Value = $statusItem.LastLogon
$row.Cells[7].Value = $statusItem.PasswordAge
```

### Customizing Default Exclusions

Set organization-specific defaults:

```powershell
# Modify in script:
} else {
    # Default exclusion list if no config exists
    $script:excludedDCs = @(
        'OLD-DC-2008',
        'REMOTE-BRANCH-DC',
        'TEST-DC',
        'RODC-*'
    )
}
```

### Branding

Add company branding:

```powershell
# Modify form title
$form.Text = "Contoso Account Status Checker v1.0"

# Add company logo (requires converting image to base64)
$logoImage = [System.Drawing.Image]::FromFile("C:\path\to\logo.png")
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Image = $logoImage
$pictureBox.Location = New-Object System.Drawing.Point(750,10)
$pictureBox.Size = New-Object System.Drawing.Size(100,50)
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$form.Controls.Add($pictureBox)
```

### Email Notifications

Add email alerts for certain actions:

```powershell
function Send-AdminAlert {
    param(
        [string]$Action,
        [string]$TargetUser,
        [string]$PerformedBy
    )
    
    $mailParams = @{
        To = "it-admins@contoso.com"
        From = "accountstatus@contoso.com"
        Subject = "Account Status Action: $Action on $TargetUser"
        Body = "Action: $Action`nTarget User: $TargetUser`nPerformed By: $PerformedBy`nTime: $(Get-Date)"
        SmtpServer = "smtp.contoso.com"
    }
    
    Send-MailMessage @mailParams
}

# Add to critical operations:
Set-ADAccountPassword -Identity $script:selectedUsername -NewPassword $securePassword -Reset
Send-AdminAlert -Action "PasswordReset" -TargetUser $script:selectedUsername -PerformedBy $env:USERNAME
```

---

## Maintenance

### Version Management

Track versions in the script:

```powershell
# Add at top of script
$script:Version = "1.0.0"
$script:BuildDate = "2025-10-15"

# Display in form title
$form.Text = "Account Status Checker v$($script:Version)"

# Add to About menu
$aboutMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenu.Text = "About"
$aboutMenu.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        "Account Status Checker`nVersion: $($script:Version)`nBuild Date: $($script:BuildDate)",
        "About",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})
$fileMenu.DropDownItems.Add($aboutMenu)
```

### Update Deployment

#### Method 1: Automatic Update Check

```powershell
# Add at startup
function Check-ForUpdates {
    try {
        $latestVersion = Get-Content "\\fileserver\IT\AccountStatusChecker\version.txt"
        if ($latestVersion -ne $script:Version) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "A new version ($latestVersion) is available. Would you like to update?",
                "Update Available",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Download and replace executable
                $updatePath = "\\fileserver\IT\AccountStatusChecker\AccountStatusChecker.exe"
                $localPath = $MyInvocation.MyCommand.Definition
                Copy-Item $updatePath $localPath -Force
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Update downloaded. Please restart the application.",
                    "Update Complete",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                
                exit
            }
        }
    } catch {
        # Silent fail - don't block app if update check fails
    }
}

Check-ForUpdates
```

#### Method 2: Scheduled Update Task

```powershell
# Create scheduled task to update
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -File "\\fileserver\IT\Scripts\Update-AccountStatusChecker.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
$principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Limited

Register-ScheduledTask -TaskName "Update Account Status Checker" -Action $action -Trigger $trigger -Principal $principal
```

### Backup and Recovery

Backup configuration:

```powershell
# Backup-AccountStatusConfig.ps1
$backupPath = "\\fileserver\Backups\AccountStatusChecker"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

if (-not (Test-Path $backupPath)) {
    New-Item -Path $backupPath -ItemType Directory -Force
}

# Backup central config
Copy-Item "\\fileserver\IT\AccountStatusChecker\config.json" "$backupPath\config_$timestamp.json"

# Backup script
Copy-Item "\\fileserver\IT\AccountStatusChecker\Account-Status.ps1" "$backupPath\Account-Status_$timestamp.ps1"

# Keep only last 30 days of backups
Get-ChildItem $backupPath | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force
```

### Health Monitoring

Monitor tool health:

```powershell
# HealthCheck-AccountStatusChecker.ps1
$healthReport = @()

# Check if file share is accessible
$shareAccessible = Test-Path "\\fileserver\IT\AccountStatusChecker"
$healthReport += [PSCustomObject]@{
    Check = "File Share Accessible"
    Status = if ($shareAccessible) { "OK" } else { "FAILED" }
}

# Check if config is valid
try {
    $config = Get-Content "\\fileserver\IT\AccountStatusChecker\config.json" | ConvertFrom-Json
    $configValid = $true
} catch {
    $configValid = $false
}
$healthReport += [PSCustomObject]@{
    Check = "Config File Valid"
    Status = if ($configValid) { "OK" } else { "FAILED" }
}

# Check if DCs are accessible
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$dcCount = ($domain.DomainControllers).Count
$reachableCount = 0
foreach ($dc in $domain.DomainControllers) {
    if (Test-NetConnection -ComputerName $dc.Name -Port 389 -InformationLevel Quiet) {
        $reachableCount++
    }
}
$healthReport += [PSCustomObject]@{
    Check = "DCs Reachable"
    Status = "$reachableCount of $dcCount DCs accessible"
}

$healthReport | Format-Table -AutoSize

# Alert if issues found
$issues = $healthReport | Where-Object {$_.Status -like "*FAILED*"}
if ($issues) {
    Send-MailMessage -To "it-admins@contoso.com" -From "monitoring@contoso.com" -Subject "Account Status Checker Health Issues" -Body ($issues | Out-String) -SmtpServer "smtp.contoso.com"
}
```

---

## Appendix

### Sample Deployment Package

Complete deployment package structure:

```
AccountStatusChecker-Deployment/
│
├── AccountStatusChecker.exe          # Main executable
├── Account-Status.ps1                # Source script (for reference)
├── config.json                       # Default configuration
├── icon.ico                          # Application icon
│
├── Documentation/
│   ├── README.md                     # Complete documentation
│   ├── QUICKSTART.md                 # Quick start guide
│   ├── ADMIN-GUIDE.md               # This document
│   └── USER-GUIDE.md                # End-user guide
│
├── Scripts/
│   ├── Install-AccountStatusChecker.ps1       # Installation script
│   ├── Uninstall-AccountStatusChecker.ps1     # Uninstallation script
│   ├── Update-AccountStatusChecker.ps1        # Update script
│   ├── Deploy-ViaGPO.ps1                      # GPO deployment helper
│   └── HealthCheck-AccountStatusChecker.ps1   # Health monitoring
│
└── GPO/
    ├── AccountStatusChecker-Install.xml       # Scheduled task XML
    └── README-GPO.txt                         # GPO deployment instructions
```

### Useful PowerShell Commands

```powershell
# Check AD module installation
Get-Module -ListAvailable -Name ActiveDirectory

# Test DC connectivity
Test-NetConnection -ComputerName DC01 -Port 389

# List all DCs
(Get-ADDomain).ReplicaDirectoryServers

# Check replication status
repadmin /replsummary

# View account lockout status
Get-ADUser -Identity username -Properties LockedOut, badPwdCount, badPasswordTime, lockoutTime

# Check who has Account Operators rights
Get-ADGroupMember "Account Operators"

# View app event logs
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='AccountStatusChecker'}

# Test LDAP query performance
Measure-Command { Get-ADUser -Identity testuser -Server DC01 -Properties * }
```

### Support Resources

- **Script Repository**: [Internal GitLab/GitHub]
- **Issue Tracking**: [Internal ticket system]
- **Knowledge Base**: [Internal wiki]
- **Training Videos**: [Internal training portal]
- **Support Email**: it-support@company.com

---

**Document Version**: 1.0  
**Last Updated**: October 15, 2025  
**Author**: IT Administration Team  
**Review Date**: January 15, 2026
