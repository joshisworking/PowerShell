<#
.SYNOPSIS
    Audits and reports on permissions associated with Azure Active Directory applications and their corresponding service principals.

.DESCRIPTION
    This script retrieves information about permissions granted by one application to another (resource apps) and organizes this data into a report.

.EXAMPLE
3. Run the script:
    PS C:\> .\Get-AzureAppPermissionReport.ps1

.NOTES
    Author: Joshua Dodd
    Date: 31 August 2023

    - Requires elevated PowerShell session.
    - To install the required Az module:
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
#>
function Get-AzureAppPermissionReport {
    [CmdletBinding()]
    param (
        [string] $ReportPath = "$env:USERPROFILE\Desktop\",
        [string] $ReportName = "AppRegistrationPermissionReport",
        [string] $WorksheetName = "AppPermissions"
    )

    
    # Attempt AzAccount connection
    try {
        Connect-AzAccount -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to connect to Azure Account. Please check your Az module installation and credentials."
        return
    }

    # Get all Azure Active Directory applications
    $apps = Get-AzADApplication

    # Empty array to store the report output
    $appReport = @()

    # Hashtable to keep track of already retrieved resource service principals
    $servicePrincipleMap = @{}

    # Progress varliables
    $progressCount = 0
    $totalCount = $apps.Count 

    # Loop through each application in the list
    foreach ($app in $apps) {
        # Update progress bar
        $progressCount++
        $progressPercent = ($progressCount / $totalCount) * 100
        Write-Progress -PercentComplete $progressPercent -Status "Processing Applications" -Activity "Processing $($app.DisplayName)" 

        # Loop through the list of required resource accesses for the application
        foreach ($requiredResourceAccess in $app.RequiredResourceAccess) {
            $resourceAppId = $requiredResourceAccess.ResourceAppId

            # If the service principal for the resource app is not already retrieved, fetch it
            if (!$servicePrincipleMap.ContainsKey($requiredResourceAccess.ResourceAppId)) {
                $servicePrincipleMap[$resourceAppId] = Get-AzADServicePrincipal -ApplicationId $resourceAppId | 
                Select-Object AppId, AppRole, DisplayName, Oauth2PermissionScope
            }

            # Loop through each resource access entry within the required resource access
            foreach ($resourceAccess in $requiredResourceAccess.ResourceAccess) {
                # Check if the resource access is of type "Scope"
                if ($resourceAccess.Type -eq "Scope") {
                    # Retrieve the corresponding permission from the OAuth2PermissionScope list
                    $permission = $servicePrincipleMap[$resourceAppId].Oauth2PermissionScope |
                    Where-Object { $_.Id -eq $resourceAccess.Id } |
                    Select-Object Id, Value, AdminConsentDescription

                    # Add the gathered information to the report array
                    $appReport += [PSCustomObject]@{
                        "App Name"                 = $app.DisplayName
                        "App Id"                   = $app.Id
                        "Service Principle Name"   = $servicePrincipleMap[$resourceAppId].DisplayName
                        "Service Principle App Id" = $servicePrincipleMap[$resourceAppId].AppId
                        "Resource Access Id"       = $resourceAccess.Id
                        "Permission Type"          = $resourceAccess.Type
                        "Permission Value"         = $permission.Value
                        "Permission Description"   = $permission.AdminConsentDescription
                    }
                }
                # Check if the resource access is of type "Role"
                elseif ($resourceAccess.Type -eq "Role") {
                    # Retrieve the corresponding permission from the AppRole list
                    $permission = $servicePrincipleMap[$resourceAppId].AppRole |
                    Where-Object { $_.Id -eq $resourceAccess.Id } | 
                    Select-Object Id, Value, Description

                    # Add the gathered information to the report array
                    $appReport += [PSCustomObject]@{
                        "App Name"                 = $app.DisplayName
                        "App Id"                   = $app.Id
                        "Service Principle Name"   = $servicePrincipleMap[$resourceAppId].DisplayName
                        "Service Principle App Id" = $servicePrincipleMap[$resourceAppId].AppId
                        "Resource Access Id"       = $resourceAccess.Id
                        "Permission Type"          = $resourceAccess.Type
                        "Permission Value"         = $permission.Value
                        "Permission Description"   = $permission.Description
                    }
                }
            }
        }
    }

    # Export the report array to an Excel file
    $ReportPath += "$ReportName $(Get-Date -Format 'yyyyMMdd').xlsx"
    $appReport | Export-Excel -Path $reportPath -WorksheetName $WorksheetName -TableName "AppReport" -BoldTopRow -AutoSize
    Write-Host "The report can be found at $ReportPath" -ForegroundColor Yellow

    # Disconnect from the AzAccount session
    Disconnect-AzAccount
}

Get-AzureAppPermissionReport