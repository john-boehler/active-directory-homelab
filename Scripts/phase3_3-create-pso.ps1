# Phase 3.3 - Fine-Grained Password Policies
# Creates two PSOs and applies them to the appropriate groups

# ---------- Standard PSO (all users) ----------
$StandardPSOName = "PSO_Standard_Users"

if (Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$StandardPSOName'" -ErrorAction SilentlyContinue) {
    Write-Host "SKIP: $StandardPSOName already exists" -ForegroundColor Yellow
} else {
    New-ADFineGrainedPasswordPolicy `
        -Name $StandardPSOName `
        -DisplayName "Standard User Password Policy" `
        -Description "Baseline password policy for all standard domain users" `
        -Precedence 100 `
        -MinPasswordLength 12 `
        -ComplexityEnabled $true `
        -ReversibleEncryptionEnabled $false `
        -PasswordHistoryCount 10 `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge "90.00:00:00" `
        -LockoutThreshold 5 `
        -LockoutDuration "00:30:00" `
        -LockoutObservationWindow "00:30:00"
    Write-Host "OK:   Created $StandardPSOName" -ForegroundColor Green
}

# Apply Standard PSO to Domain Users (everyone)
Add-ADFineGrainedPasswordPolicySubject `
    -Identity $StandardPSOName `
    -Subjects "Domain Users" `
    -ErrorAction SilentlyContinue
Write-Host "OK:   Applied $StandardPSOName to Domain Users" -ForegroundColor Green

# ---------- Privileged PSO (IT + Executives) ----------
$PrivilegedPSOName = "PSO_Privileged_Users"

if (Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$PrivilegedPSOName'" -ErrorAction SilentlyContinue) {
    Write-Host "SKIP: $PrivilegedPSOName already exists" -ForegroundColor Yellow
} else {
    New-ADFineGrainedPasswordPolicy `
        -Name $PrivilegedPSOName `
        -DisplayName "Privileged User Password Policy" `
        -Description "Stricter password policy for IT and Executives" `
        -Precedence 50 `
        -MinPasswordLength 16 `
        -ComplexityEnabled $true `
        -ReversibleEncryptionEnabled $false `
        -PasswordHistoryCount 24 `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge "60.00:00:00" `
        -LockoutThreshold 3 `
        -LockoutDuration "01:00:00" `
        -LockoutObservationWindow "01:00:00"
    Write-Host "OK:   Created $PrivilegedPSOName" -ForegroundColor Green
}

# Apply Privileged PSO to IT and Executives
Add-ADFineGrainedPasswordPolicySubject `
    -Identity $PrivilegedPSOName `
    -Subjects "IT", "Executives" `
    -ErrorAction SilentlyContinue
Write-Host "OK:   Applied $PrivilegedPSOName to IT and Executives" -ForegroundColor Green