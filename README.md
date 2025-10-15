# Account Status Checker

A comprehensive Active Directory account management tool with a user-friendly GUI for monitoring and managing user account status across multiple domain controllers.

![Version](https://img.shields.io/badge/version-1.0-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Features in Detail](#features-in-detail)
- [Configuration](#configuration)
- [Building Executable](#building-executable)
- [Troubleshooting](#troubleshooting)
- [Tips and Best Practices](#tips-and-best-practices)
- [Technical Details](#technical-details)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

**Account Status Checker** is a powerful PowerShell-based tool designed for Active Directory administrators to quickly diagnose and resolve account lockout issues, monitor password status, and manage user accounts across all domain controllers in real-time.

### Key Highlights

- 🚀 **Fast Parallel Queries** - Uses PowerShell runspaces to query up to 20 domain controllers simultaneously
- 🔍 **Real-time Monitoring** - Live updates as DC query results come in
- 🔐 **Account Management** - Reset passwords, unlock accounts, and view detailed status
- 📊 **Comprehensive Reporting** - View account details across all DCs with lockout times, bad password counts, and site information
- 💾 **Persistent Configuration** - Remembers excluded DCs between sessions
- 🎯 **User-Friendly GUI** - Clean Windows Forms interface with intuitive navigation

---

## Features

### Core Functionality

#### **1. User Search**
- Search by username, full name, first name, or last name
- Wildcard matching for flexible searches
- Multiple results displayed in a selection list

#### **2. Domain Controller Status Monitoring**
- **Real-time status updates** from all domain controllers
- **Parallel queries** for fast results (1-20 concurrent threads)
- **Automatic sorting** by DC name
- Display includes:
  - Domain Controller name (with PDC designation)
  - Site information
  - Lockout status (Yes/No)
  - Bad password count
  - Last bad password time
  - Last lockout time
- **Color-coded** error/timeout indicators

#### **3. Password Management**
- **Password Reset** with confirmation dialog
  - Two-field password entry (new + confirm)
  - Password match validation
  - "Must change password at next logon" option
  - Works with any DC in the grid
- **Password Age Monitoring**
  - Last password change date/time
  - Password age in days
  - Color-coded status:
    - 🟢 **Green**: 0-60 days (Good)
    - 🟠 **Orange**: 61-90 days (Warning)
    - 🔴 **Red**: 91+ days (Critical)
  - Visual legend for easy reference

#### **4. Account Unlock Operations**
- **Unlock on Single DC** - Right-click context menu
- **Unlock on All DCs** - One-click button to unlock across entire domain
  - Confirmation dialog
  - Progress indicator
  - Detailed success/failure report for each DC
  - Automatic refresh after operation
  - Includes excluded DCs for comprehensive unlock

#### **5. Domain Controller Management**
- **Exclude DCs** from scans (right-click context menu)
- **Re-include** previously excluded DCs
- **Excluded DCs Tab** - View and manage exclusions
- **Persistent exclusions** - Saved to JSON configuration file
- **Refresh individual DC** - Update status for a specific DC

#### **6. Basic User Information Tab**
- Username (SamAccountName)
- Display Name
- Email Address
- Department
- Title
- Manager
- Office Location
- Phone Number
- Account Status (Enabled/Disabled)
- Last Logon
- Password Last Set
- Password Expiration Date
- Account Creation Date
- Account Locked Out Status
- Group Membership Count
- UPN (User Principal Name)
- Home Directory

#### **7. Configuration Management**
- **File → Settings → Change Config Directory**
- Move configuration file to custom location
- Option to migrate existing config
- Portable configuration support

---

## Screenshots

### Main Interface
```
┌─────────────────────────────────────────────────────────────┐
│ File                                                         │
├─────────────────────────────────────────────────────────────┤
│ Enter Username or Name:                                     │
│ ┌──────────────────┐ [Search] [Refresh] [Unlock on All DCs]│
│ │                  │                                         │
│ └──────────────────┘                                         │
│ ┌────────────────────────────────────────────────────────┐  │
│ │ User List                                              │  │
│ │ • xxxxxxx - John Smith                                 │  │
│ │ • yyyyyy - James Low                                   │  │
│ └────────────────────────────────────────────────────────┘  │
│ Password Age Legend: ■ 0-60 days ■ 61-90 days ■ 91+ days   │
│                                                              │
│ ┌──[Domain Controller Status]─[Basic Info]─[Excluded DCs]─┐│
│ ││ DC Name              │Site  │Locked│BadPwd│LastBadPwd  │││
│ ││ AAAAA-HP-DC1        │RRRR  │No    │0     │2024-07-19  │││
│ ││ BBBB-HP-DC          │BBBB  │No    │0     │Never       │││
│ ││ CCCCC-CP-DC1 (PDC)  │Corp  │No    │0     │2025-10-15  │││
│ └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Software
- **Windows 10/11** or **Windows Server 2016+**
- **PowerShell 5.1** or higher (pre-installed on modern Windows)
- **.NET Framework 4.5+** (pre-installed on Windows 8+)
- **RSAT Active Directory Tools** (see installation below)

### Required Permissions
- **Domain User** account (minimum)
- **Account Operators** or **Domain Admins** (for password reset/unlock operations)
- Network access to domain controllers

### Installing RSAT Active Directory Module

#### **Windows 10/11 (Client)**
```powershell
# Run as Administrator
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

#### **Windows Server**
```powershell
# Run as Administrator
Install-WindowsFeature RSAT-AD-PowerShell
```

#### **Verify Installation**
```powershell
Get-Module -ListAvailable -Name ActiveDirectory
```

---

## Installation

### Option 1: Run as PowerShell Script

1. **Download the script**
   ```powershell
   # Create directory
   New-Item -Path "C:\Scripts\Account-Status" -ItemType Directory -Force
   
   # Copy Account-Status.ps1 to this directory
   ```

2. **Set execution policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the script**
   ```powershell
   cd C:\Scripts\Account-Status
   .\Account-Status.ps1
   ```

### Option 2: Build as Executable (Recommended for End Users)

1. **Install PS2EXE module**
   ```powershell
   Install-Module -Name ps2exe -Scope CurrentUser -Force
   ```

2. **Run the build script**
   ```powershell
   cd C:\Scripts\Account-Status
   .\Build-Executable.ps1
   ```

3. **Result**
   - Creates `AccountStatusChecker.exe` in the same directory
   - No PowerShell console window
   - Can be copied to any location or distributed

4. **Optional: Add custom icon**
   - Place `icon.ico` file in the same directory
   - Rebuild using `Build-Executable.ps1`

---

## Usage

### Basic Workflow

1. **Launch the application**
   - Double-click `AccountStatusChecker.exe` or run `Account-Status.ps1`

2. **Search for a user**
   - Enter username, first name, last name, or display name
   - Press Enter or click **Search**
   - Select user from results list

3. **View account status**
   - **Domain Controller Status** tab shows lockout status across all DCs
   - **Basic Information** tab shows detailed account properties
   - Password information displayed in the top-right

4. **Perform actions**
   - **Right-click** on any DC to access context menu
   - Use **Refresh** button to update current user's information
   - Use **Unlock on All DCs** button when account is locked

### Common Tasks

#### **Troubleshooting Account Lockouts**
1. Search for the locked user
2. View the **Domain Controller Status** tab
3. Look for:
   - "Locked Out" column showing "Yes"
   - High bad password count
   - Recent "Last Bad Password Time"
4. Identify which DC has the most recent bad password attempt
5. This indicates where the bad password is coming from

#### **Unlocking an Account**
**Method 1: Single DC**
1. Right-click on the DC showing lockout
2. Select **"Unlock Account on This DC"**

**Method 2: All DCs (Recommended)**
1. Click **"Unlock on All DCs"** button
2. Confirm the action
3. Review results showing success/failure per DC

#### **Resetting a Password**
1. Right-click any DC in the grid
2. Select **"Reset User Password..."**
3. Enter new password
4. Confirm password
5. Check **"User must change password at next logon"** (recommended)
6. Click **OK**

#### **Excluding Problematic DCs**
1. Right-click on the DC to exclude
2. Select **"Exclude DC from Scans"**
3. Confirm the exclusion
4. DC will be excluded from future scans
5. View excluded DCs in the **"Excluded DCs"** tab

#### **Re-including a DC**
1. Go to **"Excluded DCs"** tab
2. Right-click on the excluded DC
3. Select **"Re-include DC in Scans"**
4. Confirm the action

#### **Refreshing Data**
- Click **Refresh** button to reload all information for current user
- Right-click specific DC and select **"Refresh This DC"** to update just that DC

---

## Features in Detail

### Real-Time Parallel Queries

The application uses PowerShell runspaces to query multiple domain controllers simultaneously:

- **Concurrent Threads**: 1-20 parallel queries
- **Timeout Handling**: 5-second timeout per DC
- **Live Updates**: Results appear in grid as they complete
- **Auto-Sorting**: Results sorted alphabetically after all queries complete

### Smart Button States

Buttons automatically enable/disable based on context:

| Button | Enabled When |
|--------|-------------|
| **Search** | Always enabled |
| **Refresh** | User is loaded |
| **Unlock on All DCs** | User is loaded AND locked out on any DC |

### Password Age Color Coding

Visual indicators help quickly assess password age:

- **🟢 Green (0-60 days)**: Password is fresh, no action needed
- **🟠 Orange (61-90 days)**: Password is aging, consider notification
- **🔴 Red (91+ days)**: Password is old, action recommended

### Context Menus

Right-click context menus provide quick access to common operations:

**DC Status Grid:**
- Reset User Password...
- Unlock Account on This DC
- Refresh This DC
- Exclude DC from Scans

**Excluded DCs Grid:**
- Re-include DC in Scans

### Configuration Persistence

Configuration is automatically saved to `config.json`:

```json
{
  "ExcludedDCs": [
    "STLDP-CP-DC1",
    "OLD-DC-01"
  ],
  "LastUpdated": "2025-10-15 14:30:00"
}
```

**Features:**
- Automatic save on exclude/re-include operations
- Loads automatically on startup
- Can be moved via **File → Settings → Change Config Directory**
- Portable between machines (when using executable)

---

## Configuration

### Default Configuration

By default, the script:
- Creates `config.json` in the same directory as the script/executable
- Includes one default excluded DC: `STLDP-CP-DC1`
- Queries all other domain controllers in the domain

### Changing Configuration Directory

1. Click **File → Settings → Change Config Directory...**
2. Select new folder location
3. Choose whether to:
   - **Move** existing config to new location
   - **Keep** existing config at old location
   - **Cancel** and keep current location

### Manual Configuration Edit

You can manually edit `config.json`:

```json
{
  "ExcludedDCs": [
    "DC1.domain.com",
    "DC2.domain.com",
    "OLD-DC"
  ],
  "LastUpdated": "2025-10-15 14:30:00"
}
```

**Supported Values:**
- Full FQDN: `DC1.contoso.com`
- NetBIOS name: `DC1`
- Partial match: `OLD-*` (will exclude any DC with "OLD-" in the name)

### Environment-Specific Configuration

For multi-environment deployments:

**Option A: User-specific config**
```powershell
# Modify script to use AppData
$appDataPath = [Environment]::GetFolderPath('ApplicationData')
$configDir = Join-Path -Path $appDataPath -ChildPath "AccountStatusChecker"
$script:configPath = Join-Path -Path $configDir -ChildPath "config.json"
```

**Option B: Environment variable**
```powershell
$configDir = $env:ACCT_STATUS_CONFIG ?? $PSScriptRoot
$script:configPath = Join-Path -Path $configDir -ChildPath "config.json"
```

---

## Building Executable

### Using the Included Build Script

The repository includes `Build-Executable.ps1` which automates the build process:

```powershell
# Navigate to script directory
cd C:\Scripts\Account-Status

# Run build script
.\Build-Executable.ps1
```

**Build Output:**
```
Building executable...
Source: C:\Scripts\Account-Status\Account-Status.ps1
Output: C:\Scripts\Account-Status\AccountStatusChecker.exe

Build successful!
Executable created: C:\Scripts\Account-Status\AccountStatusChecker.exe
File size: 2.45 MB

Executable Details:
  Name: AccountStatusChecker.exe
  Created: 10/15/2025 2:30:00 PM
  Path: C:\Scripts\Account-Status\AccountStatusChecker.exe
```

### Build Options

Edit `Build-Executable.ps1` to customize build options:

```powershell
$params = @{
    InputFile = $scriptPath
    OutputFile = $exePath
    NoConsole = $true          # Hide console window (GUI-only)
    NoOutput = $true           # Suppress output messages
    NoError = $true            # Suppress error messages
    RequireAdmin = $false      # Don't require admin rights
    x64 = $true                # Build for 64-bit
    IconFile = $iconPath       # Custom icon (if exists)
    Title = "Account Status Checker"
    Version = "1.0.0.0"
}
```

### Manual Build

To build manually without the script:

```powershell
Import-Module ps2exe

Invoke-ps2exe `
    -InputFile "Account-Status.ps1" `
    -OutputFile "AccountStatusChecker.exe" `
    -NoConsole `
    -x64 `
    -IconFile "icon.ico"
```

### Adding a Custom Icon

1. Create or obtain a `.ico` file (256x256 recommended)
2. Save as `icon.ico` in the same directory
3. Rebuild using `Build-Executable.ps1`
4. The icon will appear in Windows Explorer and taskbar

### Code Signing (Optional)

For enterprise deployments, sign the executable:

```powershell
# Get code signing certificate
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert

# Sign the executable
Set-AuthenticodeSignature -FilePath "AccountStatusChecker.exe" -Certificate $cert

# Verify signature
Get-AuthenticodeSignature "AccountStatusChecker.exe"
```

---

## Troubleshooting

### Common Issues

#### **"Active Directory module not found"**

**Problem:** Script cannot find the ActiveDirectory PowerShell module

**Solution:**
```powershell
# Windows 10/11
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"

# Windows Server
Install-WindowsFeature RSAT-AD-PowerShell
```

#### **"Cannot bind argument to parameter 'Path'"**

**Problem:** Config path is empty (occurs in compiled executable)

**Solution:** This is fixed in the current version. If you encounter it:
1. Delete the old executable
2. Rebuild using the latest `Account-Status.ps1`
3. The script now includes proper path resolution for compiled executables

#### **DCs showing as "Timeout"**

**Problem:** Domain controller not responding within 5 seconds

**Possible Causes:**
- DC is offline or unreachable
- Network latency issues
- Firewall blocking LDAP traffic

**Solutions:**
1. Verify DC is online: `Test-Connection DC-NAME`
2. Check network connectivity
3. Exclude slow DCs if consistently timing out
4. Increase timeout (edit `$timeoutSeconds` in script)

#### **"Never" appearing in timestamp columns**

**Problem:** Bad password time or lockout time showing "Never" when it shouldn't

**Possible Causes:**
- AD property is actually 0 (never set)
- Data type conversion issue
- Replication lag between DCs

**Solutions:**
1. Check the raw AD property: `Get-ADUser username -Properties badPasswordTime -Server DC-NAME`
2. Refresh the individual DC
3. Check if account actually has bad password attempts
4. If error message appears (e.g., "Error converting:"), note the type and value

#### **Executable flagged by antivirus**

**Problem:** PS2EXE executables may be flagged as suspicious

**Solutions:**
1. **Code sign the executable** (recommended for enterprise)
2. **Whitelist** in antivirus software
3. **Submit to vendor** for analysis and whitelisting
4. **Use PowerShell script** instead of executable
5. **Use PowerShell Studio** (commercial alternative to PS2EXE)

#### **"Access Denied" when resetting passwords**

**Problem:** Insufficient permissions to reset passwords

**Solutions:**
1. Verify account has **Account Operators** or **Domain Admins** rights
2. Check if user account being reset is in a protected group
3. Try resetting on PDC specifically
4. Verify permissions: `Get-ADUser -Identity USERNAME -Properties *`

#### **Grid not updating or appearing blank**

**Problem:** DataGridView not displaying results

**Solutions:**
1. Check console output (if running as script)
2. Verify AD module is loaded
3. Try refreshing the data
4. Check for errors in Basic Information tab
5. Restart the application

#### **Button stays disabled**

**Problem:** "Unlock on All DCs" button doesn't enable

**Possible Causes:**
- Account is not actually locked out
- Grid hasn't finished loading
- Logic error in lockout detection

**Solutions:**
1. Wait for all DCs to finish querying
2. Check "Locked Out" column manually
3. Try refreshing the data
4. Close and reopen the application

---

## Tips and Best Practices

### Performance Optimization

1. **Exclude slow DCs** - DCs that consistently timeout should be excluded
2. **Network location matters** - Run from a machine with good DC connectivity
3. **Reduce timeout** for faster scans if all DCs are responsive
4. **Use during off-hours** for best performance

### Security Best Practices

1. **Use "must change at next logon"** when resetting passwords
2. **Document lockout investigations** before unlocking
3. **Check bad password sources** before unlocking repeatedly
4. **Use strong passwords** - The tool doesn't enforce complexity
5. **Limit distribution** of executable to authorized personnel
6. **Code sign** executables in enterprise environments

### Troubleshooting Workflows

#### **Persistent Lockouts**
1. Identify DC with most recent bad password time
2. Check for:
   - Mapped drives with old credentials
   - Scheduled tasks running as the user
   - Services running as the user
   - Mobile devices with cached credentials
   - Browser saved passwords
3. Don't just unlock - find and fix the source!

#### **Inconsistent Status Across DCs**
1. Check replication status between DCs
2. Look at site topology - is there a replication issue?
3. Recent bad password time helps identify which DC is receiving attempts
4. May need to run `repadmin /syncall` or wait for replication

#### **Password Reset Not Working**
1. Verify PDC is online and responsive
2. Check if user is in protected group (cannot change password)
3. Verify password meets domain policy requirements
4. Try resetting on PDC specifically
5. Check Event Logs on DC for detailed error

### Keyboard Shortcuts

- **Enter** in search box → Trigger search
- **ESC** in password dialog → Cancel
- **Enter** in password dialog → OK (if passwords valid)

### Command-Line Options (For Script Mode)

While the GUI doesn't support command-line arguments, you can modify the script for automation:

```powershell
# Example: Export lockout report
$username = "jdoe"
$status = Get-ADUserStatus -Username $username
$status | Export-Csv "C:\Reports\lockout-$username.csv" -NoTypeInformation
```

---

## Technical Details

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Windows Forms GUI                        │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐   │
│  │  Search  │  │  Refresh │  │  Unlock All DCs    │   │
│  └──────────┘  └──────────┘  └────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│            PowerShell Script Engine                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Get-ADUserStatus Function                      │   │
│  │  - Runspace Pool (1-20 threads)                 │   │
│  │  - Parallel DC Queries                          │   │
│  │  - Real-time Grid Updates                       │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Configuration Management                        │   │
│  │  - JSON Serialization                           │   │
│  │  - Persistent Settings                          │   │
│  └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│              Active Directory Module                     │
│  - Get-ADUser                                           │
│  - Get-ADDomainController                               │
│  - Set-ADAccountPassword                                │
│  - Unlock-ADAccount                                     │
├─────────────────────────────────────────────────────────┤
│                 Domain Controllers                       │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐       │
│  │  DC1   │  │  DC2   │  │  DC3   │  │  PDC   │       │
│  └────────┘  └────────┘  └────────┘  └────────┘       │
└─────────────────────────────────────────────────────────┘
```

### Key Technologies

- **PowerShell 5.1** - Core scripting language
- **Windows Forms** - GUI framework
- **System.DirectoryServices** - AD integration
- **System.DirectoryServices.AccountManagement** - User principal management
- **Runspaces** - Parallel execution
- **PS2EXE** - Script to executable conversion

### Performance Metrics

| Metric | Value |
|--------|-------|
| Concurrent DC Queries | 1-20 threads |
| Query Timeout | 5 seconds per DC |
| Average Query Time | 1-3 seconds per DC |
| Typical Scan Time | 5-10 seconds (20 DCs) |
| Memory Usage | ~50-100 MB |
| Executable Size | ~2-3 MB |

### File Structure

```
Account-Status/
├── Account-Status.ps1          # Main script
├── Build-Executable.ps1        # Build automation script
├── config.json                 # Configuration file (auto-created)
├── icon.ico                    # Optional custom icon
├── README.md                   # This file
├── AccountStatusChecker.exe    # Compiled executable (after build)
└── PACKAGING-GUIDE.md         # Distribution guide (optional)
```

### Data Flow

1. **User Search**
   ```
   User Input → Search-ADUser → LDAP Query → Results List → User Selection
   ```

2. **DC Status Query**
   ```
   Username → Get-ADUserStatus → Runspace Pool → Parallel LDAP Queries → Grid Updates → Sort
   ```

3. **Password Reset**
   ```
   User Input → Validation → Set-ADAccountPassword → Set-ADUser (if must change) → Confirmation
   ```

4. **Unlock All DCs**
   ```
   Confirmation → Get All DCs → Parallel Unlock-ADAccount → Results Collection → Report Display → Auto-Refresh
   ```

### Error Handling

The application includes comprehensive error handling:

- **Try-Catch** blocks around all AD operations
- **Timeout handling** for slow/unresponsive DCs
- **Validation** for user inputs
- **GUI error dialogs** for user-facing errors
- **Console logging** for debugging (when run as script)
- **Graceful degradation** when some DCs fail

### Security Considerations

1. **No Credential Storage** - Uses current user's credentials
2. **Secure String** - Passwords converted to SecureString immediately
3. **Audit Trail** - All operations logged to console (script mode)
4. **Minimal Permissions** - Requires only standard AD user read access (unlock/reset require additional rights)
5. **No Network Transmission** - All operations use Windows integrated authentication

---

## Contributing

Contributions are welcome! Please follow these guidelines:

### Reporting Issues

1. Check existing issues first
2. Provide detailed description
3. Include:
   - PowerShell version (`$PSVersionTable`)
   - Windows version
   - Error messages
   - Steps to reproduce

### Suggesting Features

1. Open an issue with `[Feature Request]` prefix
2. Describe the use case
3. Explain expected behavior
4. Consider implementation complexity

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Update documentation
5. Submit PR with clear description

### Development Setup

```powershell
# Clone repository
git clone https://github.com/yourusername/account-status-checker.git

# Open in VS Code
code account-status-checker

# Install PS2EXE for testing
Install-Module -Name ps2exe -Scope CurrentUser

# Test the script
.\Account-Status.ps1

# Build executable for testing
.\Build-Executable.ps1
```

---

## License

MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Changelog

### Version 1.0 (2025-10-15)

**Initial Release**

Features:
- ✅ User search by multiple criteria
- ✅ Real-time DC status monitoring with parallel queries
- ✅ Password reset with confirmation dialog
- ✅ Account unlock (single DC and all DCs)
- ✅ DC exclusion management
- ✅ Password age monitoring with color coding
- ✅ Persistent configuration
- ✅ Basic information tab
- ✅ Site information display
- ✅ Context menus for quick actions
- ✅ Automatic grid sorting
- ✅ Refresh functionality
- ✅ Configurable config directory
- ✅ Executable build support

---

## FAQ

### **Q: Do I need admin rights to run this tool?**
**A:** No, domain user rights are sufficient for viewing status. Account Operators or Domain Admins rights are required for password resets and unlocking accounts.

### **Q: Can I run this from a non-domain-joined machine?**
**A:** No, the machine must be domain-joined and have the Active Directory PowerShell module installed.

### **Q: Why are some DCs showing "Timeout"?**
**A:** The DC didn't respond within 5 seconds. This could be due to network issues, DC being offline, or high load. Consider excluding consistently slow DCs.

### **Q: Does this work with Azure AD / Entra ID?**
**A:** No, this tool is designed for on-premises Active Directory only. It does not support Azure AD / Microsoft Entra ID.

### **Q: Can I customize the timeout value?**
**A:** Yes, edit the script and change `$timeoutSeconds = 5` to your desired value (in the `Get-ADUserStatus` function).

### **Q: Will this work with Read-Only Domain Controllers (RODCs)?**
**A:** Yes for viewing status. No for password resets or unlocks (these operations must be performed on writable DCs).

### **Q: How do I add more user properties to the Basic Information tab?**
**A:** Edit the `Get-ADUserBasicInfo` function and add desired properties to the `$properties` and `$values` arrays.

### **Q: Can I run this against multiple domains?**
**A:** Currently no, it queries the current domain only. You would need to modify the script to support multi-domain environments.

### **Q: Is there a command-line version?**
**A:** The tool is GUI-based, but you can modify the functions to create a command-line wrapper if needed.

### **Q: Why doesn't the executable work on some machines?**
**A:** Ensure:
- .NET Framework 4.5+ is installed
- PowerShell 5.1+ is installed
- Active Directory PowerShell module is installed
- Machine is domain-joined
- User has network access to DCs

### **Q: Can I schedule this to run automatically?**
**A:** The GUI application is interactive and not designed for automation. For scheduled reports, extract the functions and create a separate reporting script.

---

## Support

For issues, questions, or suggestions:

- **GitHub Issues**: https://github.com/BrewCityGeek/account-status/issues
- **Email**: your.email@domain.com
- **Internal Wiki**: (for enterprise deployments)

---

## Acknowledgments

- PowerShell Community for best practices and patterns
- PS2EXE project for script-to-executable conversion
- Active Directory team for comprehensive PowerShell module

---

**Last Updated**: October 15, 2025  
**Author**: Andy Gossen
**Version**: 25.10.15
