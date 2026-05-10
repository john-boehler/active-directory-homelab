# Phase 4.2 - Tear down domain ACEs across CompanyData and subfolders
# Removes all HOMELAB\* entries; preserves Administrators, SYSTEM, CREATOR OWNER
# Disables inheritance on subfolders (preserves inherited entries as explicit)

$ParentPath = "C:\CompanyData"
$Subfolders = Get-ChildItem $ParentPath -Directory

# ---------- Clean each subfolder ----------
foreach ($Folder in $Subfolders) {
    Write-Host "`n=== Cleaning $($Folder.FullName) ===" -ForegroundColor Cyan
    
    # Step 1: Disable inheritance, preserve inherited entries as explicit
    $Acl = Get-Acl $Folder.FullName
    $Acl.SetAccessRuleProtection($true, $true)
    Set-Acl -Path $Folder.FullName -AclObject $Acl
    
    # Step 2: Reload and remove all HOMELAB\* ACEs
    $Acl = Get-Acl $Folder.FullName
    $RulesToRemove = $Acl.Access | Where-Object { $_.IdentityReference -like "HOMELAB\*" }
    
    if (-not $RulesToRemove) {
        Write-Host "  (no HOMELAB ACEs found)" -ForegroundColor Gray
    } else {
        foreach ($Rule in $RulesToRemove) {
            $Acl.RemoveAccessRule($Rule) | Out-Null
            Write-Host "  Removed: $($Rule.IdentityReference) ($($Rule.FileSystemRights))" -ForegroundColor Yellow
        }
        Set-Acl -Path $Folder.FullName -AclObject $Acl
    }
    Write-Host "  Done." -ForegroundColor Green
}

# ---------- Clean the parent ----------
Write-Host "`n=== Cleaning $ParentPath (parent) ===" -ForegroundColor Cyan
$ParentAcl = Get-Acl $ParentPath
$ParentRulesToRemove = $ParentAcl.Access | Where-Object { $_.IdentityReference -like "HOMELAB\*" }

if (-not $ParentRulesToRemove) {
    Write-Host "  (no HOMELAB ACEs found)" -ForegroundColor Gray
} else {
    foreach ($Rule in $ParentRulesToRemove) {
        $ParentAcl.RemoveAccessRule($Rule) | Out-Null
        Write-Host "  Removed: $($Rule.IdentityReference) ($($Rule.FileSystemRights))" -ForegroundColor Yellow
    }
    Set-Acl -Path $ParentPath -AclObject $ParentAcl
}
Write-Host "  Done." -ForegroundColor Green

Write-Host "`nTear down complete. Run the audit to verify clean state." -ForegroundColor Cyan