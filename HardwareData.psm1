# Funzione per settare il wallpaper -------------------------------------------------------------
function Set-Wallpaper{
    $wallPaperPath = "C:\Users\Public\Pictures\MicrosoftTeams-image.png"
    $localPolicy = Get-WmiObject -Namespace "root\rsop\computer" -Class RSOP_PolicySetting -Filter  'Desktop Wallpaper'
    if($localPolicy){
        $localPolicy.value = $wallPaperPath
        $localPolicy.Put() | Out-Null
        gpupdate /force | Out-Null
        Write-Host "Desktop Wallpaper has been modified successfully"
    }else{
        Write-Host "Impossible to find the local computer policy for desktop wallpaper"
    }
}

# ----------------------------------------------------------------------------------------------------

# Funzione per check sys operativo -------------------------------------------------------------------
function Get-PCName() {
    return [System.Net.Dns]::GetHostName()
}

function Check-ComputerNameSetProperly($expectedName) {
    return $expectedName -eq (Get-PCName)
}

# Define the function to get the minimum password length NOT WORKING ---------------------------------
function Get-MinimumPasswordLength {
    $seceditOutput = secedit.exe /export /cfg "$env:TEMP\secpol.cfg" | Out-Null
    $secpolData = Get-Content "$env:TEMP\secpol.cfg" -Raw | ConvertFrom-StringData

    if ($secpolData -match 'PasswordComplexity\s*=\s*(\d+)') {
        return $Matches[1]
    }

    return "N/A"
}

# serve che torni la versione del BIOS come stringa
function Get-BIOSVersion (){
    $getBIOSVersion = Get-WmiObject -Class Win32_BIOS -Property "SMBIOSBIOSVersion"

    $resultString = "$($getBIOSVersion.SMBIOSBIOSVersion)" | Out-String
    return [string]::join("",($resultString.Split("`n")))
}

# funzione che ritorna la versione del os 
function Get-OsVersion() {
    $osReleaseId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId | Out-String
    $osReleaseId = [string]::join("",($osReleaseId.Split("`n")))

    $osBuild = [System.Environment]:: OSVersion.Version.Build

    $osVersion = "V$($osReleaseId), build $($osBuild)"
    $osVersion = [string]::join("",($osVersion.Split("`n")))

    $osEdition = (Get-WindowsEdition -Online).Edition
    $osEdition = [string]::join("",($osEdition.Split("`n")))

    $osBits = ''

    if ([Environment]::Is64BitOperatingSystem) {
        $osBits = '64 bit'
    } else {
        $osBits = '32 bit'
    }
    $osBits = [string]::join("",($osBits.Split("`n")))

    $resultString = "$($osReleaseId) $($osVersion) $($osEdition) $($osBits)".Trim()
    return [string]::join("",($resultString.Split("`n")))
}


function Get-WindowsLicenseNumber() {
    $softwareLicensingService = Get-WmiObject -query 'select * from SoftwareLicensingService'    
    
    return $softwareLicensingService.OA3xOriginalProductKey | Out-String
}

# funzione che ritorna le informazioni del dominio del computer system(bool) -----------------------------------------------
function _Get-PCIsJoinedInDomain() {
    return (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
}
# funzione che ritorna informazioni del workgroup
function _Get-Workgroup() {
    return (Get-WmiObject -Class Win32_ComputerSystem).Workgroup
}

function Get-WorkgroupOrDomain() {
    $domainOrWorkgroupName = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain).Domain
    if (_Get-PCIsJoinedInDomain) {
        return "Domain $($domainOrWorkgroupName)"
    }
    return "Workgroup $($domainOrWorkgroupName)"
}

function Get-InstalledSoftware() {
    return Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Out-String
}

#---------------------------------------------------------------------------------------------------------------------------

## funzione che ritorna i driver installati 
function Get-InstalledDrivers() {
    return (Get-WmiObject Win32_PnPSignedDriver | select DeviceName, Manufacturer, DriverVersion | Format-List | Out-String)
}

#### !! Get-ComputerInfo ========================================================================================================================================================================================================================================================================

<# function Get-ComputerMakeAndModel() {
    $computerMake = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    $computerModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model

    return "Make $($computerMake), model $($computerModel)"
} #>

function Get-ComputerMake() 
{
	$computerMake = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
	return $computerMake
}

function Get-ComputerModel()
{
	$computerModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
	return $computerModel
}

function Get-SerialNumber(){
    $serialNumber = (Get-WMIObject -Class WIN32_SystemEnclosure -ComputerName $env:ComputerName).serialNumber 
    if($serialNumber -eq "" -or $serialNumber -match "None"){
        return ""
    } else {
        return "Serial Number $($serialNumber)"
    }
}

function Get-ProcessorName(){
	$processor = (Get-WmiObject -Class Win32_Processor).Name
	return $processor
}

function Get-TotalMemory() {
    return ((Get-CimInstance -ClassName 'Cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum / 1GB)
}

function Get-memoryDetails() {
	$memoryDetails = (Get-WmiObject win32_physicalmemory | Format-Table Manufacturer,@{ label = "Size/GB"; expression = { $_.Capacity / 1GB }}) | Out-String
	return $MemoryDetails
}

function Get-hardDrives() {
	$hardDrives = (Get-CimInstance -Class CIM_LogicalDisk | Select-Object DeviceId, @{Name="Size(GB)";Expression={[math]::floor($_.size/1gb)}}, @{Name="Free Space(GB)";Expression={[math]::floor($_.freespace/1GB)}}, DriveType | Where-Object DriveType -EQ '3') | Out-String
	return $hardDrives
}

function Get-Partitions() {
	$partitions = (gwmi win32_logicaldisk -Filter "MediaType > 0" | Format-Table DeviceId, MediaType, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}) | Out-String
    return $partitions
}

function Get-DiskInfo() {
	$disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Status, SerialNumber | Format-Table | Out-String
	return $disks
}	
		
#================================================================================================================================================================================================================================================================================================

<# function Get-ComputerInformations() {
    $computerMake = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
    $computerModel = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
    $serialNumber = (Get-WMIObject -Class WIN32_SystemEnclosure -ComputerName $env:ComputerName).SerialNumber | Out-String
    $processor = (Get-WmiObject -Class Win32_Processor).Name
    $totalMemory = ((Get-CimInstance -ClassName 'Cim_PhysicalMemory' | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $memoryDetails = (Get-WmiObject win32_physicalmemory | Format-Table Manufacturer,@{ label = "Size/GB"; expression = { $_.Capacity / 1GB }}) | Out-String
    $hardDrives = (Get-CimInstance -Class CIM_LogicalDisk | Select-Object DeviceId, @{Name="Size(GB)";Expression={[math]::floor($_.size/1gb)}}, @{Name="Free Space(GB)";Expression={[math]::floor($_.freespace/1GB)}}, DriveType | Where-Object DriveType -EQ '3') | Out-String
    $partitions = (gwmi win32_logicaldisk -Filter "MediaType > 0" | Format-Table DeviceId, MediaType, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}) | Out-String
    $disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, Status, SerialNumber | Format-Table | Out-String

	return [PSCustomObject]@{
		ComputerMake = $computerMake
		ComputerModel = $computerModel
		SerialNumber = $serialNumber
		Processor = $processor
		TotalMemory = "$totalMemory GB"
		MemoryDetails = $memoryDetails
		HardDrives = $hardDrives
		Partitions = $partitions
		Disks = $disks
	}
} #>

#### Test
#Write-Host ([PSCustomObject]).GetType()
