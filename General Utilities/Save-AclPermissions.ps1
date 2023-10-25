<#
.SYNOPSIS
Collects and saves security permissions for a specified folder, subfolders and (optionally) all sub-items. The collected data includes information about item paths, ownership, and access rights.

.DESCRIPTION
The Save-ACLPermissions function allows you to inspect the security permissions of a folder and its sub-items. It recursively explores the folder structure, creating an object for each item that includes its path, owner, group, access rights, and SDDL (Security Descriptor Definition Language). You can choose to display the collected data to the console, export it to a CSV file, or save it as JSON. The function provides flexibility in specifying the folder path to inspect, the export path for saving the collected permissions, and the output format.

.PARAMETER FolderPath
Specifies the path of the folder to inspect for security permissions. If not provided, the function will default to the current location.

.PARAMETER ExportPath
Specifies the path for exporting the collected security permissions to a CSV file or JSON file. If this parameter is omitted, the function will display the results in an Out-GridView window. Either the -JSON or -CSV switch is required if using this parameter.

.PARAMETER IncludeFiles
If specified, the function will include files in the inspection process, which may be time-consuming for large folders. If not specified, only directories will be included.

.PARAMETER JSON
If specified, the collected access rights will be returned as a JSON file. If used in conjunction with -ExportPath, it will be saved to a file.

.PARAMETER CSV
If specified, the collected access rights will be saved as a CSV file. Requires the -ExportPath parameter to specify the output file.

.NOTES
File Name      : Save-ACLPermissions.ps1
Author         : Josh Dodd
Prerequisite   : PowerShell

.EXAMPLE
# Collect security permissions for the current directory, including files, and display results in an Out-GridView window.
Save-ACLPermissions -IncludeFiles

.EXAMPLE
# Collect security permissions for a specified folder, export the results to a CSV file, and display results for directories only.
Save-ACLPermissions -FolderPath "C:\MyFolder" -ExportPath "C:\Permissions.csv"

.EXAMPLE
# Collect security permissions for a specific folder, save the results as JSON, and display the results for directories only.
Save-ACLPermissions -FolderPath "D:\AnotherFolder" -JSON

#>

function Save-AclPermissions {
    [CmdletBinding()]
    param (
        [string] 
        $FolderPath = (Get-Location).Path,
        
        [string]
        $ExportPath,

        [switch]
        $IncludeFiles,

        [switch]
        $JSON,

        [switch]
        $CSV
    )

    if ($ExportPath) {
        # If ExportPath is provided, either JSON or CSV must be specified
        if (-not ($JSON -or $CSV)) {
            Write-Error "You must specify either -JSON or -CSV when providing -ExportPath."
            return
        }
    }

    # Enqueue current folder and all sub-items
    $queue = New-Object System.Collections.Queue
    $queue.Enqueue($FolderPath)

    if ($IncludeFiles) {
        Write-Host "Getting access controls for all file can be time consuming in large folders. If this takes too long, cancel the operation and try without -IncludeFiles" -ForegroundColor DarkYellow
        foreach ($item in Get-ChildItem -Path $FolderPath -Recurse) {
            $queue.Enqueue($item.FullName)
        }
    }
    else {
        foreach ($item in Get-ChildItem -Path $FolderPath -Directory -Recurse) {
            $queue.Enqueue($item.FullName)
        }
    }


    # Initialize an array to store the permission objects
    $allPermissions = @()

    # Count the total number of items to process
    $totalItemCount = $queue.Count

    # Initialize the progress count
    $progressCount = 0

    # While there are items in the queue, process them
    while ($queue.Count -gt 0) {
        $item = $queue.Dequeue()
    
        # Get and save the ACL for the current item
        $acl = Get-Acl -Path $item.ToString()
        
        # Export Access as object if JSON, else as string
        if ($JSON) {
            $accessOutput = $acl.Access
        }
        else {
            $accessOutput = $acl.AccessToString
        }

        $permissionObject = New-Object PSObject -Property @{
            Path   = $item
            Owner  = $acl.Owner
            Group  = $acl.Group
            Access = $accessOutput
            Sddl   = $acl.Sddl
        }

        $allPermissions += $permissionObject

        # Update the progress bar
        $progressCount++
        $progressStatus = [math]::Round(($progressCount / $totalItemCount) * 100)
        Write-Progress -Id 1 -Activity "Collecting Permissions" -Status "$($queue.Count) items remaining" -PercentComplete $progressStatus
    }

    # Complete the progress bar
    Write-Progress -Id 1 -Activity "Collecting Permissions" -Status "Completed" -PercentComplete 100

    # Export if provided an ExportPath, else display results

    if ($ExportPath -and $JSON) {
        if ($ExportPath -notlike '*.json') {
            $ExportPath += '.json'
        }
        $allPermissions | ConvertTo-Json -Depth 4 | Out-File -FilePath $ExportPath 
    }
    elseif ($ExportPath -and $CSV) {
        if ($ExportPath -notlike '*.csv') {
            $ExportPath += '.csv'
        }
        $allPermissions | Export-Csv -Path $ExportPath -NoTypeInformation
    }
    elseif ($JSON) {
        $allPermissions | ConvertTo-Json -Depth 4 
    }
    else {
        $allPermissions
    }

}