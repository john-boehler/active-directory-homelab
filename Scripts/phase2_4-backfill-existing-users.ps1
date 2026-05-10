# Phase 2.4 - Backfill manually-created users with missing attributes
# Targets users created before the bulk script ran

$DomainName = (Get-ADDomain).DNSRoot

$Backfill = @(
    @{Sam="aketchum";    Department="Accounting"},
    @{Sam="wgates";      Department="HR"},
    @{Sam="eshackleton"; Department="IT"}
)

foreach ($U in $Backfill) {
    $Sam = $U.Sam
    $User = Get-ADUser -Identity $Sam -Properties Department, EmailAddress -ErrorAction SilentlyContinue
    if (-not $User) {
        Write-Host "SKIP: $Sam not found" -ForegroundColor Yellow
        continue
    }

    $Email = "$Sam@$DomainName"

    Set-ADUser -Identity $Sam `
               -Department $U.Department `
               -EmailAddress $Email

    # Make sure they're in the department group
    $InGroup = Get-ADGroupMember -Identity $U.Department | 
               Where-Object { $_.SamAccountName -eq $Sam }
    if (-not $InGroup) {
        Add-ADGroupMember -Identity $U.Department -Members $Sam
        Write-Host "OK: $Sam updated + added to $($U.Department) group" -ForegroundColor Green
    } else {
        Write-Host "OK: $Sam updated (already in $($U.Department) group)" -ForegroundColor Green
    }
}