<#
.SYNOPSIS
    Copies direct reports from one Active Directory user to another.

.DESCRIPTION
    This PowerShell function copies direct reports from a source Active Directory user to a destination user.

.PARAMETER Source
    Specifies the source Active Directory user account Identity from which group memberships will be copied.
    Valid inputs include 1) A distinguished name, 2) A GUID (objectGUID), 3) A security identifier (objectSid), or 4) A SAM account name (sAMAccountName) 
    This parameter is mandatory.

.PARAMETER Destination
    Specifies the destination Active Directory user account Identity from which group memberships will be copied.
    Valid inputs include 1) A distinguished name, 2) A GUID (objectGUID), 3) A security identifier (objectSid), or 4) A SAM account name (sAMAccountName) 
    This parameter is mandatory.

.EXAMPLE
    Copy-Memberships -Source <ADUser Identity> -Destination <ADUser Identity>

.NOTES
    Author: Josh Dodd
    Last update: 4 December 2023

    To use this function, make sure you are running it in an environment with Active Directory cmdlets available.
#>

function Copy-DirectReport {
    Param(
        [Parameter (Mandatory)]
        [string]$Source, 

        [Parameter (Mandatory)]
        [string]$Destination
    )
    
    # Obtain the source user, end operation and show error if failed
    try {
        [Microsoft.ActiveDirectory.Management.ADAccount]$sourceManager = Get-ADUser $Source -Properties directReports -ErrorAction Stop
    }
    catch {
        Write-Error "Error: Unable to obtain Source AD User. Please check that name is correct."
        return
    }

    # Obtain the destination user, end operation and show error if failed
    try {
        [Microsoft.ActiveDirectory.Management.ADAccount]$destinationManager = Get-ADUser $Destination -ErrorAction Stop
    }
    catch {
        Write-Error "Error: Unable to obtain Destination AD User. Please check that name is correct."
        return
    }

    # If no direct reports, write message and end operation
    $reports = $sourceManager | Select-Object -ExpandProperty directReports
    if ($reports.Count -eq 0) {
        Write-Output "No direct reports found for source user. Terminating."
        return
    }

    # Print current activity 
    Write-Output "Reassigning direct reports from $($sourceManager.Name) to $($destinationManager.Name)"
    Write-Output "----------------------------------------------------------"
    
    # Set destination user as the manager for all direct reports. 
    # Success/Fail count will be incremented as manager is set for reports
    $successCount = 0
    $failedCount = 0
    foreach ($person in $reports) {
        try {
            Set-ADUser $person -Manager $destinationManager -ErrorAction Stop
            Write-Output "Manager successfully updated for: $person"
            $successCount += 1
        }
        catch {
            Write-Warning "Could not update manager for $person"
            $failedCount += 1
        }
    }

    Write-Output "`n------------------------------------"
    Write-Output "Operation complete."
    Write-Output "------------------------------------"
    Write-Output "Direct reports total count: $($reports.Count)"
    Write-Output "Direct reports moved: $successCount."
    Write-Output "Direct reports failed: $failedCount"
}

