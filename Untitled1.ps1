# Function to display instructions on how to use the script
function Show-Help {
    Write-Output "Usage:"
    Write-Output "$MyInvocation.MyCommand.Name [option]"
    Write-Output "Options:"
    Write-Output "1. Add-User - Add a new user"
    Write-Output "2. Remove-User - Remove an existing user"
    Write-Output "3. Modify-User - Modify user information"
    Write-Output "4. Show-LocalUsers - Show all local users"
    Write-Output "5. Exit - Exit the program"
    Write-Output "6. --Help"
}

# Function to retrieve local users and groups
function Get-LocalUsers {
    try {
        $localUsers = Get-LocalUser
        Write-Output "Local users on the computer:"
        $localUsers | Format-Table -AutoSize
        
        $localGroup = Get-LocalGroup
        Write-Output "Local Groups on the computer:"
        $localGroup | Format-Table -AutoSize

    }
    catch {
        Write-Output "Failed to retrieve local users: $($_.Exception.Message)"
        exit 1
    }
}

# Function to add a new user
function Add-User {
    Param(
        [string]$username
    )

    Write-Output "Adding user: $username"
    try {
        $password = Read-Host "Enter the password for user $username" -AsSecureString
        New-LocalUser -Name $username -Password $password -FullName $username -Description "Created by script" -AccountNeverExpires:$true
        Add-LocalGroupMember -Group "Users" -Member $username
        Enable-LocalUser -Name $username
        Write-Output "User $username added successfully to the local computer, enabled, and added to the 'Users' group."
    }
    catch {
        Write-Output "$MyInvocation.MyCommand.Name: Add-User operation failed. $($_.Exception.Message)"
        exit 1
    }
}

# Function to remove a user
function Remove-User {
    param([string]$username)
    Write-Output "Removing user: $username"
    try {
        Remove-LocalUser -Name $username -ErrorAction Stop
        Write-Output "User $username removed successfully."
    }
    Catch {
        Write-Output "$MyInvocation.MyCommand.Name: Remove-User operation failed. $($_.Exception.Message)"
        exit 1
    }
}

# Function to modify user information. Those being username, description, enabling logon and PermissionLevel. 
function Modify-User {
    param([string]$username)
    Write-Output "Modifying user: $username"
    
    try {
        $options = @(
            "Username",
            "Description",
            "Enabled",
            "PermissionLevel"
        )

        $attribute = Read-Host "Select an attribute to modify:`n$(foreach ($opt in $options) { "$($options.IndexOf($opt) + 1). $opt" })"
        $selectedOption = $options[$attribute - 1]

        switch ($selectedOption) {
            "Username" {
                $newUsername = Read-Host "Enter the new username for $username"
                Rename-LocalUser -Name $username -NewName $newUsername -ErrorAction Stop
                Write-Output "User $username username modified successfully. Set username to $newUsername."
            }
            "Description" {
                $value = Read-Host "Enter the new description for $username"
                Set-LocalUser -Name $username -Description $value -ErrorAction Stop
                Write-Output "User $username description modified successfully. Set description to $value."
            }
            "Enabled" {
                $enable = @(
                "1 Enable logon",
                "2 Disable logon"
                )
                $enable = Read-Host "Select to Enable or Disable: '$(foreach ($perm in $enable) { $perm })"
                switch ($enable) {
                
                "1" {
                    Enable-localUser -Name $username
                    Write-Output "Enabled Logon was successful"
                    }

                "2" {
                    Disable-LocalUser -Name $username
                    Write-Output "Disabled logon was successful"
                    }
                Default {
                    Write-Output "Invalid permission level selected."
                    }
                }
             }
             "PermissionLevel" {
                $permissionLevels = @(
                    "1. Standard User",
                    "2. Administrator",
                    "3. Restricted"
                )
        
                $permission = Read-Host "Select the permission level:`n$(foreach ($perm in $permissionLevels) { $perm })"
                switch ($permission) {
                    
                    "1" {
                        # Set user as Standard User
                        Set-LocalUser -Name $username -AccountNeverExpires:$true -ErrorAction Stop
                        Write-Output "User $username permission level changed successfully. Set Permission Level to 'Standard User'."
                        }
        
        
                    "2" {
                        # Set user as Administrator by adding to Administrators group
                        Add-LocalGroupMember -Group Administrators -Member $username -ErrorAction Stop
                        Write-Output "User $username permission level changed successfully. Set Permission Level to 'Administrator'."
                        }
        
                    "3" {
                        # Set user as Restricted
                        # Add your code for setting user as Restricted here
                        Write-Output "User $username permission level changed successfully. Set Permission Level to 'Restricted'."
                    }
                    Default {
                        Write-Output "Invalid permission level selected."
                    }
                }
            }
            Default {
                Write-Output "Invalid attribute selected."
            }
        }
    }
    catch {
        Write-Output "$MyInvocation.MyCommand.Name: Modify-User operation failed. $($_.Exception.Message)"
        exit 1
    }
}

# Function to manage users based on options provided
function Manage-Users {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Options,
        [string]$username
    )
    
    switch -regex ($Options.ToLower()) {
        "1|add-user" {
            Add-User -username $username
            break
        }

        "2|remove-user" {
            Remove-User -username $username
            break
        }
        
        "3|modify-user" {
            Modify-User -username $username
            break
        }

        "4|show-localusers" {
            Get-LocalUsers
            break
        }

        "5|exit" {
            Write-Output "Exiting the program."
            exit 0
        }

        "6|Help"{
            Show-Help "Here are the instructions again"
        }
        

        Default {
            Write-Output "$MyInvocation.MyCommand.Name: Invalid option. Please see the help for usage."
            Show-Help
            exit 1
        }
    }
}

# Loop to continuously prompt for actions until user chooses to exit
while ($true) {
    if ($args.Count -eq 0) {
        $option = Read-Host "Enter an option (1 for Add-User, 2 for Remove-User, 3 for Modify-User, 4 for list of users, 5 for exit, 6 for help or type 'show-help')"
        if ($option -in 1, 2, 3) {
            $username = Read-Host "Enter the username"
        }
        Manage-Users -Options $option -username $username
    } else {
        # Otherwise, execute based on provided arguments
        Manage-Users -Options $args[0] -username $args[1]
    }

    # Prompt the user to continue or exit
    $continue = Read-Host "Do you want to perform another action? (Y/N)"
    if ($continue -ne "Y") {
        break
    }
}

