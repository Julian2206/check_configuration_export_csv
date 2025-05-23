
## Import Modules -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Set-Location -Path $PSScriptRoot

try {
    Import-Module .\NetworkConfig.psm1 -ErrorAction Stop
} catch {
    Write-Host -ForegroundColor Red "Errore caricamento modulo NetworkConfig"
}
try {
    Import-Module .\HardwareData.psm1 -ErrorAction Stop
} catch {
    Write-Host -ForegroundColor Red "Errore caricamento modulo HardwareData"
}
try {
    Import-Module .\Services.psm1 -ErrorAction Stop
} catch {
    Write-Host -ForegroundColor Red "Errore caricamento modulo Services"
}
try {
    Import-Module .\Security.psm1 -ErrorAction Stop
} catch {
    Write-Host -ForegroundColor Red "Errore caricamento modulo Security"
}
try {
    Import-Module .\RegionalSettings.psm1 -ErrorAction Stop
} catch {
    Write-Host -ForegroundColor Red "Errore caricamento modulo RegionalSettings"
}

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Get-Content from Json data 
$jsonContent = Get-Content "$PSScriptRoot\config.json" | Out-String | ConvertFrom-Json

$servicesToEnableList = $jsonContent.servicesToEnable
$servicesToDisableList = $jsonContent.servicesToDisable
$expectedComputerName = $jsonContent.computerName

$checkConfiguredData = [PSCustomObject]@{
    computerNameSetProperly = $false
    usbPortsDisabled = $false
}

$reportString = ""
$succededControls = @()
$failedControls = @()
$toCheckManually = @()

function addSuccededControl($stringToAdd) {
    $script:succededControls += $stringToAdd
}

function addFailedControl($stringToAdd) {
    $script:failedControls += $stringToAdd
}

function addControlToCheckManually($stringToAdd) {
    $script:toCheckManually += $stringToAdd
}

function addToReport($stringToAdd) {
    $script:reportString += ("`n"+ $stringToAdd)
}

# EXECUTION POLICY IS DEFAULT
If (Check-ExecutionPolicyIsDefault) {
    $message = "Execution policy is safe."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = "Execution policy not safe. Change it to default."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

# COMPUTER NAME
If (Check-ComputerNameSetProperly($expectedComputerName)) {
    $message = "Computer name set correctly as $($expectedComputerName)"
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = "Computer name not set correctly. Expected name: $($expectedComputerName)"
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    $success = $false
    addFailedControl($message)
}

# USB PORTS DISABLED
If (Check-USBportsDisabled) {
    $message = "USB ports are correctly disabled."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = "USB ports are not disabled."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    $success = $false
    addFailedControl($message)
}

# BIOS
$biosVersion = Get-BIOSVersion
$message = "BIOS version: $($biosVersion)"
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

# OS VERSION
$osVersion = Get-OsVersion
$message = "OS version: $($osVersion)"
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

#OS LICENSE NUMBER
$windowsLicenseNumber = Get-WindowsLicenseNumber
$message = "OS license number: $($osVersion)"
if ($windowsLicenseNumber -ne "") {
    Write-Host -ForegroundColor Yellow $message
    addToReport($message)
    addControlToCheckManually($message)
} else {
    $message = "Windows License number not found."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

# WORKGROUP OR DOMAIN
$message = "PC is in $(Get-WorkgroupOrDomain)"
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

# TIME ZONE --------------------------------------------------------------------------------------------------------
$timeZone = Get-TimeZoneDisplayName
if ($timeZone -ne "") {
    $message = "Time zone set is: $(timeZone)." # or Get-timeZone ?
    Write-Host -ForegroundColor Yellow $message
    addControlToCheckManually($message)
} else {
    $message = "Time zone is not set."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}
#-------------------------------------------------------------------------------------------------------------------

# HardawareData Function TODO: add the new functions and remove the old ones -------------------------------------------------------------------------------------------
$Serial = Get-SerialNumber
if ($Serial -eq "") 
{
	$Serial = "PC Serial Number Not Found."
	$message ="
---------------------------------------------
	PC Serial Number Not Found.
---------------------------------------------
	"

    Write-Host -ForegroundColor Red $message
	addToReport($message)
    addFailedControl($message)
}
else 
{
	$message = "PC serial number is: $($Serial)."
    Write-Host -ForegroundColor Yellow $message
	addToReport($message)
	addControlToCheckManually($message)
}

$message = @"
------------------------------------------------
PC make: $(Get-ComputerMake)
------------------------------------------------
PC model: $(Get-ComputerModel)
------------------------------------------------
PC serial number: $($Serial)
------------------------------------------------
PC processor name: $(Get-ProcessorName)
------------------------------------------------
PC total memory: $(Get-TotalMemory)
------------------------------------------------
PC memory details: $(Get-memoryDetails)
------------------------------------------------
PC hard drives: $(Get-hardDrives)
------------------------------------------------
PC partitions info: $(Get-Partitions)
------------------------------------------------
PC disk info $(Get-DiskInfo)
------------------------------------------------
"@
addToReport($message)
addControlToCheckManually($message)
#-------------------------------------------------------------------------------------------------------------------

# IP ADDRESSES
$message = @"
IP ADDRESSES
----------------------------------
$(Get-NetAdaptersData)
----------------------------------
"@
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

$message = @"
LISTENING TCP PORTS
----------------------------------
$(Get-TCPListeningPorts)
----------------------------------
"@
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

$message = @"
INSTALLED DRIVERS
----------------------------------
$(Get-InstalledDrivers)
----------------------------------
"@
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

# INSTALLED SOFTWARE
$message = @"
INTSTALLED SOFTWARE
----------------------------------
$(Get-InstalledSoftware)
----------------------------------
"@
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

# PASSWORD POLICY
$message = "!!!! Password policy cannot be retrieved using this script yet.!!!! "
Write-Host -ForegroundColor Red $message
addToReport($message)
addControlToCheckManually($message)

# SYSTEM SLEEP POLICY
$message = "!!!! System lock policy cannot be retrieved using this script yet.!!!!"
Write-Host -ForegroundColor Red $message
addToReport($message)
addControlToCheckManually($message)

# LOCAL USERS
$message = @"
LOCAL USERS
----------------------------------
$(Get-LocalUsersWithGroups)
----------------------------------
"@
Write-Host -ForegroundColor Yellow $message
addToReport($message)
addControlToCheckManually($message)

# FIREWALL
If (Check-FirewallIsEnabled) {
    $message = "Firewall is enabled."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = "Firewall is not enabled."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

if (Check-FirewallIsEnabled) {
    $message = @"
FIREWALL RULES
----------------------------------
$(Get-FirewallRules)
----------------------------------
"@
    Write-Host -ForegroundColor Yellow $message
    addToReport($message)
    addControlToCheckManually($message)
}

# FIREWALL LOGGING LOCALLY
If (Check-WindowsFirewallLoggingLocally) {
    $message = "Windows firewall is logging correctly."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = "Windows firewall is not generating logs correctly."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

# REQUIRED SERVICES ENABLING
$enabledServicesAsRequired = Check-EnabledServicesAsRequired($servicesToEnableList)
if ($enabledServicesAsRequired.Success) {
    $message = "The required services have been enabled correctly."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = @"
The required services have not been enabled correctly. Below the list of not enabled services:
$($enabledServicesAsRequired.NotRightlySetServices -join ", ")
"@
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

# REQUIRED SERVICES DISABLING
$disabledServicesAsRequired = Check-DisabledServicesAsRequired($servicesToDisableList)
if ($disabledServicesAsRequired.Success) {
    $message = "The required services have been disabled correctly."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = @"
The required services have not been disabled correctly. Below the list of not disabled services:
$($disabledServicesAsRequired.NotRightlySetServices -join ", ")
"@
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

# CHECK NTP SYNCRONIZATION
$checkNtpSync = Check-NTPSyncronization
if($checkNtpSync.Success) {
    $message = "The time has synced succesfully with $($checkNtpSync.NtpSource) server."
    Write-Host -ForegroundColor Green $message
    addToReport($message)
    addSuccededControl($message)
} else {
    $message = "The time have not synced succesfully with $($checkNtpSync.NtpSource) server."
    Write-Host -ForegroundColor Red $message
    addToReport($message)
    addFailedControl($message)
}

$controlsNumber = $succededControls.Count + $failedControls.Count + $toCheckManually.Count

$message = "##########################################"
$reportString += $message
Write-Host $message

$message = @"
Total controls number: $($controlsNumber)
******************************************
"@
$reportString += $message
Write-Host $message

$message = "SUCCEDED CONTROLS: $($succededControls.Count)"
$reportString += $message
Write-Host -ForegroundColor Green $message

$message = @"
$($succededControls -join "`n------------------------------------------`n")
******************************************
"@
$reportString += $message
Write-Host $message

$message = "CONTROLS TO CHECK MANUALLY: $($toCheckManually.Count)"
$reportString +=$message
Write-Host -ForegroundColor Yellow $message

$message = @"
$($toCheckManually -join "`n------------------------------------------`n")
******************************************
"@
$reportString += $message
Write-Host $message

$message = "FAILED CONTROLS: $($failedControls.Count)"
$reportString += $message
Write-Host -ForegroundColor Red $message

$message = @"
$($failedControls -join "`n------------------------------------------`n")
"@
$reportString += $message
Write-Host $message
Write-Host "##########################################"

$reportString > "$($PSScriptRoot)\$($expectedComputerName).txt"

###------------------------ EXPORT IN CSV ----------------------------------###

$report = @() #create a empty list
$report += [PSCustomObject]@{ # add to 
    'Tipo' = 'SUCCEDED CONTROLS'
    'Valore' = $succededControls.Count
}

foreach ($control in $succededControls) {
    $report += [PSCustomObject]@{
        'Tipo' = 'SUCCEDED CONTROL'
        'Valore' = $control
    }
}
$report += [PSCustomObject]@{
    'Tipo' = 'CONTROLS TO CHECK MANUALLY'
    'Valore' = $toCheckManually.Count
}
foreach ($control in $toCheckManually) {
    $report += [PSCustomObject]@{
        'Tipo' = 'CONTROL TO CHECK MANUALLY'
        'Valore' = $control
    }
}
$report += [PSCustomObject]@{
    'Tipo' = 'FAILED CONTROLS'
    'Valore' = $failedControls.Count
}
foreach ($control in $failedControls) {
    $report += [PSCustomObject]@{
        'Tipo' = 'FAILED CONTROL'
        'Valore' = $control
    }
}

#$report | Export-Csv -Path "$($PSScriptRoot)\$($expectedComputerName).csv" -NoTypeInformation
$report | Export-Csv -Path "$PSScriptRoot\$expectedComputerName.csv" -NoTypeInformation -Encoding UTF8
