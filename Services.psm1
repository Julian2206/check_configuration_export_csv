#funzione che abilita il servizio RDP
function Enable-RDPService(){
    $pathRDP = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    Set-ItemProperty -Path $pathRDP -Name "fDenyTSConnections" -Value 0
}

#funzione che abilita il servizio RDP
function Disable-RDPService(){
    $pathRDP = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
    Set-ItemProperty -Path $pathRDP -Name "fDenyTSConnections" -Value 
}

#funzione che controlla se il servizio RDP è disabilitato
function Check-RDPDisabled(){
    $RDPStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections"
    if($RDPStatus.fDenyTSConnections -eq 1){
        return $false
    }else{
        return $true
    }
}

function Enable-USBports () {
    $pathUSB = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR'
    Set-ItemProperty -Path $pathUSB -Name "Start" -Value 3
}

function Disable-USBports (){
    $pathUSB = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR'
    Set-ItemProperty -Path $pathUSB -Name "Start" -Value 4
}

function Check-USBportsDisabled () {
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR'
    $disableUSBports = Get-ItemProperty -Path $path -Name "Start"
    if($disableUSBports.Start -eq 4){
        return $true
    }
    return $false
}

#confrontare con server ntp in input -> serve ricevere l'indirizzo del server NTP che ci aspettiamo ci sia
#vedere caso con più NTP server
#funzione che controlla se il server dato in input sia quello che è settato nella macchina
function Check-NTPServerAddressesSetCorrectly($serverNTP) {
    $pathNTP = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers'
    $NTPlist = @()
    $notFoundServers = @()
    $value = 0  
    foreach ($ntpServer in $serverNTP) {
        $checkNTP = Get-ItemProperty -Path $pathNTP
        if ($checkNTP.$value -in $serverNTP) {
            $value += 1
            $NTPlist += $ntpServer
        }else{
            $value += 1
            $notFoundServers += $ntpServer
        }
    }
    if ($notFoundServers.Count -ne 0) {
            Write-Host "This(These) server(s) NTP '$notFoundServers' is(are) not set on this computer."
    }
    Write-Host "Actual NTP(s) address on this computer: $($NTPlist)"
}

#funzione che controlla i servizi che dovrebbero essere abilitati
#funzione deve tornare oggetto con i seguenti parametri: success [booleano], errorMessage [stringa], notRightlySetServices [lista di stringhe (nomi servizi)]
function Check-EnabledServicesAsRequired($servicesToEnableList) {
    $enabledServices = @()
    $notEnableServices = @()
    $notFoundService = @()
    $valid = $true  
    Foreach ($service in $servicesToEnableList) {
        try {
            $currentService = Get-Service -Name $service.name -ErrorAction Stop
            if ($currentService.StartType -ne "Disabled") {
                $enabledServices += $service.name
            }else{
                $notEnableServices += $service.name
            }
        } catch {
            $notFoundService += $($service.name)
        }
    }
    if ($notEnableServices.Count -eq 0) {
        $errorMessage = ""
        $notRightlySetServices = @()
    }else{
        $valid = $false
        $errorMessage = "Not all services that must be enabled are set rightly"
        $notRightlySetServices = $notEnableServices
    }
    $result = [PSCustomObject]@{
        Success = $valid
        ErrorMessage = $errorMessage
        NotRightlySetServices = $notRightlySetServices
        NotFoundServices = $notFoundService
    }
    return $result
}

#funzione che controlla i servizi che dovrebbero essere disabilitati
function Check-DisabledServicesAsRequired($servicesToDisableList){
    $disableServices = @()
    $notDisableService = @()
    $notFoundService = @()
    $valid = $true
    Foreach ($service in $servicesToDisableList) {
        try {
            $currentService = Get-Service -Name $($service.name) -ErrorAction Stop
            if($currentService.StartType -eq "Disabled") {
                $disableServices += "$($service.name)"
            }else{
                $notDisableService += "$($service.name)"
            }
        }catch{
            $notFoundService += "$($service.name)"
        }
    }
    if($notDisableService.Count -eq 0){
        $errorMessage = ""
        $notRightlySetServices = @()
    }else{
        $valid = $false
        $errorMessage = "Not all services that must be disabled are set rightly"
        $notRightlySetServices = $notDisableService
    }
    $result = [PSCustomObject]@{
        Success = $valid
        ErrorMessage = $errorMessage
        NotRightlySetServices = $notRightlySetServices
        NotFoundService = $notFoundService
    }
    return $result
}

# funzione che esporta file dei servizi
function Export-ServicesStartupType() {
    Get-Service | Select-Object Name, DisplayName, StartType | Export-Csv "$($PSScriptRoot)\$(Get-PCName)_services.txt"
}