# Powershell

## Description
Useful PowerShell scripts for administrating on-premises and Azure cloud resources

## Scripts

### Active Directory
- [Copy-ADMemberships](./Active-Directory/Copy-ADMemberships.ps1)
Copies memberships from one Active Directory user to another, with user interaction.

### Azure
- [Get-AzureAppPermissionReport](./Azure/Get-AzureAppPermissionReport.ps1)
Audits and reports on permissions associated with Azure Active Directory applications and their corresponding service principals.
- [Get-EXOMailboxDiscrepancies](./Azure/Get-EXOMailboxDiscrepancies.ps1)
Lists Active Directory on-premises accounts with missing Exchange Online mailboxes and orphaned EXO mailboxes.

### General Utilities
- [Save-AclPermissions](./General%20Utilities/Save-ACLPermissions.ps1)
Collects and saves security permissions for a specified folder, subfolders and (optionally) all sub-items.

## License
MIT License

