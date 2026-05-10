# Phase 4.3 - Build the Domain Local layer of AGDLP
# Creates DL groups and nests the appropriate Global groups into each

$DomainDN = (Get-ADDomain).DistinguishedName
$GroupsOU = "OU=Groups,OU=USA,$DomainDN"

# Mapping: each DL group and the Global group(s) that should be members
$Mapping = @(
    @{DL="DL_Accounting_Modify"; Globals=@("Accounting")},
    @{DL="DL_Executives_Modify"; Globals=@("Executives")},
    @{DL="DL_HR_Modify";         Globals=@("HR")},
    @{DL="DL_IT_Modify";         Globals=@("IT")},
    @{DL="DL_Marketing_Modify";  Globals=@("Marketing")},
    @{DL="DL_Sales_Modify";      Globals=@("Sales")},
    @{DL="DL_Public_Modify";     Globals=@("Domain Users")}
)

foreach ($M in $Mapping) {
    $DLName = $M.DL

    # Create the DL group if missing
    if (Get-ADGroup -Filter "Name -eq '$DLName'" -ErrorAction SilentlyContinue) {
        Write-Host "SKIP: $DLName already exists" -ForegroundColor Yellow
    } else {
        New-ADGroup -Name $DLName `
                    -GroupScope DomainLocal `
                    -GroupCategory Security `
                    -Path $GroupsOU `
                    -Description "DL group granting Modify access to corresponding folder"
        Write-Host "OK:   Created $DLName" -ForegroundColor Green
    }

    # Nest each Global into the DL
    foreach ($Global in $M.Globals) {
        $AlreadyMember = Get-ADGroupMember -Identity $DLName -ErrorAction SilentlyContinue |
                         Where-Object { $_.Name -eq $Global }
        if ($AlreadyMember) {
            Write-Host "  SKIP: $Global is already in $DLName" -ForegroundColor Yellow
        } else {
            Add-ADGroupMember -Identity $DLName -Members $Global
            Write-Host "  OK:   Added $Global to $DLName" -ForegroundColor Green
        }
    }
}