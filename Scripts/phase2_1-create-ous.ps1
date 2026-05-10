# Phase 2.1 - Create OU structure under USA
# Idempotent: skips OUs that already exist

$DomainDN = (Get-ADDomain).DistinguishedName
$USA_DN   = "OU=USA,$DomainDN"

function New-OUIfNotExists {
    param($Name, $Path)
    try {
        Get-ADOrganizationalUnit -Identity "OU=$Name,$Path" -ErrorAction Stop | Out-Null
        Write-Host "SKIP: $Name already exists" -ForegroundColor Yellow
    } catch {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
        Write-Host "OK:   Created $Name at $Path" -ForegroundColor Green
    }
}

# Top-level OUs under USA
New-OUIfNotExists "_Admin"       $USA_DN
New-OUIfNotExists "Groups"       $USA_DN
New-OUIfNotExists "Servers"      $USA_DN
New-OUIfNotExists "Workstations" $USA_DN

# Department OUs under Users
$Users_DN = "OU=Users,OU=USA,$DomainDN"
New-OUIfNotExists "Accounting" $Users_DN
New-OUIfNotExists "Executives" $Users_DN
New-OUIfNotExists "HR"         $Users_DN
New-OUIfNotExists "IT"         $Users_DN
New-OUIfNotExists "Marketing"  $Users_DN
New-OUIfNotExists "Sales"      $Users_DN