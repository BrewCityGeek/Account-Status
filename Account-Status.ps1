Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.DirectoryServices -ErrorAction SilentlyContinue
Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction SilentlyContinue

# Additional assembly loading for PowerShell 5 compatibility
try {
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
} catch {
    try {
        [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") | Out-Null
    } catch {
        # Silent fail - will be caught by verification below
    }
}

# Verify the types are available
try {
    $testContext = [System.DirectoryServices.AccountManagement.PrincipalContext]
    $testUser = [System.DirectoryServices.AccountManagement.UserPrincipal]
} catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Required .NET Framework components are not available. Please ensure .NET Framework 3.5+ is installed.",
        "Missing Components",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Configuration file path - handle both script and compiled executable scenarios
if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    # When compiled to EXE, use the executable's directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if ([string]::IsNullOrEmpty($scriptDir)) {
        # Fallback to current directory
        $scriptDir = Get-Location
    }
} else {
    $scriptDir = $PSScriptRoot
}
$script:configPath = Join-Path -Path $scriptDir -ChildPath "config.json"

# Function to load configuration
function Load-Configuration {
    if (Test-Path $script:configPath) {
        try {
            $config = Get-Content $script:configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            return $null
        }
    } else {
        return $null
    }
}

# Function to save configuration
function Save-Configuration {
    param(
        [array]$ExcludedDCs
    )
    
    try {
        $config = @{
            ExcludedDCs = $ExcludedDCs
            LastUpdated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        
        $config | ConvertTo-Json | Set-Content -Path $script:configPath -Force
        return $true
    } catch {
        return $false
    }
}

# Load configuration on startup
$config = Load-Configuration
if ($config -and $config.ExcludedDCs) {
    $script:excludedDCs = @($config.ExcludedDCs)
} else {
    # Default exclusion list if no config exists
    $script:excludedDCs = @('STLDP-CP-DC1')
}

# Script-level variable for excluded DCs (loaded from config or defaults)

function Get-ADUserStatus {
    param(
        [string]$Username,
        [scriptblock]$StatusUpdateCallback,
        [scriptblock]$GridUpdateCallback
    )

    Write-Host "Getting user status for: $Username" -ForegroundColor Cyan
    $userStatus = @()
    $timeoutSeconds = 5  # Increased back to 5 seconds to catch slower DCs

    try {
        # Pre-load ActiveDirectory module
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        
        # Get all domain controllers
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        $allDCs = $domain.DomainControllers | Where-Object { 
            $dcName = $_.Name
            $excluded = $false
            foreach ($excludePattern in $script:excludedDCs) {
                if ($dcName -like "*$excludePattern*") {
                    Write-Host "Skipping excluded DC: $dcName" -ForegroundColor Yellow
                    $excluded = $true
                    break
                }
            }
            -not $excluded
        } | Sort-Object Name  # Sort domain controllers alphabetically by name
        $pdcEmulator = $domain.PdcRoleOwner
        
        Write-Host "Found $($allDCs.Count) domain controllers (after exclusions) - Starting FAST parallel queries using runspaces..." -ForegroundColor Yellow
        if ($StatusUpdateCallback) { & $StatusUpdateCallback "Querying $($allDCs.Count) domain controllers..." }
        
        # Create runspace pool for parallel execution
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 20)
        $runspacePool.Open()
        
        # Script block to execute in each runspace
        $scriptBlock = {
            param($dcName, $username, $isPDC)
            
            try {
                Import-Module ActiveDirectory -ErrorAction Stop
                
                # Get DC site information
                $dcSite = 'Unknown'
                try {
                    $dc = Get-ADDomainController -Identity $dcName -ErrorAction Stop
                    $dcSite = $dc.Site
                } catch {
                    $dcSite = 'Unknown'
                }
                
                # Request properties explicitly - use wildcard to ensure we get everything
                $user = Get-ADUser -Identity $username -Server $dcName -Properties * -ErrorAction Stop
                
                if ($user) {
                    $isLockedOut = if ($user.LockedOut) { 'Yes' } else { 'No' }
                    
                    # Handle badPasswordTime (FILETIME format) - Simple approach with debug output
                    $badPwdTime = 'Never'
                    $rawBadPwdTime = $user.badPasswordTime
                    if ($rawBadPwdTime) {
                        try {
                            $numericValue = [int64]$rawBadPwdTime
                            if ($numericValue -gt 0) {
                                $badPwdTime = [DateTime]::FromFileTime($numericValue).ToString('yyyy-MM-dd HH:mm:ss')
                            }
                        } catch {
                            # If conversion fails, show the raw value for debugging
                            $badPwdTime = "Error converting: $rawBadPwdTime (Type: $($rawBadPwdTime.GetType().Name))"
                        }
                    }
                    
                    # Handle lockoutTime (FILETIME format) - Simple approach with debug output
                    $lockoutTime = 'Never'
                    $rawLockoutTime = $user.lockoutTime
                    if ($rawLockoutTime) {
                        try {
                            $numericValue = [int64]$rawLockoutTime
                            if ($numericValue -gt 0) {
                                $lockoutTime = [DateTime]::FromFileTime($numericValue).ToString('yyyy-MM-dd HH:mm:ss')
                            }
                        } catch {
                            # If conversion fails, show the raw value for debugging
                            $lockoutTime = "Error converting: $rawLockoutTime (Type: $($rawLockoutTime.GetType().Name))"
                        }
                    }
                    
                    $badPwdCount = if ($user.badPwdCount -and $user.badPwdCount -gt 0) { $user.badPwdCount } else { 0 }
                    
                    # Return as simple hashtable - works better with runspaces
                    return @{
                        Success = $true
                        DCName = $dcName
                        DCSite = $dcSite
                        IsPDC = $isPDC
                        IsLockedOut = $isLockedOut
                        BadPwdCount = $badPwdCount
                        BadPwdTime = $badPwdTime
                        LockoutTime = $lockoutTime
                    }
                }
                return @{ 
                    Success = $false
                    Error = "User not found on $dcName"
                    DCName = $dcName
                    DCSite = $dcSite
                    IsPDC = $isPDC
                }
            } catch {
                # Try to get site even on error
                $dcSite = 'Unknown'
                try {
                    $dc = Get-ADDomainController -Identity $dcName -ErrorAction Stop
                    $dcSite = $dc.Site
                } catch {
                    $dcSite = 'Unknown'
                }
                
                return @{ 
                    Success = $false
                    Error = $_.Exception.Message
                    DCName = $dcName
                    DCSite = $dcSite
                    IsPDC = $isPDC
                }
            }
        }
        
        # Create and start runspaces for all DCs
        $runspaces = @()
        
        foreach ($dc in $allDCs) {
            $isPDC = $dc.Name -eq $pdcEmulator.Name
            $displayName = if ($isPDC) { "$($dc.Name) (PDC)" } else { $dc.Name }
            
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool
            [void]$powershell.AddScript($scriptBlock)
            [void]$powershell.AddArgument($dc.Name)
            [void]$powershell.AddArgument($Username)
            [void]$powershell.AddArgument($isPDC)
            
            $runspaces += @{
                PowerShell = $powershell
                Handle = $powershell.BeginInvoke()
                DCName = $displayName
                StartTime = Get-Date
                Completed = $false
            }
        }
        
        Write-Host "All runspaces started, collecting results..." -ForegroundColor Yellow
        
        # Collect results as they complete
        $completedCount = 0
        $totalCount = $runspaces.Count
        
        while ($completedCount -lt $totalCount) {
            foreach ($runspace in $runspaces) {
                if (-not $runspace.Completed) {
                    # Check if completed or timed out
                    if ($runspace.Handle.IsCompleted) {
                        try {
                            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
                            $runspace.Completed = $true
                            $completedCount++
                            
                            Write-Host "Completed: $($runspace.DCName)" -ForegroundColor Green
                            
                            if ($result.Success) {
                                $displayName = if ($result.IsPDC) { "$($result.DCName) (PDC)" } else { $result.DCName }
                                
                                $status = [PSCustomObject]@{
                                    'DomainController'      = $displayName
                                    'Site'                  = $result.DCSite
                                    'LockedOut'             = $result.IsLockedOut
                                    'BadPwdCount'           = $result.BadPwdCount
                                    'LastBadPasswordTime'   = $result.BadPwdTime
                                    'LastLockoutTime'       = $result.LockoutTime
                                    'ErrorMessage'          = ''
                                }
                                $userStatus += $status
                                
                                # Real-time grid update
                                if ($GridUpdateCallback) { & $GridUpdateCallback $status }
                            } else {
                                $displayName = if ($result.IsPDC) { "$($result.DCName) (PDC)" } else { $result.DCName }
                                $errorStatus = [PSCustomObject]@{
                                    'DomainController'      = $displayName
                                    'Site'                  = if ($result.DCSite) { $result.DCSite } else { 'Unknown' }
                                    'LockedOut'             = 'Error'
                                    'BadPwdCount'           = 'Error'
                                    'LastBadPasswordTime'   = 'Error'
                                    'LastLockoutTime'       = 'Error'
                                    'ErrorMessage'          = if ($result.Error) { $result.Error } else { "Unknown error" }
                                }
                                $userStatus += $errorStatus
                                
                                if ($GridUpdateCallback) { & $GridUpdateCallback $errorStatus }
                                
                                # Show detailed error message
                                $errorMsg = if ($result.Error) { $result.Error } else { "Unknown error" }
                                Write-Host "Error from $($runspace.DCName): $errorMsg" -ForegroundColor Red
                            }
                            
                            # Update status periodically
                            if ($StatusUpdateCallback -and ($completedCount % 5 -eq 0 -or $completedCount -eq $totalCount)) {
                                & $StatusUpdateCallback "Completed: $completedCount/$totalCount domain controllers"
                            }
                        } catch {
                            Write-Host "Error processing result from $($runspace.DCName): $($_.Exception.Message)" -ForegroundColor Red
                            $runspace.Completed = $true
                            $completedCount++
                        } finally {
                            $runspace.PowerShell.Dispose()
                        }
                    }
                    elseif (((Get-Date) - $runspace.StartTime).TotalSeconds -gt $timeoutSeconds -and -not $runspace.Completed) {
                        # Timeout
                        $runspace.PowerShell.Stop()
                        $runspace.Completed = $true
                        $completedCount++
                        
                        $timeoutStatus = [PSCustomObject]@{
                            'DomainController'      = $runspace.DCName
                            'Site'                  = 'Timeout'
                            'LockedOut'             = 'Timeout'
                            'BadPwdCount'           = 'Timeout'
                            'LastBadPasswordTime'   = 'Timeout'
                            'LastLockoutTime'       = 'Timeout'
                            'ErrorMessage'          = "Query exceeded $timeoutSeconds second timeout - DC may be slow or unreachable"
                        }
                        $userStatus += $timeoutStatus
                        
                        if ($GridUpdateCallback) { & $GridUpdateCallback $timeoutStatus }
                        Write-Host "Timeout: $($runspace.DCName)" -ForegroundColor Red
                        
                        $runspace.PowerShell.Dispose()
                    }
                }
            }
            Start-Sleep -Milliseconds 10  # Very short sleep for fast response
        }
        
        # Clean up
        $runspacePool.Close()
        $runspacePool.Dispose()
        
        Write-Host "All DC queries completed" -ForegroundColor Green
        if ($StatusUpdateCallback) { & $StatusUpdateCallback "All queries completed - $($userStatus.Count) results" }
        
    } catch {
        Write-Host "General error in Get-ADUserStatus: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $userStatus
}

function Get-ADUserBasicInfo {
    param(
        [string]$Username
    )
    
    try {
        Write-Host "Getting basic info for: $Username" -ForegroundColor Cyan
        Import-Module ActiveDirectory -ErrorAction Stop
        
        $user = Get-ADUser -Identity $Username -Properties * -ErrorAction Stop
        
        # Calculate values first to avoid syntax issues
        $managerName = if ($user.Manager) { 
            try { (Get-ADUser -Identity $user.Manager -ErrorAction Stop).Name } 
            catch { 'Error retrieving manager' }
        } else { 'Not Set' }
        
        $accountStatus = if ($user.Enabled) { 'Enabled' } else { 'Disabled' }
        
        $lastLogon = if ($user.LastLogonDate) { 
            $user.LastLogonDate.ToString('yyyy-MM-dd HH:mm:ss') 
        } else { 'Never' }
        
        $passwordLastSet = if ($user.PasswordLastSet) { 
            $user.PasswordLastSet.ToString('yyyy-MM-dd HH:mm:ss') 
        } else { 'Never' }
        
        $passwordExpires = if ($user.PasswordNeverExpires) { 
            'Never' 
        } elseif ($user.PasswordLastSet) { 
            try {
                $maxAge = (Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop).MaxPasswordAge
                if ($maxAge.Days -gt 0) {
                    ($user.PasswordLastSet.AddDays($maxAge.Days)).ToString('yyyy-MM-dd HH:mm:ss')
                } else { 'Never' }
            } catch { 'Unable to determine' }
        } else { 'Unknown' }
        
        $accountCreated = if ($user.Created) { 
            $user.Created.ToString('yyyy-MM-dd HH:mm:ss') 
        } else { 'Unknown' }
        
        $isLockedOut = if ($user.LockedOut) { 'Yes' } else { 'No' }
        
        $groupCount = try {
            (Get-ADPrincipalGroupMembership -Identity $Username -ErrorAction Stop | Measure-Object).Count
        } catch { 'Error counting groups' }
        
        # Create an array of objects for DataGridView binding
        $basicInfoArray = @()
        $properties = @(
            'Username (SamAccountName)',
            'Display Name',
            'Email Address',
            'Department',
            'Title',
            'Manager',
            'Office',
            'Phone',
            'Account Status',
            'Last Logon',
            'Password Last Set',
            'Password Expires',
            'Account Created',
            'Account Locked Out',
            'Bad Password Count',
            'Home Directory',
            'Profile Path',
            'Group Memberships (Count)'
        )
        
        $values = @(
            $user.SamAccountName,
            $user.DisplayName,
            $user.EmailAddress,
            $user.Department,
            $user.Title,
            $managerName,
            $user.Office,
            $user.OfficePhone,
            $accountStatus,
            $lastLogon,
            $passwordLastSet,
            $passwordExpires,
            $accountCreated,
            $isLockedOut,
            $user.BadLogonCount,
            $user.HomeDirectory,
            $user.ProfilePath,
            $groupCount
        )
        
        # Create individual objects for each property-value pair
        for ($i = 0; $i -lt $properties.Count; $i++) {
            $basicInfoArray += [PSCustomObject]@{
                'Property' = $properties[$i]
                'Value' = if ($values[$i]) { $values[$i].ToString() } else { 'Not Set' }
            }
        }
        
        Write-Host "Created $($basicInfoArray.Count) property-value pairs" -ForegroundColor Green
        return $basicInfoArray
    } catch {
        Write-Host "Error getting basic info: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Search-ADUser {
    param(
        [string]$SearchTerm
    )
    
    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        return @()
    }
    
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        
        # Create the filter string properly
        $filter = "SamAccountName -like '*$SearchTerm*' -or Name -like '*$SearchTerm*' -or GivenName -like '*$SearchTerm*' -or Surname -like '*$SearchTerm*'"
        
        Write-Host "Searching for users with filter: $filter" -ForegroundColor Yellow
        
        $users = Get-ADUser -Filter $filter -Properties SamAccountName, Name, GivenName, Surname -ErrorAction Stop
        
        Write-Host "Found $($users.Count) users" -ForegroundColor Green
        
        return $users | Select-Object SamAccountName, Name
    } catch {
        Write-Host "Error in Search-ADUser: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function to load user information (reusable for initial load and refresh)
function Load-UserInformation {
    param(
        [string]$Username,
        [string]$DisplayName
    )
    
    try {
        # Store selected username for context menu operations
        $script:selectedUsername = $Username
        
        $statusLabel.Text = "Loading information for $Username - $DisplayName..."
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
        Write-Host "Loading user information: $Username" -ForegroundColor Cyan
        
        # Clear both grids first
        $basicInfoGrid.DataSource = $null
        $statusGrid.DataSource = $null
        
        # Get and display password information early (before DC queries)
        $statusLabel.Text = "Getting password information for $Username - $DisplayName..."
        $statusLabel.Refresh()
        try {
            $user = Get-ADUser -Identity $Username -Properties PasswordLastSet -ErrorAction Stop
            if ($user.PasswordLastSet) {
                $passwordLastSetLabel.Text = "Last Changed: $($user.PasswordLastSet.ToString('yyyy-MM-dd HH:mm:ss'))"
                $passwordAge = (Get-Date) - $user.PasswordLastSet
                $passwordAgeLabel.Text = "Age: $($passwordAge.Days) days"
                
                # Color code based on age
                if ($passwordAge.Days -gt 90) {
                    $passwordAgeLabel.ForeColor = [System.Drawing.Color]::Red
                } elseif ($passwordAge.Days -gt 60) {
                    $passwordAgeLabel.ForeColor = [System.Drawing.Color]::DarkOrange
                } else {
                    $passwordAgeLabel.ForeColor = [System.Drawing.Color]::Green
                }
            } else {
                $passwordLastSetLabel.Text = "Last Changed: Never"
                $passwordAgeLabel.Text = "Age: Never set"
                $passwordAgeLabel.ForeColor = [System.Drawing.Color]::Red
            }
        } catch {
            $passwordLastSetLabel.Text = "Last Changed: Error retrieving"
            $passwordAgeLabel.Text = "Age: Error"
            $passwordAgeLabel.ForeColor = [System.Drawing.Color]::Red
        }
        
        # Force UI update
        $form.Refresh()
        
        # Get basic user information
        $statusLabel.Text = "Loading basic information for $Username - $DisplayName..."
        $statusLabel.Refresh()
        Write-Host "Getting basic user information..." -ForegroundColor Yellow
        $basicInfo = Get-ADUserBasicInfo -Username $Username
        if ($basicInfo -and $basicInfo.Count -gt 0) {
            Write-Host "BasicInfo array count: $($basicInfo.Count)" -ForegroundColor Magenta
            Write-Host "BasicInfoGrid exists: $($basicInfoGrid -ne $null)" -ForegroundColor Magenta
            Write-Host "First item: Property='$($basicInfo[0].Property)', Value='$($basicInfo[0].Value)'" -ForegroundColor Magenta
            
            # Clear and reset the grid
            $basicInfoGrid.DataSource = $null
            $basicInfoGrid.Rows.Clear()
            $basicInfoGrid.Columns.Clear()
            
            # Set up columns manually
            $basicInfoGrid.Columns.Add("Property", "Property")
            $basicInfoGrid.Columns.Add("Value", "Value")
            $basicInfoGrid.Columns[0].Width = 300
            $basicInfoGrid.Columns[1].Width = 500
            
            # Add rows manually
            foreach ($item in $basicInfo) {
                $rowIndex = $basicInfoGrid.Rows.Add()
                $basicInfoGrid.Rows[$rowIndex].Cells[0].Value = $item.Property
                $basicInfoGrid.Rows[$rowIndex].Cells[1].Value = $item.Value
            }
            
            $basicInfoGrid.Refresh()
            Write-Host "Basic info loaded successfully with $($basicInfoGrid.Rows.Count) rows" -ForegroundColor Green
        } else {
            Write-Host "No basic info returned or empty array" -ForegroundColor Red
        }
        
        # Get domain controller status with progress updates
        $statusCallback = {
            param($message)
            $statusLabel.Text = "$message for $Username - $DisplayName"
            $statusLabel.Refresh()
        }
        
        # Set up the grid for real-time updates
        $statusGrid.DataSource = $null
        $statusGrid.Rows.Clear()
        $statusGrid.Columns.Clear()
        
        # Set up columns manually
        $statusGrid.Columns.Add("DomainController", "Domain Controller")
        $statusGrid.Columns.Add("Site", "Site")
        $statusGrid.Columns.Add("LockedOut", "Locked Out")
        $statusGrid.Columns.Add("BadPwdCount", "Bad Pwd Count")
        $statusGrid.Columns.Add("LastBadPasswordTime", "Last Bad Password Time")
        $statusGrid.Columns.Add("LastLockoutTime", "Last Lockout Time")
        $statusGrid.AutoResizeColumns()
        
        # Grid update callback for real-time updates
        $gridUpdateCallback = {
            param($statusItem)
            try {
                $rowIndex = $statusGrid.Rows.Add()
                $statusGrid.Rows[$rowIndex].Cells[0].Value = $statusItem.DomainController
                $statusGrid.Rows[$rowIndex].Cells[1].Value = $statusItem.Site
                $statusGrid.Rows[$rowIndex].Cells[2].Value = $statusItem.LockedOut
                $statusGrid.Rows[$rowIndex].Cells[3].Value = $statusItem.BadPwdCount
                $statusGrid.Rows[$rowIndex].Cells[4].Value = $statusItem.LastBadPasswordTime
                $statusGrid.Rows[$rowIndex].Cells[5].Value = $statusItem.LastLockoutTime
                
                # Add tooltips for Error and Timeout entries
                if ($statusItem.ErrorMessage) {
                    for ($i = 0; $i -lt 6; $i++) {
                        $statusGrid.Rows[$rowIndex].Cells[$i].ToolTipText = $statusItem.ErrorMessage
                    }
                }
                
                $statusGrid.Refresh()
            } catch {
                Write-Host "Error updating grid: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "Getting domain controller status..." -ForegroundColor Yellow
        $status = Get-ADUserStatus -Username $Username -StatusUpdateCallback $statusCallback -GridUpdateCallback $gridUpdateCallback
        
        # The grid is now populated in real-time via the GridUpdateCallback
        # Sort the grid by Domain Controller name after all results are collected
        if ($status -and $status.Count -gt 0) {
            Write-Host "DC status completed - $($status.Count) domain controllers processed" -ForegroundColor Green
            Write-Host "Sorting results by Domain Controller name..." -ForegroundColor Yellow
            $statusGrid.Sort($statusGrid.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)
            Write-Host "Grid sorted successfully" -ForegroundColor Green
            
            # Check if account is locked out on any DC
            $isLockedOut = $false
            foreach ($row in $statusGrid.Rows) {
                if ($row.Cells[2].Value -eq 'Yes') {
                    $isLockedOut = $true
                    break
                }
            }
            
            # Enable/disable unlock all button based on lockout status
            $unlockAllButton.Enabled = $isLockedOut
            if ($isLockedOut) {
                Write-Host "Account is locked out - Unlock All DCs button enabled" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No DC status returned or empty array" -ForegroundColor Red
            $unlockAllButton.Enabled = $false
        }
        
        $statusLabel.Text = "Information loaded for $Username - $DisplayName"
        $statusLabel.ForeColor = [System.Drawing.Color]::Green
        
        # Enable refresh button after successful load
        $refreshButton.Enabled = $true
        
        # Switch to Domain Controller Status tab after data is loaded
        $tabControl.SelectedTab = $statusTab
        
    } catch {
        $statusLabel.Text = "Error loading information for $Username - $DisplayName"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        Write-Host "Error retrieving user information: $($_.Exception.Message)" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show("Error retrieving information for selected user: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Account Status Checker"
$form.Size = New-Object System.Drawing.Size(900,875)  # Increased to 875 to accommodate menu bar
$form.StartPosition = "CenterScreen"

# Add Main Menu
$mainMenu = New-Object System.Windows.Forms.MenuStrip
$form.Controls.Add($mainMenu)

# File Menu
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"
$mainMenu.Items.Add($fileMenu)

# Settings submenu
$settingsMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$settingsMenu.Text = "Settings"
$fileMenu.DropDownItems.Add($settingsMenu)

# Change Config Directory
$configDirMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$configDirMenu.Text = "Change Config Directory..."
$settingsMenu.DropDownItems.Add($configDirMenu)

$configDirMenu.Add_Click({
    # Create a folder browser dialog
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select directory for configuration file"
    $folderBrowser.SelectedPath = Split-Path -Path $script:configPath -Parent
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $newConfigPath = Join-Path -Path $folderBrowser.SelectedPath -ChildPath "config.json"
        
        # Ask if user wants to move existing config
        if (Test-Path $script:configPath) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to move the existing configuration file to the new location?",
                "Move Configuration",
                [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    Copy-Item -Path $script:configPath -Destination $newConfigPath -Force
                    Remove-Item -Path $script:configPath -Force
                    $script:configPath = $newConfigPath
                    [System.Windows.Forms.MessageBox]::Show(
                        "Configuration moved successfully to:`n$newConfigPath",
                        "Success",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                } catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error moving configuration file: $($_.Exception.Message)",
                        "Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            } elseif ($result -eq [System.Windows.Forms.DialogResult]::No) {
                $script:configPath = $newConfigPath
                [System.Windows.Forms.MessageBox]::Show(
                    "Configuration directory changed to:`n$newConfigPath`n`nExisting config was kept at the old location.",
                    "Configuration Updated",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            # Cancel: do nothing
        } else {
            $script:configPath = $newConfigPath
            [System.Windows.Forms.MessageBox]::Show(
                "Configuration directory changed to:`n$newConfigPath",
                "Configuration Updated",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
})

$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Username or Name:"
$label.Location = New-Object System.Drawing.Point(10,30)
$label.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,60)
$textBox.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($textBox)

$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = "Search"
$searchButton.Location = New-Object System.Drawing.Point(320,58)
$searchButton.Size = New-Object System.Drawing.Size(75,23)
$form.Controls.Add($searchButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Location = New-Object System.Drawing.Point(405,58)
$refreshButton.Size = New-Object System.Drawing.Size(75,23)
$refreshButton.Enabled = $false  # Initially disabled
$refreshButton.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($refreshButton)

$unlockAllButton = New-Object System.Windows.Forms.Button
$unlockAllButton.Text = "Unlock on All DCs"
$unlockAllButton.Location = New-Object System.Drawing.Point(490,58)
$unlockAllButton.Size = New-Object System.Drawing.Size(110,23)
$unlockAllButton.Enabled = $false  # Initially disabled
$unlockAllButton.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8, [System.Drawing.FontStyle]::Bold)
$unlockAllButton.ForeColor = [System.Drawing.Color]::DarkRed
$form.Controls.Add($unlockAllButton)

$userList = New-Object System.Windows.Forms.ListBox
$userList.Location = New-Object System.Drawing.Point(10,90)
$userList.Size = New-Object System.Drawing.Size(400,120)
$form.Controls.Add($userList)

# Add status label for user feedback
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready - Search for a user to begin"
$statusLabel.Location = New-Object System.Drawing.Point(430,135)
$statusLabel.Size = New-Object System.Drawing.Size(400,35)
$statusLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [System.Drawing.Color]::Blue
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$form.Controls.Add($statusLabel)

# Create tab control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(10,245)
$tabControl.Size = New-Object System.Drawing.Size(860,570)  # Adjusted for menu bar
$form.Controls.Add($tabControl)

# Domain Controller Status Tab (Primary)
$statusTab = New-Object System.Windows.Forms.TabPage
$statusTab.Text = "Domain Controller Status"
$tabControl.TabPages.Add($statusTab)

$statusGrid = New-Object System.Windows.Forms.DataGridView
$statusGrid.Location = New-Object System.Drawing.Point(10,10)
$statusGrid.Size = New-Object System.Drawing.Size(840,500)  # Increased from 350 to 500
$statusGrid.ReadOnly = $true
$statusGrid.AllowUserToAddRows = $false
$statusGrid.AllowUserToDeleteRows = $false
$statusGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells
$statusGrid.ShowCellToolTips = $true  # Enable tooltips
$statusTab.Controls.Add($statusGrid)

# Create context menu for DC status grid
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$menuResetPassword = New-Object System.Windows.Forms.ToolStripMenuItem
$menuResetPassword.Text = "Reset User Password..."
$contextMenu.Items.Add($menuResetPassword)

$menuUnlockAccount = New-Object System.Windows.Forms.ToolStripMenuItem
$menuUnlockAccount.Text = "Unlock Account on This DC"
$contextMenu.Items.Add($menuUnlockAccount)

$menuRefreshDC = New-Object System.Windows.Forms.ToolStripMenuItem
$menuRefreshDC.Text = "Refresh This DC"
$contextMenu.Items.Add($menuRefreshDC)

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$menuExcludeDC = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExcludeDC.Text = "Exclude DC from Scans"
$contextMenu.Items.Add($menuExcludeDC)

$statusGrid.ContextMenuStrip = $contextMenu

# Store selected username and DC for context menu operations
$script:selectedUsername = $null
$script:selectedDC = $null

# Context menu opening event - capture the clicked row
$contextMenu.Add_Opening({
    param($sender, $e)
    
    # Get the clicked row
    $hitTest = $statusGrid.HitTest($statusGrid.PointToClient([System.Windows.Forms.Cursor]::Position).X, 
                                     $statusGrid.PointToClient([System.Windows.Forms.Cursor]::Position).Y)
    
    if ($hitTest.RowIndex -ge 0) {
        $script:selectedDC = $statusGrid.Rows[$hitTest.RowIndex].Cells[0].Value
        # Enable menu items
        $menuResetPassword.Enabled = $true
        $menuUnlockAccount.Enabled = $true
        $menuRefreshDC.Enabled = $true
        $menuExcludeDC.Enabled = $true
    } else {
        # Disable if not on a valid row
        $menuResetPassword.Enabled = $false
        $menuUnlockAccount.Enabled = $false
        $menuRefreshDC.Enabled = $false
        $menuExcludeDC.Enabled = $false
    }
})

# Menu item click handlers
$menuResetPassword.Add_Click({
    if ($script:selectedUsername -and $script:selectedDC) {
        # Create a proper input dialog that stays on top
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = "Reset Password"
        $inputForm.Size = New-Object System.Drawing.Size(400,220)
        $inputForm.StartPosition = "CenterParent"
        $inputForm.TopMost = $true
        $inputForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $inputForm.MaximizeBox = $false
        $inputForm.MinimizeBox = $false
        
        # Header label
        $headerLabel = New-Object System.Windows.Forms.Label
        $headerLabel.Text = "Reset password for user: $($script:selectedUsername)"
        $headerLabel.Location = New-Object System.Drawing.Point(10,15)
        $headerLabel.Size = New-Object System.Drawing.Size(370,20)
        $headerLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9, [System.Drawing.FontStyle]::Bold)
        $inputForm.Controls.Add($headerLabel)
        
        # New password label
        $newPwdLabel = New-Object System.Windows.Forms.Label
        $newPwdLabel.Text = "New password:"
        $newPwdLabel.Location = New-Object System.Drawing.Point(10,45)
        $newPwdLabel.Size = New-Object System.Drawing.Size(100,20)
        $inputForm.Controls.Add($newPwdLabel)
        
        # New password textbox
        $newPwdTextBox = New-Object System.Windows.Forms.TextBox
        $newPwdTextBox.Location = New-Object System.Drawing.Point(115,43)
        $newPwdTextBox.Size = New-Object System.Drawing.Size(255,20)
        $newPwdTextBox.UseSystemPasswordChar = $true
        $inputForm.Controls.Add($newPwdTextBox)
        
        # Confirm password label
        $confirmPwdLabel = New-Object System.Windows.Forms.Label
        $confirmPwdLabel.Text = "Confirm password:"
        $confirmPwdLabel.Location = New-Object System.Drawing.Point(10,75)
        $confirmPwdLabel.Size = New-Object System.Drawing.Size(100,20)
        $inputForm.Controls.Add($confirmPwdLabel)
        
        # Confirm password textbox
        $confirmPwdTextBox = New-Object System.Windows.Forms.TextBox
        $confirmPwdTextBox.Location = New-Object System.Drawing.Point(115,73)
        $confirmPwdTextBox.Size = New-Object System.Drawing.Size(255,20)
        $confirmPwdTextBox.UseSystemPasswordChar = $true
        $inputForm.Controls.Add($confirmPwdTextBox)
        
        # "Must change password" checkbox
        $mustChangeCheckbox = New-Object System.Windows.Forms.CheckBox
        $mustChangeCheckbox.Text = "User must change password at next logon"
        $mustChangeCheckbox.Location = New-Object System.Drawing.Point(10,110)
        $mustChangeCheckbox.Size = New-Object System.Drawing.Size(350,20)
        $mustChangeCheckbox.Checked = $true  # Default to checked
        $inputForm.Controls.Add($mustChangeCheckbox)
        
        # OK button
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Location = New-Object System.Drawing.Point(215,145)
        $okButton.Size = New-Object System.Drawing.Size(75,23)
        $okButton.Add_Click({
            # Validate passwords match
            if ($newPwdTextBox.Text -ne $confirmPwdTextBox.Text) {
                [System.Windows.Forms.MessageBox]::Show(
                    $inputForm,
                    "Passwords do not match. Please try again.",
                    "Password Mismatch",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                $confirmPwdTextBox.Text = ""
                $confirmPwdTextBox.Focus()
                return
            }
            
            if ([string]::IsNullOrWhiteSpace($newPwdTextBox.Text)) {
                [System.Windows.Forms.MessageBox]::Show(
                    $inputForm,
                    "Password cannot be empty.",
                    "Invalid Password",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                return
            }
            
            $inputForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $inputForm.Close()
        })
        $inputForm.Controls.Add($okButton)
        $inputForm.AcceptButton = $okButton
        
        # Cancel button
        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = "Cancel"
        $cancelButton.Location = New-Object System.Drawing.Point(295,145)
        $cancelButton.Size = New-Object System.Drawing.Size(75,23)
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $inputForm.Controls.Add($cancelButton)
        $inputForm.CancelButton = $cancelButton
        
        $result = $inputForm.ShowDialog($form)
        
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $newPassword = $newPwdTextBox.Text
            $mustChange = $mustChangeCheckbox.Checked
            $inputForm.Dispose()
            
            try {
                # Reset the password
                Set-ADAccountPassword -Identity $script:selectedUsername -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force) -Reset -ErrorAction Stop
                
                # Set "must change password at next logon" if checked
                if ($mustChange) {
                    Set-ADUser -Identity $script:selectedUsername -ChangePasswordAtLogon $true -ErrorAction Stop
                }
                
                $message = "Password reset successfully for $($script:selectedUsername)"
                if ($mustChange) {
                    $message += "`n`nUser must change password at next logon."
                }
                
                [System.Windows.Forms.MessageBox]::Show(
                    $form,
                    $message,
                    "Success",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            } catch {
                [System.Windows.Forms.MessageBox]::Show(
                    $form,
                    "Error resetting password: $($_.Exception.Message)",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        } else {
            $inputForm.Dispose()
        }
    }
})

$menuUnlockAccount.Add_Click({
    if ($script:selectedUsername -and $script:selectedDC) {
        # Extract DC name without (PDC) suffix
        $dcName = $script:selectedDC -replace ' \(PDC\)', ''
        
        try {
            Unlock-ADAccount -Identity $script:selectedUsername -Server $dcName -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show(
                "Account unlocked successfully on $dcName",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            # Optionally refresh the DC after unlocking
            # (We could call refresh logic here)
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error unlocking account: $($_.Exception.Message)",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
})

$menuRefreshDC.Add_Click({
    if ($script:selectedUsername -and $script:selectedDC) {
        # Extract DC name without (PDC) suffix
        $dcName = $script:selectedDC -replace ' \(PDC\)', ''
        
        $statusLabel.Text = "Refreshing $dcName..."
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
        $statusLabel.Refresh()
        
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
            
            # Get DC site information
            $dcSite = 'Unknown'
            try {
                $dc = Get-ADDomainController -Identity $dcName -ErrorAction Stop
                $dcSite = $dc.Site
            } catch {
                $dcSite = 'Unknown'
            }
            
            $user = Get-ADUser -Identity $script:selectedUsername -Server $dcName -Properties badPasswordTime, lockoutTime, badPwdCount, LockedOut -ErrorAction Stop
            
            if ($user) {
                $isLockedOut = if ($user.LockedOut) { 'Yes' } else { 'No' }
                
                # Handle badPasswordTime (FILETIME format) - Simple approach with debug output
                $badPwdTime = 'Never'
                $rawBadPwdTime = $user.badPasswordTime
                if ($rawBadPwdTime) {
                    try {
                        $numericValue = [int64]$rawBadPwdTime
                        if ($numericValue -gt 0) {
                            $badPwdTime = [DateTime]::FromFileTime($numericValue).ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } catch {
                        $badPwdTime = "Error converting: $rawBadPwdTime (Type: $($rawBadPwdTime.GetType().Name))"
                    }
                }
                
                # Handle lockoutTime (FILETIME format) - Simple approach with debug output
                $lockoutTime = 'Never'
                $rawLockoutTime = $user.lockoutTime
                if ($rawLockoutTime) {
                    try {
                        $numericValue = [int64]$rawLockoutTime
                        if ($numericValue -gt 0) {
                            $lockoutTime = [DateTime]::FromFileTime($numericValue).ToString('yyyy-MM-dd HH:mm:ss')
                        }
                    } catch {
                        $lockoutTime = "Error converting: $rawLockoutTime (Type: $($rawLockoutTime.GetType().Name))"
                    }
                }
                
                $badPwdCount = if ($user.badPwdCount -and $user.badPwdCount -gt 0) { $user.badPwdCount } else { 0 }
                
                # Find and update the row
                foreach ($row in $statusGrid.Rows) {
                    if ($row.Cells[0].Value -eq $script:selectedDC) {
                        $row.Cells[1].Value = $dcSite
                        $row.Cells[2].Value = $isLockedOut
                        $row.Cells[3].Value = $badPwdCount
                        $row.Cells[4].Value = $badPwdTime
                        $row.Cells[5].Value = $lockoutTime
                        
                        # Clear any error tooltip
                        for ($i = 0; $i -lt 6; $i++) {
                            $row.Cells[$i].ToolTipText = ""
                        }
                        break
                    }
                }
                
                $statusGrid.Refresh()
                $statusLabel.Text = "Refreshed $dcName successfully"
                $statusLabel.ForeColor = [System.Drawing.Color]::Green
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Error refreshing DC: $($_.Exception.Message)",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            $statusLabel.Text = "Error refreshing $dcName"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        }
    }
})

$menuExcludeDC.Add_Click({
    if ($script:selectedDC) {
        # Extract DC name without (PDC) suffix
        $dcName = $script:selectedDC -replace ' \(PDC\)', ''
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Exclude '$dcName' from future scans?`n`nYou can re-include it later from the 'Excluded DCs' tab.",
            "Confirm Exclusion",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            # Add to exclusion list if not already there
            if ($script:excludedDCs -notcontains $dcName) {
                $script:excludedDCs += $dcName
                
                # Save configuration to persist exclusions
                Save-Configuration -ExcludedDCs $script:excludedDCs
                
                # Refresh the excluded list display
                & $script:RefreshExcludedList
                
                [System.Windows.Forms.MessageBox]::Show(
                    "'$dcName' has been excluded from scans.`n`nIt will not appear in future queries until re-included.`n`nExclusion saved to configuration file.",
                    "DC Excluded",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                
                # Switch to excluded DCs tab to show the update
                $tabControl.SelectedTab = $excludedTab
            } else {
                [System.Windows.Forms.MessageBox]::Show(
                    "'$dcName' is already excluded from scans.",
                    "Already Excluded",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        }
    }
})

# Basic Info Tab (Secondary)
$basicInfoTab = New-Object System.Windows.Forms.TabPage
$basicInfoTab.Text = "Basic Information"
$tabControl.TabPages.Add($basicInfoTab)

$basicInfoGrid = New-Object System.Windows.Forms.DataGridView
$basicInfoGrid.Location = New-Object System.Drawing.Point(10,10)
$basicInfoGrid.Size = New-Object System.Drawing.Size(840,500)  # Increased from 350 to 500
$basicInfoGrid.ReadOnly = $true
$basicInfoGrid.AllowUserToAddRows = $false
$basicInfoGrid.AllowUserToDeleteRows = $false
$basicInfoGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$basicInfoTab.Controls.Add($basicInfoGrid)

# Excluded DCs Tab (Third)
$excludedTab = New-Object System.Windows.Forms.TabPage
$excludedTab.Text = "Excluded DCs"
$tabControl.TabPages.Add($excludedTab)

$excludedGrid = New-Object System.Windows.Forms.DataGridView
$excludedGrid.Location = New-Object System.Drawing.Point(10,10)
$excludedGrid.Size = New-Object System.Drawing.Size(840,500)
$excludedGrid.ReadOnly = $true
$excludedGrid.AllowUserToAddRows = $false
$excludedGrid.AllowUserToDeleteRows = $false
$excludedGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
$excludedGrid.ShowCellToolTips = $true
$excludedTab.Controls.Add($excludedGrid)

# Setup excluded DCs grid columns
$excludedGrid.Columns.Add("DCName", "Excluded Domain Controller")

# Function to refresh excluded DCs list
$script:RefreshExcludedList = {
    $excludedGrid.Rows.Clear()
    foreach ($dc in ($script:excludedDCs | Sort-Object)) {
        $rowIndex = $excludedGrid.Rows.Add()
        $excludedGrid.Rows[$rowIndex].Cells[0].Value = $dc
    }
    $excludedGrid.Refresh()
}

# Initialize excluded list
& $script:RefreshExcludedList

# Context menu for excluded DCs grid
$excludedContextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$menuReinclude = New-Object System.Windows.Forms.ToolStripMenuItem
$menuReinclude.Text = "Re-include DC in Scans"
$excludedContextMenu.Items.Add($menuReinclude)

$excludedGrid.ContextMenuStrip = $excludedContextMenu

$script:selectedExcludedDC = $null

# Context menu opening event for excluded DCs
$excludedContextMenu.Add_Opening({
    param($sender, $e)
    
    $hitTest = $excludedGrid.HitTest($excludedGrid.PointToClient([System.Windows.Forms.Cursor]::Position).X, 
                                      $excludedGrid.PointToClient([System.Windows.Forms.Cursor]::Position).Y)
    
    if ($hitTest.RowIndex -ge 0) {
        $script:selectedExcludedDC = $excludedGrid.Rows[$hitTest.RowIndex].Cells[0].Value
        $menuReinclude.Enabled = $true
    } else {
        $menuReinclude.Enabled = $false
    }
})

# Re-include DC menu handler
$menuReinclude.Add_Click({
    if ($script:selectedExcludedDC) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Re-include '$($script:selectedExcludedDC)' in future scans?",
            "Confirm Re-inclusion",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            # Remove from exclusion list
            $script:excludedDCs = @($script:excludedDCs | Where-Object { $_ -ne $script:selectedExcludedDC })
            
            # Save the updated exclusion list to configuration file
            Save-Configuration -ExcludedDCs $script:excludedDCs
            
            # Refresh the excluded list display
            & $script:RefreshExcludedList
            
            [System.Windows.Forms.MessageBox]::Show(
                "'$($script:selectedExcludedDC)' will be included in the next scan. Configuration saved.",
                "DC Re-included",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
})

# Password Information Labels
$passwordLabel = New-Object System.Windows.Forms.Label
$passwordLabel.Text = "Password Information:"
$passwordLabel.Location = New-Object System.Drawing.Point(430,170)
$passwordLabel.Size = New-Object System.Drawing.Size(150,20)
$passwordLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 9, [System.Drawing.FontStyle]::Bold)
$passwordLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($passwordLabel)

$passwordLastSetLabel = New-Object System.Windows.Forms.Label
$passwordLastSetLabel.Text = "Last Changed: Not selected"
$passwordLastSetLabel.Location = New-Object System.Drawing.Point(430,190)
$passwordLastSetLabel.Size = New-Object System.Drawing.Size(300,20)
$passwordLastSetLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8)
$passwordLastSetLabel.ForeColor = [System.Drawing.Color]::Black
$form.Controls.Add($passwordLastSetLabel)

$passwordAgeLabel = New-Object System.Windows.Forms.Label
$passwordAgeLabel.Text = "Age: Not selected"
$passwordAgeLabel.Location = New-Object System.Drawing.Point(430,210)
$passwordAgeLabel.Size = New-Object System.Drawing.Size(300,20)
$passwordAgeLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8)
$passwordAgeLabel.ForeColor = [System.Drawing.Color]::Black
$form.Controls.Add($passwordAgeLabel)

# Password Age Legend
$legendLabel = New-Object System.Windows.Forms.Label
$legendLabel.Text = "Password Age Legend:"
$legendLabel.Location = New-Object System.Drawing.Point(10,215)
$legendLabel.Size = New-Object System.Drawing.Size(140,20)
$legendLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8, [System.Drawing.FontStyle]::Bold)
$legendLabel.ForeColor = [System.Drawing.Color]::Black
$form.Controls.Add($legendLabel)

$legendGreen = New-Object System.Windows.Forms.Label
$legendGreen.Text = "■ 0-60 days"
$legendGreen.Location = New-Object System.Drawing.Point(155,215)
$legendGreen.Size = New-Object System.Drawing.Size(75,20)
$legendGreen.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8)
$legendGreen.ForeColor = [System.Drawing.Color]::Green
$form.Controls.Add($legendGreen)

$legendOrange = New-Object System.Windows.Forms.Label
$legendOrange.Text = "■ 61-90 days"
$legendOrange.Location = New-Object System.Drawing.Point(235,215)
$legendOrange.Size = New-Object System.Drawing.Size(85,20)
$legendOrange.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8)
$legendOrange.ForeColor = [System.Drawing.Color]::DarkOrange
$form.Controls.Add($legendOrange)

$legendRed = New-Object System.Windows.Forms.Label
$legendRed.Text = "■ 91+ days"
$legendRed.Location = New-Object System.Drawing.Point(325,215)
$legendRed.Size = New-Object System.Drawing.Size(75,20)
$legendRed.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8)
$legendRed.ForeColor = [System.Drawing.Color]::Red
$form.Controls.Add($legendRed)

$searchButton.Add_Click({
    $userList.Items.Clear()
    $statusGrid.DataSource = $null
    $basicInfoGrid.DataSource = $null
    $statusLabel.Text = "Searching..."
    $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    
    # Disable refresh button during search
    $refreshButton.Enabled = $false
    
    if ([string]::IsNullOrWhiteSpace($textBox.Text)) {
        $statusLabel.Text = "Please enter a search term"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("Please enter a username or name to search for.", "Search Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    Write-Host "Starting search for: '$($textBox.Text)'" -ForegroundColor Cyan
    
    try {
        $users = Search-ADUser -SearchTerm $textBox.Text
        
        if ($users.Count -eq 0) {
            $statusLabel.Text = "No users found matching '$($textBox.Text)'"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
            Write-Host "No users found for search term: '$($textBox.Text)'" -ForegroundColor Yellow
            [System.Windows.Forms.MessageBox]::Show("No users found matching '$($textBox.Text)'.`n`nTry searching with:
• Part of the username (e.g., 'john' for 'john.doe')
• Part of the display name (e.g., 'Smith' for 'John Smith')
• First or last name", "No Results", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        
        $statusLabel.Text = "Found $($users.Count) user(s) - Select one to view details"
        $statusLabel.ForeColor = [System.Drawing.Color]::Green
        Write-Host "Adding $($users.Count) users to list" -ForegroundColor Green
        foreach ($user in $users) {
            $userList.Items.Add("$($user.SamAccountName) - $($user.Name)")
        }
    } catch {
        $statusLabel.Text = "Error during search: $($_.Exception.Message)"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
        Write-Host "Error during search: $($_.Exception.Message)" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show("Error during search: $($_.Exception.Message)", "Search Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Add Enter key support to the textbox
$textBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        $searchButton.PerformClick()
    }
})

$userList.Add_SelectedIndexChanged({
    if ($userList.SelectedItem) {
        $selected = $userList.SelectedItem.ToString().Split(' - ')[0]
        $displayName = $userList.SelectedItem.ToString().Split(' - ', 2)[1]  # Get display name from list
        
        Load-UserInformation -Username $selected -DisplayName $displayName
    }
})

# Refresh button click handler
$refreshButton.Add_Click({
    if ($script:selectedUsername -and $userList.SelectedItem) {
        $selected = $userList.SelectedItem.ToString().Split(' - ')[0]
        $displayName = $userList.SelectedItem.ToString().Split(' - ', 2)[1]
        
        Write-Host "Refreshing data for: $selected" -ForegroundColor Green
        Load-UserInformation -Username $selected -DisplayName $displayName
    } else {
        [System.Windows.Forms.MessageBox]::Show("No user selected. Please select a user first.", "No User Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Unlock All DCs button click handler
$unlockAllButton.Add_Click({
    if ($script:selectedUsername) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "This will attempt to unlock the account '$($script:selectedUsername)' on ALL domain controllers.`n`nDo you want to continue?",
            "Confirm Unlock on All DCs",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $statusLabel.Text = "Unlocking account on all DCs..."
            $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
            $statusLabel.Refresh()
            $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
            
            try {
                Import-Module ActiveDirectory -ErrorAction Stop
                
                # Get all DCs (including excluded ones for unlock operation)
                $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                $allDCs = $domain.DomainControllers
                
                $successCount = 0
                $failedDCs = @()
                
                Write-Host "Unlocking account '$($script:selectedUsername)' on all DCs..." -ForegroundColor Cyan
                
                foreach ($dc in $allDCs) {
                    $dcName = $dc.Name
                    try {
                        Write-Host "  Attempting unlock on $dcName..." -ForegroundColor Gray
                        Unlock-ADAccount -Identity $script:selectedUsername -Server $dcName -ErrorAction Stop
                        $successCount++
                        Write-Host "  ✓ Success on $dcName" -ForegroundColor Green
                    } catch {
                        $failedDCs += "$dcName : $($_.Exception.Message)"
                        Write-Host "  ✗ Failed on $dcName : $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                
                $form.Cursor = [System.Windows.Forms.Cursors]::Default
                
                # Build result message
                $message = "Unlock operation completed:`n`n"
                $message += "✓ Successfully unlocked on $successCount of $($allDCs.Count) DCs"
                
                if ($failedDCs.Count -gt 0) {
                    $message += "`n`n✗ Failed on $($failedDCs.Count) DC(s):`n"
                    foreach ($failed in $failedDCs) {
                        $message += "  • $failed`n"
                    }
                }
                
                $iconType = if ($failedDCs.Count -eq 0) { 
                    [System.Windows.Forms.MessageBoxIcon]::Information 
                } else { 
                    [System.Windows.Forms.MessageBoxIcon]::Warning 
                }
                
                [System.Windows.Forms.MessageBox]::Show(
                    $form,
                    $message,
                    "Unlock Results",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    $iconType
                )
                
                # Refresh the display to show updated lockout status
                if ($userList.SelectedItem) {
                    $selected = $userList.SelectedItem.ToString().Split(' - ')[0]
                    $displayName = $userList.SelectedItem.ToString().Split(' - ', 2)[1]
                    Load-UserInformation -Username $selected -DisplayName $displayName
                }
                
            } catch {
                $form.Cursor = [System.Windows.Forms.Cursors]::Default
                $statusLabel.Text = "Error during unlock operation"
                $statusLabel.ForeColor = [System.Drawing.Color]::Red
                [System.Windows.Forms.MessageBox]::Show(
                    $form,
                    "Error during unlock operation: $($_.Exception.Message)",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("No user selected. Please select a user first.", "No User Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Removed $form.Topmost = $true to allow normal window switching
[void]$form.ShowDialog()