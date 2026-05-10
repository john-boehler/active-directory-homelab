# Phase 4.4 - Apply Domain Local groups to folder NTFS permissions
# Each subfolder gets its corresponding DL_*_Modify group with Modify rights
# Parent gets Domain Users with Read+Execute (this folder only) for traversal

$Mapping = @(
    @{Folder="C:\CompanyData\Accounting"; DL="DL_Accounting_Modify"},
    @{Folder="C:\CompanyData\Executives"; DL="DL_Executives_Modify"},
    @{Folder="C:\CompanyData\HR";         DL="DL_HR_Modify"},
    @{Folder="C:\CompanyData\IT";         DL="DL_IT_Modify"},
    @{Folder="C:\CompanyData\Marketing";  DL="DL_Marketing_Modify"},
    @{Folder="C:\CompanyData\Public";     DL="DL_Public_Modify"},
    @{Folder="C:\CompanyData\Sales";      DL="DL_Sales_Modify"}
)

# Step 1: Apply DL groups to each subfolder
foreach ($M in $Mapping) {
    $Folder   = $M.Folder
    $DLFull   = "HOMELAB\$($M.DL)"

    Write-Host "`n=== Granting Modify on $Folder to $DLFull ===" -ForegroundColor Cyan
    
    $Acl  = Get-Acl $Folder
    $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $DLFull,
        "Modify",
        "ContainerInherit,ObjectInherit",   # apply to subfolders + files
        "None",                              # propagation flag (no special)
        "Allow"
    )
    $Acl.AddAccessRule($Rule)
    Set-Acl -Path $Folder -AclObject $Acl
    Write-Host "  OK" -ForegroundColor Green
}

# Step 2: Parent traversal for Domain Users
Write-Host "`n=== Granting traversal on C:\CompanyData to Domain Users ===" -ForegroundColor Cyan
$ParentAcl = Get-Acl "C:\CompanyData"
$TraversalRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "HOMELAB\Domain Users",
    "ReadAndExecute",
    "None",          # InheritanceFlags=None: this folder only, no propagation
    "None",          # PropagationFlags
    "Allow"
)
$ParentAcl.AddAccessRule($TraversalRule)
Set-Acl -Path "C:\CompanyData" -AclObject $ParentAcl
Write-Host "  OK" -ForegroundColor Green

Write-Host "`nAGDLP applied. Run the audit to verify." -ForegroundColor Cyan