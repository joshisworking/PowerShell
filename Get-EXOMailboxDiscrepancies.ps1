<#
.SYNOPSIS
    Lists Active Directory on-premises accounts with missing Exchange Online mailboxes and orphaned EXO mailboxes

.DESCRIPTION
    In a hybrid environment, inadvertent changes in Active Directory can lead to permanent mailbox deletions in Exchange Online. 
    This script helps identify discrepancies and ensures that every user has a corresponding mailbox and helps prevent data loss due to inadvertent actions.
    It also identifies and lists cloud-only mailboxes as a point of reference.
    This script should be run at least every two weeks since deleted mailboxes are recoverable within 30 days of being marked for deletion. 
    
.EXAMPLE
    PS C:\> .\Get-MissingEXOMailboxes.ps1

        Step 1: Retrieving users from Active Directory
        ------------------------------------------------------------
        Retrieving all users from Active Directory
        Total users retrieved from Active Directory: 150

        Step 2: Retrieving mailboxes from Exchange Online
        ------------------------------------------------------------
        Total mailboxes retrieved from Exchange Online: 175

        Step 3: Checking for missing mailboxes
        ------------------------------------------------------------
        Total user accounts missing mailboxes: 12

        Identity
        --------
        CN=John Doe,OU=Users,DC=contoso,DC=com
        CN=Alice Smith,OU=Users,DC=contoso,DC=com
        ...

        ------------------------------------------------------------

        Step 4: Checking for mailboxes without user accounts
        ------------------------------------------------------------
        Total mailboxes without corresponding user accounts: 7

        Identity
        --------
        john.doe@contoso.com
        alice.smith@contoso.com
        ...

    PS C:\>

.NOTES
    Author: Josh Dodd
    Date: 12 October 2023
    Prerequisites: 
    1. The Exchange Recipient Administrator role must be activated in Azure
    2. This script must be run from an elevated PowerShell session.
    3. The ExchangeOnlineManagement module must be installed for the local PowerShell instance
#>
function Get-EXOMailboxDiscrepancies {

    # Check if the Connect-ExchangeOnline function is available
    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        Write-Warning "The ExchangeOnlineManagement module is not available. Please install it before running this script."
        Write-Output "To install the module, open a PowerShell session as an administrator and run the following command:"
        Write-Output "Install-Module -Name ExchangeOnlineManagement"
        exit
    }

    # Attempt to connect to Exchange Online
    try {
        # Update the UserPrincipalName to your Azure admin username and uncomment rest of line for quicker login
        Connect-ExchangeOnline # -UserPrincipalName josh.
    }
    catch {
        Write-Warning "Error connecting to Exchange Online: $_"
        Write-Output "Please ensure you have the Exchange Online Management Module installed and correctly configured."
        exit
    }

    # Output a message to inform the user that we are retrieving users from Active Directory
    Write-Output "Step 1: Retrieving users from Active Directory"
    Write-Output "------------------------------------------------------------"
    Write-Output "Retrieving all users from Active Directory"
    # Get all users from Active Directory within the specified OU and filter out those with no targetAddress property
    $allUsersFromAD = Get-ADUser -Filter * -Properties targetAddress | Where-Object { $null -ne $_.targetAddress }
    Write-Output "Total users retrieved from Active Directory: $($allUsersFromAD.Count)`n"

    # Output a message to inform the user that we are retrieving mailboxes from Exchange Online
    Write-Output "Step 2: Retrieving mailboxes from Exchange Online"
    Write-Output "------------------------------------------------------------"
    # Get all mailboxes from Exchange Online without any limitations
    $allMailboxesFromEXO = Get-EXOMailbox -ResultSize Unlimited
    Write-Output "Total mailboxes retrieved from Exchange Online: $($allMailboxesFromEXO.Count)`n"

    # Check for user accounts that don't have a corresponding mailbox
    Write-Output "Step 3: Checking for missing mailboxes"
    Write-Output "------------------------------------------------------------"
    $missingMailboxes = @()
    foreach ($userFromAD in $allUsersFromAD) {
        if (!($userFromAD.userprincipalname -in $allMailboxesFromEXO.UserPrincipalName)) {
            $missingMailboxes += $userFromAD
        }
    }

    # Output the number of user accounts missing mailboxes and list their identities
    Write-Output "Total user accounts missing mailboxes: $($missingMailboxes.Count)"
    $missingMailboxes | Select-Object Identity
    Write-Output "------------------------------------------------------------`n"

    # Check for mailboxes without corresponding user accounts
    Write-Output "Step 4: Checking for mailboxes without user accounts"
    Write-Output "------------------------------------------------------------"
    $orphanedMailboxes = @()
    foreach ($mailboxFromEXO in $allMailboxesFromEXO) {
        if (!($mailboxFromEXO.userprincipalname -in $allUsersFromAD.UserPrincipalName)) {
            $orphanedMailboxes += $mailboxFromEXO
        }
    }

    # Output the number of mailboxes without corresponding user accounts and list their identities
    Write-Output "Total mailboxes without corresponding user accounts: $($orphanedMailboxes.Count)"
    $orphanedMailboxes | Select-Object Identity
}

Get-EXOMailboxDiscrepancies