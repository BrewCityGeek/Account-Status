# Account Status Checker - Quick Start Guide

**Get up and running in 5 minutes!**

---

## Prerequisites Check

Before you begin, ensure you have:

- ✅ Windows 10/11 or Windows Server 2016+
- ✅ Domain-joined computer
- ✅ Active Directory PowerShell module installed

**Install AD Module** (if needed):
```powershell
# Run as Administrator
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

---

## Installation (Choose One)

### Option A: Use the Executable (Easiest)

1. **Download** `AccountStatusChecker.exe`
2. **Copy** to any folder (e.g., `C:\Tools\`)
3. **Double-click** to run - that's it!

### Option B: Run PowerShell Script

1. **Download** `Account-Status.ps1`
2. **Right-click** → "Run with PowerShell"

If you get an error about execution policy:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## First-Time Use

### 1. Search for a User

![Search Icon](🔍)

- Type a username, first name, last name, or display name
- Press **Enter** or click **Search**
- Select the user from the results

### 2. View Status

The main grid shows:
- ✅ Each domain controller's lockout status
- 📍 DC site location
- 🔢 Bad password count
- 📅 Last bad password time
- 🔒 Last lockout time

### 3. Common Actions

| Task | How To |
|------|--------|
| **Unlock Account** | Click **"Unlock on All DCs"** button |
| **Reset Password** | Right-click any DC → "Reset User Password..." |
| **Refresh Data** | Click **"Refresh"** button |
| **View Basic Info** | Click **"Basic Information"** tab |

---

## Quick Actions Reference

### 🔓 Unlocking an Account

**Fast Method:**
1. Click the **"Unlock on All DCs"** button (appears when account is locked)
2. Click **Yes** to confirm
3. Review results
4. Done! ✓

**Single DC Method:**
1. Right-click on the locked DC
2. Select **"Unlock Account on This DC"**

### 🔑 Resetting a Password

1. Right-click any DC in the grid
2. Select **"Reset User Password..."**
3. Enter new password **twice**
4. Check ☑ **"User must change password at next logon"**
5. Click **OK**

### 🔄 Refreshing Data

- **All DCs**: Click **"Refresh"** button
- **Single DC**: Right-click DC → "Refresh This DC"

### 🚫 Excluding Slow DCs

If a DC consistently times out:
1. Right-click the DC
2. Select **"Exclude DC from Scans"**
3. Click **"Excluded DCs"** tab to view exclusions

To re-include later:
1. Go to **"Excluded DCs"** tab
2. Right-click the DC
3. Select **"Re-include DC in Scans"**

---

## Understanding the Display

### Password Age Colors

Look at the **"Age:"** field in the top-right:

- 🟢 **Green (0-60 days)** = Good, no action needed
- 🟠 **Orange (61-90 days)** = Warning, password aging
- 🔴 **Red (91+ days)** = Critical, password very old

### Grid Column Meanings

| Column | What It Means |
|--------|---------------|
| **Domain Controller** | DC name (PDC marked with "(PDC)") |
| **Site** | AD site location |
| **Locked Out** | Yes/No - Is account locked? |
| **Bad Pwd Count** | Number of recent bad password attempts |
| **Last Bad Password Time** | When was the last wrong password entered? |
| **Last Lockout Time** | When was the account last locked? |

**Special Values:**
- **"Never"** = No bad password attempts recorded
- **"Timeout"** = DC didn't respond (too slow or offline)
- **"Error"** = Query failed (check DC status)

---

## Troubleshooting Lockouts in 3 Steps

### Step 1: Identify the Problem

- Look for **"Yes"** in the **"Locked Out"** column
- Check **"Bad Pwd Count"** - high numbers indicate multiple attempts
- Note the **"Last Bad Password Time"** - this shows when it happened

### Step 2: Find the Source

The DC with the **most recent** "Last Bad Password Time" is receiving the bad password attempts.

**Common sources:**
- 💻 Mapped network drives
- 📱 Mobile devices (phones, tablets)
- ⚙️ Scheduled tasks
- 🖥️ Services running as the user
- 🌐 Web browsers with saved passwords
- 📧 Email clients (Outlook)

### Step 3: Take Action

1. **Unlock the account** using "Unlock on All DCs" button
2. **Reset password** if needed
3. **Find and fix** the source of bad passwords (don't just keep unlocking!)

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **Enter** (in search box) | Search |
| **Enter** (in password dialog) | OK |
| **Esc** | Cancel dialog |

---

## Tips for Success

### ✅ DO:
- **Check all DCs** before concluding the account isn't locked
- **Use "Unlock on All DCs"** to ensure complete unlock
- **Enable "must change password"** when resetting passwords
- **Document** what you find before unlocking
- **Investigate** the source of lockouts

### ❌ DON'T:
- **Don't just unlock repeatedly** - find the source!
- **Don't reset without confirming** with the user
- **Don't ignore high bad password counts** - investigate why
- **Don't exclude DCs permanently** - fix network issues instead

---

## Common Issues & Quick Fixes

### "Active Directory module not found"

**Fix:**
```powershell
# Run as Administrator
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

### Some DCs show "Timeout"

**Fix:**
- Right-click the DC → "Exclude DC from Scans"
- Or wait longer (DCs may be slow)

### Button stays grayed out

**Fix:**
- Wait for all DCs to finish loading
- Click "Refresh" to reload
- Check if account is actually locked

### Can't reset password / unlock account

**Fix:**
- Verify you have Account Operators or Domain Admin rights
- Check that target user isn't in a protected group
- Try again on the PDC specifically

---

## Getting Help

### Built-in Help
- Hover over buttons for tooltips (coming soon)
- Right-click grids to see available actions
- Check the console window (if running script) for detailed logs

### Additional Documentation
- **README.md** - Complete documentation
- **Admin Guide** - Advanced configuration and deployment
- **User Guide** - Detailed end-user instructions

### Support
- Check the full README for comprehensive troubleshooting
- Contact your IT administrator
- Report issues to the tool maintainer

---

## Next Steps

Now that you're up and running:

1. **Bookmark this guide** for quick reference
2. **Try each feature** to get comfortable with the tool
3. **Read the Admin Guide** if you're deploying to multiple users
4. **Check the README** for advanced features and configuration

---

## Version Information

- **Version**: 1.0
- **Last Updated**: October 15, 2025
- **Compatibility**: Windows 10/11, Server 2016+, PowerShell 5.1+

---

**Happy troubleshooting! 🎉**
