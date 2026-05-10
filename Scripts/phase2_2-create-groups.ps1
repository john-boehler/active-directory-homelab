# Phase 2.2 - Create department security groups
# Idempotent: skips groups that already exist

$DomainDN = (Get-ADDomain).DistinguishedName
$GroupsOU = "OU=Groups,OU=USA,$DomainDN"

$Groups = @("Accounting", "Executives", "HR", "IT", "Marketing", "Sales")

foreach ($GroupName in $Groups) {
    if (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue) {
        Write-Host "SKIP: $GroupName already exists" -ForegroundColor Yellow
    } else {
        New-ADGroup -Name $GroupName `
                    -GroupScope Global `
                    -GroupCategory Security `
                    -Path $GroupsOU `
                    -Description "Department group for $GroupName"
        Write-Host "OK:   Created group $GroupName" -ForegroundColor Green
    }
}