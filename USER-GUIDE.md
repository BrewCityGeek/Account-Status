# Account Status Checker - User Guide

**A step-by-step guide for help desk staff and end users**

---

## Table of Contents

- [Welcome](#welcome)
- [What This Tool Does](#what-this-tool-does)
- [Getting Started](#getting-started)
- [Understanding the Interface](#understanding-the-interface)
- [Common Tasks](#common-tasks)
- [Troubleshooting Scenarios](#troubleshooting-scenarios)
- [Understanding Results](#understanding-results)
- [Best Practices](#best-practices)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Getting Help](#getting-help)

---

## Welcome

Welcome to the Account Status Checker! This tool helps you quickly diagnose and fix Active Directory account problems, especially account lockouts. This guide will walk you through everything you need to know.

### Who Should Use This Tool?

- ✅ **Help Desk Technicians** - First-line support troubleshooting user account issues
- ✅ **System Administrators** - IT staff managing Active Directory
- ✅ **Delegated Administrators** - Users with Account Operators permissions
- ✅ **End Users** (if given permission) - Users checking their own account status

### What You'll Learn

By the end of this guide, you'll know how to:
- Search for user accounts
- Identify if an account is locked out
- Unlock accounts across all domain controllers
- Reset passwords securely
- Understand password age indicators
- Troubleshoot common account problems

---

## What This Tool Does

### The Problem It Solves

When users can't log in, it's often because:
- Their account is **locked out** after too many wrong password attempts
- They're trying to use an **old/expired password**
- Their password needs to be changed
- There's a **replication delay** between domain controllers

The Account Status Checker shows you the **real-time status** of an account on **every domain controller**, so you can quickly identify and fix the problem.

### Key Features

| Feature | What It Does |
|---------|-------------|
| **Multi-DC Status** | Checks all domain controllers at once for lockouts |
| **Color-Coded Passwords** | Shows password age at a glance (green=new, yellow=aging, red=old) |
| **Quick Unlock** | Unlock accounts on one DC or all DCs with one click |
| **Password Reset** | Reset passwords with confirmation and force-change option |
| **Refresh** | Re-check account status after making changes |
| **DC Exclusions** | Hide slow or problematic domain controllers |

---

## Getting Started

### Opening the Application

#### Method 1: Desktop Shortcut
1. **Double-click** the "Account Status Checker" icon on your desktop
2. The application opens immediately (no login required)

#### Method 2: Start Menu
1. Click the **Start** button
2. Type `Account Status` in the search bar
3. Click **Account Status Checker**

#### Method 3: Network Share (if deployed centrally)
1. Open File Explorer
2. Navigate to `\\fileserver\Tools\AccountStatusChecker`
3. Double-click `AccountStatusChecker.exe`

### First Launch

When you first open the tool:
- The search box is **empty**
- The grid is **blank** (no results yet)
- The **Refresh** button is **disabled** (until you search)
- All other buttons are **disabled** (until you select a result)

**You're ready to go!** No configuration needed for basic use.

---

## Understanding the Interface

### Main Window Layout

```
┌─────────────────────────────────────────────────────────────┐
│ File                                                         │  ← Menu Bar
├─────────────────────────────────────────────────────────────┤
│ Username: [____________]  [Search] [Refresh]                │  ← Search Area
├─────────────────────────────────────────────────────────────┤
│ ┌───────────────────────────────────────────────────────┐  │
│ │ Domain Controller │ Site │ PDC │ Locked Out │ ...     │  │  ← Results Grid
│ │ DC01              │ Main │  ✓  │ Yes        │ ...     │  │
│ │ DC02              │ Main │     │ No         │ ...     │  │
│ │ DC03              │ Branch│    │ No         │ ...     │  │
│ └───────────────────────────────────────────────────────┘  │
│ [Unlock on Selected DC] [Unlock on All DCs] [Reset Pwd]    │  ← Action Buttons
└─────────────────────────────────────────────────────────────┘
```

### Input Fields

#### Username Search Box
- **Where**: Top of window
- **What**: Enter the username you want to check
- **Accepts**: 
  - `jsmith` (just username)
  - `DOMAIN\jsmith` (with domain)
  - `jsmith@company.com` (email format)
- **Tips**: 
  - No need to include domain prefix (it's added automatically)
  - Not case-sensitive
  - Press **Enter** to search immediately

### Buttons

| Button | When Enabled | What It Does |
|--------|-------------|--------------|
| **Search** | Always | Searches for the entered username across all domain controllers |
| **Refresh** | After first search | Re-checks the account status (useful after unlocking/resetting) |
| **Unlock on Selected DC** | When a locked row is selected | Unlocks the account on just that one domain controller |
| **Unlock on All DCs** | When any lock detected | Unlocks the account on **every** domain controller at once |
| **Reset Password** | When a row is selected | Opens password reset dialog with confirmation |

### Results Grid

The grid shows one row per domain controller:

| Column | Meaning | Example |
|--------|---------|---------|
| **Domain Controller** | Server name | `DC01` |
| **Site** | AD site location | `Main-Office` |
| **PDC** | Is this the Primary DC? | `✓` (Yes) or blank (No) |
| **Locked Out** | Is account locked here? | `Yes` / `No` |
| **Bad Pwd Count** | Wrong password attempts | `0` to `5` |
| **Last Bad Pwd** | When last wrong password entered | `2025-10-15 14:32:18` or `Never` |
| **Lockout Time** | When account was locked | `2025-10-15 14:32:45` or `Never` |
| **Pwd Age** | How old is the password? | `45 days` (color-coded) |

### Color Coding

#### Password Age Colors

The **Pwd Age** column uses colors to show password health:

- 🟢 **Green (0-90 days)** - Password is fresh and acceptable
- 🟡 **Yellow (91-180 days)** - Password is aging, might need change soon
- 🔴 **Red (181+ days)** - Password is very old, likely needs changing

*Note: These ranges are typical defaults. Your organization may have different policies.*

#### Row Highlighting

Some systems highlight entire rows:
- **Red background** - Account is locked out on this DC
- **Bold text** - This is the PDC (Primary Domain Controller)

*Exact highlighting depends on your deployment configuration.*

### Right-Click Context Menu

**Right-click on any domain controller name** to access:

| Menu Item | What It Does |
|-----------|--------------|
| **Exclude this DC** | Hides this DC from future searches (removes from grid) |
| **Unlock on This DC** | Unlocks account on this specific DC |
| **Copy DC Name** | Copies the DC name to clipboard |

### Menu Bar

#### File Menu

- **Settings** - Opens configuration dialog to:
  - Change where config files are stored
  - View excluded DCs list
- **Exit** - Closes the application

---

## Common Tasks

### Task 1: Checking If an Account Is Locked Out

**When to use**: User reports "Account is locked out" error when logging in

**Steps**:

1. **Launch** Account Status Checker
2. **Type** the username in the search box (e.g., `jsmith`)
3. **Click** the **Search** button (or press **Enter**)
4. **Wait** 5-10 seconds while the tool checks all domain controllers
5. **Review** the results grid

**What to look for**:
- ✅ **"Locked Out" column shows "Yes"** → Account IS locked
- ✅ **"Bad Pwd Count" > 0** → Wrong passwords were attempted
- ✅ **"Lockout Time" shows a recent date** → When the lockout happened
- ❌ **All show "No"** → Account is NOT locked (problem is something else)

**Example Result**:

```
Domain Controller | PDC | Locked Out | Bad Pwd Count | Lockout Time
DC01              | ✓   | Yes        | 5             | 2025-10-15 14:30:22
DC02              |     | No         | 0             | Never
DC03              |     | No         | 0             | Never
```

**Interpretation**: Account is locked on DC01 (the PDC), but not yet replicated to DC02/DC03.

---

### Task 2: Unlocking an Account (Single DC)

**When to use**: Account is locked on one specific domain controller

**Steps**:

1. **Search** for the account (see Task 1)
2. **Find** the row where "Locked Out" = "Yes"
3. **Click** on that row to select it (row turns blue/highlighted)
4. **Click** the **"Unlock on Selected DC"** button
5. **Wait** for confirmation message: *"Account unlocked successfully on DC01"*
6. **Click** **OK**
7. **Click** **Refresh** to verify the lock is gone

**Tips**:
- You can also **right-click** the DC name and choose "Unlock on This DC"
- If you get an error, you may not have permission (see [Troubleshooting](#troubleshooting-scenarios))

---

### Task 3: Unlocking an Account (All DCs)

**When to use**: Account is locked on multiple DCs, or you want to be thorough

**Steps**:

1. **Search** for the account
2. **Verify** at least one DC shows "Locked Out" = "Yes"
3. **Click** the **"Unlock on All DCs"** button (red text, bottom right)
4. **Read** the confirmation message:
   - *"This will attempt to unlock the account on ALL domain controllers, including excluded ones. Continue?"*
5. **Click** **Yes** to proceed
6. **Wait** 10-20 seconds while unlocking on all DCs
7. **Review** the results dialog:

   ```
   Unlock Results:
   
   Successful:
   ✓ DC01 - Account unlocked successfully
   ✓ DC02 - Account unlocked successfully
   ✓ DC03 - Account unlocked successfully
   
   Failed: None
   
   The grid will now refresh automatically.
   ```

8. **Click** **OK**
9. The grid **refreshes automatically** - verify "Locked Out" now shows "No" on all DCs

**When to prefer this over single DC unlock**:
- User is trying to log in from multiple locations
- You want to ensure immediate resolution
- Replication between DCs is slow
- You're not sure which DC the user will authenticate against

---

### Task 4: Resetting a Password

**When to use**: 
- User forgot their password
- User account compromised (security incident)
- Need to force password change at next logon

**Steps**:

1. **Search** for the account
2. **Click** on any row in the grid to select the account
3. **Click** the **"Reset Password"** button
4. A dialog box appears with two password fields:

   ```
   ┌─────────────────────────────────────┐
   │ Reset Password for: jsmith         │
   ├─────────────────────────────────────┤
   │ New Password:     [_____________]  │
   │ Confirm Password: [_____________]  │
   │                                     │
   │ ☑ User must change password at      │
   │   next logon                        │
   │                                     │
   │        [OK]      [Cancel]           │
   └─────────────────────────────────────┘
   ```

5. **Type** the new password in the "New Password" field
   - Password appears as dots (`••••••••`) for security
   - Follow your organization's password requirements (e.g., 8+ characters, uppercase, numbers, symbols)

6. **Type** the same password again in "Confirm Password"

7. **(Optional)** Check the box **"User must change password at next logon"** if:
   - ✅ You want the user to create their own password after logging in
   - ✅ This is a temporary password
   - ✅ Company policy requires it
   - ❌ Leave unchecked if you want the password to remain permanent

8. **Click** **OK**

9. If passwords match:
   - ✅ Success message appears: *"Password has been reset for user jsmith"*
   - Give the new password to the user securely (phone call, encrypted message, in person)

10. If passwords DON'T match:
    - ❌ Error message: *"Passwords do not match. Please try again."*
    - Click **OK** and re-enter both passwords carefully

**Important Security Notes**:
- 🔒 **Never** send passwords via email or instant message (unless encrypted)
- 🔒 **Always** verify you're speaking with the actual user (check caller ID, ask verification questions)
- 🔒 **Document** password resets in your ticket system
- 🔒 **Enable** "must change at next logon" for shared/temporary passwords

---

### Task 5: Excluding a Domain Controller

**When to use**: 
- A DC is very slow and times out frequently
- A DC is being decommissioned
- A DC is in a remote site you don't support
- A DC causes errors every time you search

**Steps**:

1. **Search** for any account (to populate the grid)
2. **Find** the DC you want to exclude in the grid
3. **Right-click** on the Domain Controller name
4. **Click** **"Exclude this DC"**
5. A confirmation dialog appears:
   - *"Are you sure you want to exclude DC02 from future queries? This setting will be saved."*
6. **Click** **Yes**
7. The row disappears from the grid immediately
8. **Future searches** will automatically skip this DC

**How to undo**:
- Click **File** → **Settings**
- View the "Excluded DCs" list
- Remove the DC from the config file
- (Currently requires manual edit - future versions may add a "Remove Exclusion" button)

**Note**: Exclusions are saved in `config.json` and persist even after closing the application.

---

### Task 6: Refreshing Results

**When to use**:
- After unlocking an account (to verify it worked)
- After resetting a password
- When waiting for changes to replicate between DCs
- To check current status without re-typing the username

**Steps**:

1. Make sure you've already searched for an account (grid has results)
2. **Click** the **Refresh** button
3. **Wait** 5-10 seconds for the query to complete
4. The grid updates with current information

**Tip**: The Refresh button is disabled until after your first search. This prevents accidental clicks when no username is entered.

---

## Troubleshooting Scenarios

### Scenario 1: User Can't Log In - "Account Locked Out" Error

**User reports**: *"I can't log in. It says my account is locked out."*

**Your response**:

1. **Search** for the user's account
2. **Check** the "Locked Out" column
3. **If "Yes"** on any DC:
   - Click **"Unlock on All DCs"**
   - Tell user: *"I've unlocked your account. Please try logging in again."*
4. **If "No"** on all DCs:
   - Check "Pwd Age" column - is it red (180+ days)?
   - Likely password is expired or incorrect
   - Tell user: *"Your account isn't locked. Let's reset your password."*
   - Click **"Reset Password"** and follow [Task 4](#task-4-resetting-a-password)

**Escalate if**:
- Account keeps locking repeatedly (every few minutes)
- Account shows as locked, but unlock fails
- User still can't log in after unlock and password reset

---

### Scenario 2: Account Keeps Locking Out

**User reports**: *"I unlocked my account, but it locked again 5 minutes later!"*

**Your response**:

This usually means:
- ❌ User has a **saved password** somewhere that's typing the wrong password automatically
- ❌ **Mobile device** or **cached credential** is retrying with old password

**Troubleshooting steps**:

1. **Unlock** the account using **"Unlock on All DCs"**
2. **Ask user**:
   - "Do you have any devices that auto-connect to company resources?" (phone, tablet, laptop)
   - "Did you recently change your password?"
   - "Do you have any mapped network drives or saved credentials?"

3. **Common culprits**:
   - 📱 **Mobile phone** - Outlook app, email sync, company app with saved login
     - *Solution*: Have user update password in device settings
   - 💻 **Saved credentials** - Windows Credential Manager
     - *Solution*: Tell user to open Control Panel → Credential Manager → Remove old credentials
   - 🗂️ **Mapped network drives** - Drives mapped with explicit credentials
     - *Solution*: Disconnect and reconnect drives with new password
   - 🖥️ **Scheduled tasks** - Tasks running with user's credentials
     - *Solution*: Update task credentials (requires admin)
   - ⏰ **Active sessions** - User logged in on another computer
     - *Solution*: Have user log out of all sessions

4. **Watch the "Last Bad Pwd" column**:
   - After unlocking, if "Last Bad Pwd" keeps updating every few minutes...
   - Something is actively trying to authenticate with wrong password
   - Check the **DC name** where it's updating - this tells you which DC is closest to the source

5. **Document** in ticket:
   - How many times account locked today
   - What device was causing it
   - Resolution steps

**Escalate if**:
- User has checked all devices and it still keeps locking
- Pattern suggests possible security incident (compromise)

---

### Scenario 3: User Forgot Password

**User reports**: *"I forgot my password. Can you reset it?"*

**Your response**:

1. **Verify** it's really the user:
   - Check caller ID or employee ID
   - Ask a verification question (manager's name, department, last 4 of phone, etc.)
   - **Never** reset a password without verification!

2. **Search** for their account

3. **Check** if account is locked:
   - If "Locked Out" shows "Yes", click **"Unlock on All DCs"** first
   - If "No", proceed to reset

4. **Click** "Reset Password"

5. **Create** a temporary password:
   - Follow your organization's password policy
   - Example format: `Welcome2025!` or `TempPass$123`
   - OR let user choose if they're on the phone

6. **Check** the box: ☑ "User must change password at next logon"
   - This forces them to create their own password immediately

7. **Click** OK

8. **Communicate** the temporary password securely:
   - ✅ **In person** - Write it down and hand it to them
   - ✅ **Phone call** - Spell it out letter by letter
   - ✅ **Encrypted message** - Use encrypted email or secure portal
   - ❌ **Plain email** - NEVER send passwords via email
   - ❌ **Chat/IM** - Avoid unless your chat platform is encrypted

9. **Tell user**:
   - *"Your temporary password is [password]. You'll be prompted to change it immediately after logging in. Choose a new password you'll remember."*

10. **Document** in ticket system:
    - Date/time of reset
    - Verification method used
    - That user must change at next logon

---

### Scenario 4: Results Show "Never" for All Timestamps

**You see**: All timestamps show "Never" - no lockout time, no bad password time

**What it means**:
- ✅ Account is in good standing
- ✅ No recent authentication problems
- ✅ User hasn't entered wrong password recently

**If user still can't log in**:
- Check if account is **disabled**: (Not shown in this tool - use Active Directory Users and Computers)
- Check if account is **expired**: (Not shown in this tool - use AD module: `Get-ADUser -Identity username -Properties AccountExpirationDate`)
- Check **password age** - if very old (red), password may be expired
- Check if user is typing username/password correctly
- Try having user log in from different computer/location

---

### Scenario 5: Some DCs Show Locked, Others Don't

**You see**:
```
DC01 | ✓ (PDC) | Yes | 5 | 2025-10-15 14:30:22
DC02 |         | No  | 0 | Never
DC03 |         | No  | 0 | Never
```

**What it means**:
- The lockout happened recently on DC01
- It hasn't replicated to DC02 and DC03 yet
- This is **normal** - replication takes a few seconds to minutes

**What to do**:
- Click **"Unlock on All DCs"** to immediately unlock everywhere
- OR
- Unlock on DC01 only and wait 5-15 minutes for replication
- Use **Refresh** button to watch the status update

**Why it matters**:
- If user tries to log in again immediately, they might authenticate against DC02 or DC03
- Those DCs might still think the account is locked (stale data)
- Unlocking on all DCs ensures immediate resolution regardless of which DC they hit

---

### Scenario 6: "Access Denied" or Permission Errors

**Error message**: *"Access denied. You do not have permission to unlock this account."*

**What it means**:
- Your user account doesn't have the required permissions
- You need to be a member of:
  - **Account Operators** group, OR
  - **Domain Admins** group, OR
  - Have delegated permissions for account management

**What to do**:
1. **Verify** your permissions:
   ```powershell
   whoami /groups
   ```
   Look for "Account Operators" or "Domain Admins"

2. **If you don't have permissions**:
   - **Escalate** to a senior team member or supervisor
   - **Document** in ticket: "Account requires unlock - escalated to [person] due to permissions"

3. **If you should have permissions**:
   - Log out and log back in (permissions might not have applied yet)
   - Check with IT admin to verify group membership
   - May need to close application and relaunch after permissions added

**Note**: You can **view** account status without special permissions, but **unlocking** and **resetting passwords** require elevated rights.

---

## Understanding Results

### Interpreting the Grid

#### Domain Controller Column
- Shows the **hostname** of each domain controller
- Example: `DC01`, `NYC-DC-02`, `BRANCH-DC`

**Why it matters**: 
- Different DCs may show different statuses due to replication lag
- Knowing which DC has the lock helps with troubleshooting

#### Site Column
- Shows the **Active Directory site** where the DC is located
- Example: `Main-Office`, `Branch-NYC`, `Remote-LA`

**Why it matters**:
- Users authenticate against the **closest DC** (usually in their site)
- If a remote site DC shows a lock, users in that location will be affected

#### PDC Column
- Shows a **checkmark (✓)** for the Primary Domain Controller
- Only **one** DC will have this checkmark

**Why it matters**:
- The PDC is the "source of truth" for lockouts
- If the PDC shows locked, the account is definitely locked
- Other DCs replicate lockout status from the PDC

#### Locked Out Column
- Shows **"Yes"** if account is currently locked on this DC
- Shows **"No"** if account is NOT locked

**Why it matters**:
- This is the most important column for troubleshooting login issues
- **Any "Yes"** means the user can't log in (if they hit that DC)

#### Bad Pwd Count Column
- Shows number between **0 and 5** (or your organization's threshold)
- **0** = No wrong passwords
- **1-4** = Some wrong attempts, not locked yet
- **5** = Threshold reached, account locked (typical default)

**Why it matters**:
- Helps identify if user is mistyping password
- If count is 3-4, user is close to lockout (warn them!)
- After unlock, this resets to 0

#### Last Bad Pwd Column
- Shows **date and time** of the last wrong password attempt
- Format: `2025-10-15 14:32:18` (YYYY-MM-DD HH:MM:SS)
- Shows **"Never"** if no wrong attempts ever recorded

**Why it matters**:
- Helps identify **when** the problem started
- Can correlate with user's report ("Yes, I tried logging in around 2:30 PM")
- Recent timestamps mean active problem

#### Lockout Time Column
- Shows **date and time** when account was locked
- Format: `2025-10-15 14:32:45` (YYYY-MM-DD HH:MM:SS)
- Shows **"Never"** if account never locked on this DC

**Why it matters**:
- Shows exactly when the lock occurred
- Helps with troubleshooting timeline
- Usually matches or is slightly after "Last Bad Pwd" time

#### Pwd Age Column
- Shows how long since password was last changed
- Format: `45 days`, `120 days`, etc.
- Color-coded:
  - 🟢 Green (0-90 days) = Good
  - 🟡 Yellow (91-180 days) = Aging
  - 🔴 Red (181+ days) = Old

**Why it matters**:
- Old passwords (red) may be expired or need changing
- If user says "I'm using my usual password" but it's red...
  - Password may have been force-changed
  - They may have forgotten they changed it
  - Company policy may require change

---

### Common Result Patterns

#### Pattern 1: All DCs Locked Out
```
DC01 | ✓ | Yes | 5 | 2025-10-15 14:30:22 | 2025-10-15 14:30:45
DC02 |   | Yes | 5 | 2025-10-15 14:30:22 | 2025-10-15 14:30:45
DC03 |   | Yes | 5 | 2025-10-15 14:30:22 | 2025-10-15 14:30:45
```
**Meaning**: Account is locked everywhere. Lockout has fully replicated.  
**Action**: Use "Unlock on All DCs" button.

---

#### Pattern 2: Only PDC Locked
```
DC01 | ✓ | Yes | 5 | 2025-10-15 14:30:22 | 2025-10-15 14:30:45
DC02 |   | No  | 0 | Never                | Never
DC03 |   | No  | 0 | Never                | Never
```
**Meaning**: Lockout just happened, hasn't replicated yet.  
**Action**: Use "Unlock on All DCs" to immediately resolve, or wait 5-15 min for replication.

---

#### Pattern 3: High Bad Password Count, Not Locked
```
DC01 | ✓ | No | 3 | 2025-10-15 14:25:10 | Never
DC02 |   | No | 3 | 2025-10-15 14:25:10 | Never
DC03 |   | No | 3 | 2025-10-15 14:25:10 | Never
```
**Meaning**: User is entering wrong password, but hasn't hit the threshold (usually 5).  
**Action**: Warn user they're close to lockout. Verify password or reset it.

---

#### Pattern 4: Old Lockout (No Longer Locked)
```
DC01 | ✓ | No | 0 | 2025-10-10 09:15:22 | 2025-10-10 09:15:45
DC02 |   | No | 0 | 2025-10-10 09:15:22 | 2025-10-10 09:15:45
DC03 |   | No | 0 | 2025-10-10 09:15:22 | 2025-10-10 09:15:45
```
**Meaning**: Account was locked in the past but is no longer locked (auto-unlocked after 30 min, or manually unlocked).  
**Action**: None needed. Account is currently accessible.

---

#### Pattern 5: No Issues
```
DC01 | ✓ | No | 0 | Never | Never
DC02 |   | No | 0 | Never | Never
DC03 |   | No | 0 | Never | Never
```
**Meaning**: Account is perfectly healthy. No authentication problems.  
**Action**: If user can't log in, problem is NOT account lockout. Check password expiration, account disabled status, network connectivity, etc.

---

## Best Practices

### For Help Desk Staff

#### DO:
- ✅ **Always verify** the user's identity before resetting passwords
- ✅ **Use "Unlock on All DCs"** for fastest resolution
- ✅ **Check password age** - if red, suggest password change
- ✅ **Document** all actions in your ticket system
- ✅ **Use Refresh** after making changes to verify they worked
- ✅ **Enable "must change password at next logon"** for temporary passwords
- ✅ **Communicate passwords securely** (phone, in person, encrypted)
- ✅ **Investigate repeated lockouts** - don't just keep unlocking

#### DON'T:
- ❌ **Don't** reset passwords without verification
- ❌ **Don't** send passwords via plain email or unencrypted chat
- ❌ **Don't** give the same password to multiple users
- ❌ **Don't** ignore repeated lockouts (investigate the root cause)
- ❌ **Don't** exclude DCs without understanding why they're slow
- ❌ **Don't** unlock accounts for users who aren't calling you (social engineering)

### For System Administrators

#### DO:
- ✅ **Monitor** repeated lockouts for patterns (possible security incident)
- ✅ **Audit** password resets and unlocks via logs
- ✅ **Train** help desk staff on proper usage
- ✅ **Exclude** problematic DCs to improve performance
- ✅ **Test** regularly to ensure tool is working
- ✅ **Update** the tool when new versions are released
- ✅ **Configure** centralized config for enterprise deployments

#### DON'T:
- ❌ **Don't** give this tool to users without training
- ❌ **Don't** ignore repeated lockouts from the same account (investigate!)
- ❌ **Don't** disable audit logging
- ❌ **Don't** share admin credentials for tool usage

### For All Users

#### DO:
- ✅ **Use the Refresh button** after making changes
- ✅ **Check all DCs** before concluding "account isn't locked"
- ✅ **Note the PDC result** - it's the most authoritative
- ✅ **Report bugs or issues** to your IT admin
- ✅ **Keep the tool updated** to the latest version

#### DON'T:
- ❌ **Don't** make changes without documenting them
- ❌ **Don't** assume one locked DC means all are locked (check the grid!)
- ❌ **Don't** panic if results look different between DCs (replication lag is normal)

---

## Frequently Asked Questions

### General Questions

#### Q: Why do different domain controllers show different results?

**A**: Active Directory uses **replication** to sync data between domain controllers. This takes a few seconds to minutes. When an account is locked on one DC, it takes time to replicate to all other DCs. This is normal and expected.

---

#### Q: What's the difference between unlocking on one DC vs. all DCs?

**A**: 
- **Unlocking on Selected DC**: Unlocks only that specific DC. Other DCs will unlock automatically when replication completes (5-15 minutes).
- **Unlocking on All DCs**: Immediately unlocks on every DC. User can log in right away regardless of which DC they authenticate against. **Recommended for fastest resolution.**

---

#### Q: Can I use this tool to unlock my own account?

**A**: No. If your account is locked, you can't log in to run the tool. You'll need to:
- Call the help desk to have them unlock it
- Use a different admin account (if you have one)
- Use the self-service password reset portal (if your company has one)

---

#### Q: Why doesn't my search work?

**A**: Common reasons:
- ✅ Check spelling of the username
- ✅ Don't include domain prefix (tool adds it automatically) - try `jsmith`, not `DOMAIN\jsmith`
- ✅ Make sure the user exists in Active Directory
- ✅ Verify you have network connectivity
- ✅ Check that the Active Directory PowerShell module is installed

---

#### Q: What does "PDC" mean?

**A**: **Primary Domain Controller**. This is the domain controller that has the special role of being the "master" for account lockouts. When an account is locked, the PDC is always right. Other DCs replicate from the PDC.

---

#### Q: Can I search by email address?

**A**: It depends on your environment. Try it! If your username is `jsmith@company.com`, you can try typing that in the search box. The tool will attempt to extract the username part. However, it's more reliable to use just the username (`jsmith`).

---

#### Q: How do I undo excluding a DC?

**A**: Currently:
1. Click **File** → **Settings**
2. Note the config file location
3. Open the `config.json` file in Notepad
4. Remove the DC name from the "ExcludedDCs" list
5. Save the file
6. Restart the application

(Future versions may add a GUI option to remove exclusions)

---

### Troubleshooting Questions

#### Q: I get "Access Denied" when trying to unlock. Why?

**A**: You don't have the required permissions. You need to be a member of:
- **Account Operators** group
- **Domain Admins** group
- Have delegated unlock permissions

**Solution**: Contact your IT administrator to request permissions, or escalate the ticket to someone who has access.

---

#### Q: I unlocked the account, but user still can't log in. Why?

**A**: Several possibilities:
1. **Replication lag** - Wait 5 minutes and have user try again
2. **Wrong password** - User is typing the wrong password. Consider resetting it.
3. **Account disabled** - Check in Active Directory Users and Computers
4. **Password expired** - Check the "Pwd Age" column. If red, password may be expired.
5. **Computer/network issue** - Not an account problem. Check network, DNS, etc.

---

#### Q: The tool is very slow. What can I do?

**A**: 
- **Exclude slow DCs**: Right-click on slow DCs and choose "Exclude this DC"
- **Check network**: Ensure you have good network connectivity
- **Contact admin**: Report slow DCs to your system administrator for investigation

---

#### Q: Some columns show "Error" instead of results. Why?

**A**: This means the tool couldn't contact that specific domain controller. Possible reasons:
- DC is offline/unreachable
- Firewall blocking connection
- DC is very slow and timed out (default: 5 seconds)
- Network connectivity issue

**Solution**: Exclude that DC if it happens frequently, or report to system admin.

---

#### Q: Account keeps locking out every few minutes. What's wrong?

**A**: This usually means something is automatically retrying authentication with an old/wrong password. Common culprits:
- 📱 Mobile device with saved credentials
- 💻 Mapped network drives with old credentials
- ⏰ Scheduled tasks running with user's credentials
- 🗂️ Saved credentials in Windows Credential Manager

**Solution**: See [Scenario 2: Account Keeps Locking Out](#scenario-2-account-keeps-locking-out) for detailed troubleshooting steps.

---

### Technical Questions

#### Q: Does this tool work with multiple domains/forests?

**A**: It works with the **current domain** you're logged into. To check accounts in other domains:
- You'd need to run the tool while logged in as a user in that domain
- OR modify the script to specify a different domain (requires customization)

---

#### Q: Can I run this tool from home/VPN?

**A**: Yes, as long as you have:
- ✅ VPN connection to the corporate network
- ✅ Network connectivity to domain controllers (LDAP port 389)
- ✅ Active Directory PowerShell module installed
- ✅ Credentials for the domain

---

#### Q: Does this tool work with Azure AD / Microsoft 365?

**A**: No. This tool is designed for **on-premises Active Directory** only. It uses LDAP queries to domain controllers. Azure AD / Microsoft 365 accounts need to be managed through:
- Azure AD portal
- Microsoft 365 admin center
- Azure AD PowerShell module

---

#### Q: What happens if I close the tool while a search is running?

**A**: The search will be interrupted and incomplete results may be shown. It's best to wait for searches to complete. They typically take only 5-10 seconds.

---

## Getting Help

### Internal Support

- **Help Desk**: [Your company's help desk phone/email]
- **IT Support Portal**: [Your company's ticket system URL]
- **Knowledge Base**: [Your company's internal wiki/KB]

### Reporting Issues

When reporting problems with the tool, include:

1. **What you were trying to do**
   - Example: "I was trying to unlock user jsmith's account"

2. **What happened**
   - Example: "I got an 'Access Denied' error"

3. **Error message** (if any)
   - Copy the exact error message text

4. **Username** (if relevant)
   - Example: "jsmith"

5. **Screenshots** (if helpful)
   - Screenshot of the error or unexpected behavior

6. **Your environment**
   - Your username
   - Computer name
   - Whether you're on VPN or in the office

### Training Resources

- **Quick Start Guide**: `QUICKSTART.md` - 5-minute intro for new users
- **Admin Guide**: `ADMIN-GUIDE.md` - For IT administrators deploying the tool
- **README**: `README.md` - Complete technical documentation

### Version Information

To check what version you're running:
- Look at the title bar of the application window
- OR check File → About (if available in your version)
- Current version: 1.0 (as of October 2025)

---

## Tips for Success

### Quick Wins

1. **Use "Unlock on All DCs"** by default - fastest resolution
2. **Check password age first** - saves time if password is expired
3. **Use Refresh liberally** - verify changes took effect
4. **Document in tickets** - helps track patterns
5. **Investigate repeated lockouts** - don't just keep unlocking

### Time-Savers

- Press **Enter** instead of clicking Search
- Use **right-click menu** for quick actions
- **Exclude slow DCs** to speed up every search
- Keep a **standard temporary password format** ready
- Have **verification questions** prepared for password resets

### Common Mistakes to Avoid

- ❌ Not verifying user identity before password reset
- ❌ Sending passwords via insecure channels
- ❌ Not checking password age before troubleshooting
- ❌ Ignoring repeated lockouts (they indicate a problem!)
- ❌ Not using "Unlock on All DCs" (leaving user partially locked)

---

## Appendix

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Enter** | Execute search (when in search box) |
| **Ctrl+R** | Refresh results |
| **Ctrl+F** | Focus search box |
| **Alt+F4** | Close application |
| **Tab** | Navigate between fields |

*(Note: Exact shortcuts may vary based on your deployment)*

### Password Requirements

Check with your IT department for your organization's specific password policy. Common requirements:

- **Minimum length**: 8-14 characters
- **Complexity**: Must contain:
  - Uppercase letters (A-Z)
  - Lowercase letters (a-z)
  - Numbers (0-9)
  - Symbols (!@#$%^&*)
- **No** part of username
- **No** common words or dictionary words
- **No** previous passwords (last 12 passwords remembered)

### Account Lockout Policy

Typical defaults (your organization may differ):

- **Lockout threshold**: 5 bad password attempts
- **Lockout duration**: 30 minutes (auto-unlock)
- **Reset counter after**: 30 minutes of no bad attempts

### Escalation Procedures

Escalate to Tier 2 / Senior IT if:

- User account keeps locking repeatedly despite troubleshooting
- Multiple users are locked simultaneously (possible AD issue)
- You don't have permissions to unlock/reset
- Account seems compromised (security concern)
- Tool is malfunctioning or showing errors

---

**Document Version**: 1.0  
**Last Updated**: October 15, 2025  
**Audience**: Help Desk Staff & End Users  
**Review Date**: January 15, 2026

---

## Quick Reference Card

**Print this section for your desk!**

### Most Common Actions

| I need to... | Steps |
|--------------|-------|
| **Check if account is locked** | 1. Type username<br>2. Click Search<br>3. Look at "Locked Out" column |
| **Unlock an account** | 1. Search for user<br>2. Click "Unlock on All DCs"<br>3. Click Yes to confirm |
| **Reset password** | 1. Search for user<br>2. Click "Reset Password"<br>3. Enter password twice<br>4. Check "must change at logon"<br>5. Click OK |
| **Verify a fix worked** | 1. Click "Refresh"<br>2. Wait 5 seconds<br>3. Check results |

### Quick Interpretations

| If you see... | It means... | Do this... |
|---------------|-------------|------------|
| "Locked Out" = Yes | Account is locked | Click "Unlock on All DCs" |
| "Locked Out" = No everywhere | Account is NOT locked | Problem is password or other issue |
| Password age is RED | Password is very old (180+ days) | Consider password reset |
| "Bad Pwd Count" = 3 or 4 | Close to lockout! | Warn user, verify password |
| Different results on different DCs | Replication lag | Use "Unlock on All DCs" or wait 10 min |

### Remember

- ✅ Always verify user identity before password resets
- ✅ Never send passwords via plain email
- ✅ Document all actions in tickets
- ✅ Investigate repeated lockouts (don't just keep unlocking)
- ✅ Use "Unlock on All DCs" for fastest resolution

**Questions? Contact Help Desk: [your help desk contact]**
