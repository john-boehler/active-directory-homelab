# Phase 2.3 - Bulk user creation from in-script list
# Idempotent: skips users that already exist
# Run as Domain Admin on the DC

# ---------- CONFIGURATION ----------
$DefaultPassword = "TempP@ssw0rd2026!"
$DomainDN   = (Get-ADDomain).DistinguishedName
$DomainName = (Get-ADDomain).DNSRoot

# ---------- USER LIST ----------
# Format: First, Last, Department
$Users = @(
    # Executives
    @{First="Roald";      Last="Amundsen";    Department="Executives"},
    @{First="Edmund";     Last="Hillary";     Department="Executives"},
    @{First="Reinhold";   Last="Messner";     Department="Executives"},
    @{First="Junko";      Last="Tabei";       Department="Executives"},
    @{First="James";      Last="Cook";        Department="Executives"},
    @{First="Francis";    Last="Drake";       Department="Executives"},
    @{First="Robert";     Last="Peary";       Department="Executives"},
    @{First="Matthew";    Last="Henson";      Department="Executives"},

    # IT
    @{First="Ernest";     Last="Shackleton";  Department="IT"},
    @{First="Robert";     Last="Scott";       Department="IT"},
    @{First="Fridtjof";   Last="Nansen";      Department="IT"},
    @{First="Vitus";      Last="Bering";      Department="IT"},
    @{First="Alexander";  Last="Mackenzie";   Department="IT"},
    @{First="Yuri";       Last="Gagarin";     Department="IT"},
    @{First="Neil";       Last="Armstrong";   Department="IT"},
    @{First="Buzz";       Last="Aldrin";      Department="IT"},
    @{First="Sally";      Last="Ride";        Department="IT"},
    @{First="Valentina";  Last="Tereshkova";  Department="IT"},

    # Accounting
    @{First="Marco";      Last="Polo";        Department="Accounting"},
    @{First="Jacques";    Last="Cartier";     Department="Accounting"},
    @{First="Henry";      Last="Hudson";      Department="Accounting"},
    @{First="John";       Last="Cabot";       Department="Accounting"},
    @{First="Christopher";Last="Columbus";    Department="Accounting"},
    @{First="Ferdinand";  Last="Magellan";    Department="Accounting"},
    @{First="Leif";       Last="Erikson";     Department="Accounting"},
    @{First="Ibn";        Last="Battuta";     Department="Accounting"},

    # HR
    @{First="Daniel";     Last="Boone";       Department="HR"},
    @{First="David";      Last="Livingstone"; Department="HR"},
    @{First="Henry";      Last="Stanley";     Department="HR"},
    @{First="Mary";       Last="Kingsley";    Department="HR"},
    @{First="Gertrude";   Last="Bell";        Department="HR"},
    @{First="Isabella";   Last="Bird";        Department="HR"},
    @{First="Jane";       Last="Goodall";     Department="HR"},
    @{First="Dian";       Last="Fossey";      Department="HR"},

    # Marketing
    @{First="Amelia";     Last="Earhart";     Department="Marketing"},
    @{First="Charles";    Last="Lindbergh";   Department="Marketing"},
    @{First="Bessie";     Last="Coleman";     Department="Marketing"},
    @{First="Jeanne";     Last="Baret";       Department="Marketing"},
    @{First="Aron";       Last="Ralston";     Department="Marketing"},
    @{First="Bear";       Last="Grylls";      Department="Marketing"},
    @{First="Steve";      Last="Irwin";       Department="Marketing"},
    @{First="Jacques";    Last="Cousteau";    Department="Marketing"},

    # Sales
    @{First="Meriwether"; Last="Lewis";       Department="Sales"},
    @{First="William";    Last="Clark";       Department="Sales"},
    @{First="Hernando";   Last="Cortez";      Department="Sales"},
    @{First="Amerigo";    Last="Vespucci";    Department="Sales"},
    @{First="Vasco";      Last="Balboa";      Department="Sales"},
    @{First="Tenzing";    Last="Norgay";      Department="Sales"},
    @{First="Annie";      Last="Peck";        Department="Sales"},
    @{First="Zheng";      Last="He";          Department="Sales"}
)

# ---------- CREATION LOOP ----------
$Created = 0
$Skipped = 0
$Failed  = 0

foreach ($U in $Users) {
    $FirstName   = $U.First
    $LastName    = $U.Last
    $Department  = $U.Department
    $SamName     = ($FirstName.Substring(0,1) + $LastName).ToLower()
    $UPN         = "$SamName@$DomainName"
    $DisplayName = "$FirstName $LastName"
    $TargetOU    = "OU=$Department,OU=Users,OU=USA,$DomainDN"

    # Idempotency check
    if (Get-ADUser -Filter "SamAccountName -eq '$SamName'" -ErrorAction SilentlyContinue) {
        Write-Host "SKIP: $DisplayName ($SamName) already exists" -ForegroundColor Yellow
        $Skipped++
        continue
    }

    try {
        New-ADUser `
            -Name              $DisplayName `
            -GivenName         $FirstName `
            -Surname           $LastName `
            -SamAccountName    $SamName `
            -UserPrincipalName $UPN `
            -DisplayName       $DisplayName `
            -EmailAddress      $UPN `
            -Department        $Department `
            -Path              $TargetOU `
            -AccountPassword   (ConvertTo-SecureString $DefaultPassword -AsPlainText -Force) `
            -Enabled           $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        Add-ADGroupMember -Identity $Department -Members $SamName -ErrorAction Stop

        Write-Host "OK:   $DisplayName ($SamName) -> $Department" -ForegroundColor Green
        $Created++
    }
    catch {
        Write-Host "FAIL: $DisplayName ($SamName) - $($_.Exception.Message)" -ForegroundColor Red
        $Failed++
    }
}

Write-Host ""
Write-Host "===== SUMMARY =====" -ForegroundColor Cyan
Write-Host "Created: $Created"   -ForegroundColor Green
Write-Host "Skipped: $Skipped"   -ForegroundColor Yellow
Write-Host "Failed:  $Failed"    -ForegroundColor Red
