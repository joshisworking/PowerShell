# Powershell

## Description
Useful PowerShell scripts and functions for administrating Active Directory and Azure cloud resources. 

## Usage 
Scripts are designed to execute by running the file:

    PS> Path\To\ScriptName.ps1

Functions can be loaded to a PowerShell session by dot-sourcing the file and calling the function:

    PS> . Path\To\FunctionName.ps1
    PS> FunctionName -Arguments $true

## Contents

### Active Directory
- [Copy-ADMemberships](./Active-Directory/Copy-ADMemberships.ps1)
Function. Copies memberships from one Active Directory user to another, with user interaction.
- [Copy-DirectReports](./Active-Directory/Copy-DirectReports.ps1)
Function. Copies direct reports from one Active Directory user to another, replacing previous manager.

### Azure
- [Get-AzureAppPermissionReport](./Azure/Get-AzureAppPermissionReport.ps1)
Script. Audits and reports on permissions associated with Azure Active Directory applications and their corresponding service principals.
- [Get-EXOMailboxDiscrepancies](./Azure/Get-EXOMailboxDiscrepancies.ps1)
Script. Lists Active Directory on-premises accounts with missing Exchange Online mailboxes and orphaned EXO mailboxes.

### General Utilities
- [Save-AclPermissions](./General%20Utilities/Save-ACLPermissions.ps1)
Function. Collects and saves security permissions for a specified folder, subfolders and (optionally) all sub-items.

## License
MIT License

