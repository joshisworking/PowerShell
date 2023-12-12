<#
.SYNOPSIS
    Copies memberships from one Active Directory user to another, with user interaction.

.DESCRIPTION
    This PowerShell function copies group memberships from a source Active Directory user to a destination user.
    It provides for interactive selection, allowing the user to choose which groups to copy.
    The process is logged to a transcript file.

.PARAMETER Source
    Specifies the source Active Directory user account from which group memberships will be copied.
    This parameter is mandatory.

.PARAMETER Destination
    Specifies the destination Active Directory user account to which group memberships will be copied.
    This parameter is mandatory.

.EXAMPLE
    Copy-Memberships -Source (Get-ADUser "SourceUser") -Destination (Get-ADUser "DestinationUser")

.NOTES
    Author: Josh Dodd
    Last update: 12 July 2023

    The transcript file will be saved on the desktop with a filename containing the destination user's name and the current date.

    To use this function, make sure you are running it in an environment with Active Directory cmdlets available.
#>

function Copy-ADMembership {
    Param(
        [Parameter (Mandatory = $True)]
        [Microsoft.ActiveDirectory.Management.ADAccount]$Source, 

        [Parameter (Mandatory = $True)]
        [Microsoft.ActiveDirectory.Management.ADAccount]$Destination
    )
    
    #Begin transcript
    $today = Get-Date
    $transcriptPath = "$env:USERPROFILE\Desktop\" + $Destination.SamAccountName + "_COPY-MEMBERSHIPS-LOG_" + $today.ToShortDateString() + ".log"
    try {
        Start-Transcript -Path $transcriptPath
    }
    catch {
        Write-Error "Transcript could not be started. Cancelling process."
        return
    }
    
    Write-Output "SOURCE:`r`n $($Source.Name)"
    Write-Output "DESTINATION:`r`n$($Destination.Name)"

    # Get the memberof for Source if not included in Object passed in
    if (!$Source.memberof) {
        $Source = Get-ADUser -Identity $Source.ObjectGuid -Properties memberof
    }
    Write-Output "`r`nGetting memberships of $($Source.Name)"
    $memberships = $Source.memberof

    # Write groups user is already a member
    Write-Output "`r`n$($Destination.Name) is already part of the following groups:`r`n"
    $Destination = Get-ADUser -Identity $Destination.ObjectGuid -Properties memberof # Get current memberships of Destination user
    $dGroups = $Destination.memberof # Save memberships
    Write-Output $dGroups
        
    # Iterate through memberships, adding restricted groups to collection without adding
    $restrictedGroups = foreach ($group in $memberships) {
        if ($dGroups -notcontains $group) { 

            $reply = Read-Host "`r`n$g`r`nWould you like to add this group? (y/n)"
            if ($reply -eq 'Y' -or $reply -eq 'y') {
                Add-ADGroupMember -Identity $group -Members $Destination -Verbose
            }
            else {
                Get-ADGroup -Identity $group -Properties Description, info | Select-Object Name, Description, info
            }
        }
    }

    #Write list of rejected groups
    Write-Output "`r`nGroups Not Added:"
    foreach ($g in $restrictedGroups) {
        Write-Host "Name: " $g.Name
        Write-Host "Description: " $g.Description
        Write-Host "Info: " $g.Info "`r`n"
    }
      
    #End transcript
    Stop-Transcript
}
