# funzione che ritorna il DNS server
function Get-DNSServersAddressesByIfIndex($ifIndex) {
    $dnsServer1 = ""
    $dnsServer2 = ""
    $dnsServersList = @()

    try {
        (Get-DnsClientServerAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction Stop) | ForEach-Object {$dnsServersList += $_.ServerAddresses}
    } catch {
        Write-Host "Interface with index $($ifIndex) not found."
    }

    if($dnsServersList.Count -gt 1) {
            $dnsServer1 = $dnsServersList[0]
            $dnsServer2 = $dnsServersList[1]
        } elseif ($dnsServersList.Count -eq 1) {
            $dnsServer1 = $dnsServersList[0]
        } else {
            $dnsServer1 = ""
            $dnsServer2 = ""
        }

    return [PSCustomObject]@{
            "DnsServer1" = $dnsServer1
            "DnsServer2" = $dnsServer2
    }
}

# Funzione di controllo per sincronizzazione NTP -----------------------------------------------------
function Check-NTPSyncronization {
    # Set the desired time (3:33:00 A.M.)
    $desiredTime = Get-Date "3:33:00 AM"
    $currentTime = Get-Date
    $ntpSource = (w32tm /query /source)
    
    # Set the system time to the desired time
    Set-Date $desiredTime

    # Try to synchronize time with NTP server
    try {
        w32tm /resync
    }
    catch {
        Write-Host "Time synchronization failed."
        return $false
    }

    # Wait for a moment to let the time sync complete
    Start-Sleep -Seconds 5

    # Compare the time after sync with the desired time (3:33:00 A.M.)
    if ($currentTime -ne $desiredTime) {
        [PsCustomObject]@{
            Success = $true
            NtpSource = $ntpSource
        }
        return $true  # Time was different than 3:33 A.M.
    } else {
        return $false # Time was equal to 3:33 A.M.
    }
}

# funzione che ritorna una lista di indirizzi IP
function Get-IpAddresses($ifIndex) {
    try {
        return (Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction Stop | Where-Object {$_.PrefixLength -ne "WellKnown"})
    } catch {
        Write-Host "Interface with index $($ifIndex) not found."
        return @()
    }
}

# funzione che ritorna il gateway 
function Get-IPGateway($ifIndex) {
    try {
        $interface = (Get-NetIPInterface -InterfaceIndex $ifIndex -ErrorAction Stop)
        $result = (Get-NetIPConfiguration -InterfaceIndex $ifIndex -ErrorAction Stop)
        return $result.IPv4DefaultGateway.NextHop
    } catch {
        Write-Host "Interface with index $($ifIndex) not found."
        return ""
    }
}

# funzione che ritorna le schede di rete
function Get-NetAdaptersData() {
    return Get-NetAdapter | ForEach-Object {
        $enabled = $false
        $dnsServers = (Get-DNSServersAddressesByIfIndex($_.ifIndex))
        $ipAddresses = (Get-IpAddresses($_.ifIndex))
        $gateway = (Get-IPGateway($_.ifIndex))

        if ($_.InterfaceAdminStatus -eq 1) {
            $enabled = $true
        }
        if ($ipAddresses) {
            return [PSCustomObject]@{
                "Name" = $_.Name
                "InterfaceDescription" = $_.InterfaceDescription
                "ifIndex" = $_.ifIndex
                "Status" = $_.Status
                "Enabled" = $enabled
                "IPAddress" = $ipAddresses.IPAddress
                "SubnetMask" = "/$($ipAddresses.PrefixLength)"
                "Gateway" = $gateway
                "MacAddress" = $_.MacAddress
                "DNSServer1" = $dnsServers.DnsServer1
                "DNSServer2" = $dnsServers.DnsServer2
            } | Format-List | Out-String
        } else {
            return [PSCustomObject]@{
                "Name" = $_.Name
                "InterfaceDescription" = $_.InterfaceDescription
                "ifIndex" = $_.ifIndex
                "Status" = $_.Status
                "Enabled" = $enabled
                "IPAddress" = "NOT SET"
                "SubnetMask" = "NOT SET"
                "Gateway" = "NOT SET"
                "MacAddress" = $_.MacAddress
                "DNSServer1" = "NOT SET"
                "DNSServer2" = "NOT SET"
            } | Format-List | Out-String
        }
    }
}

# !! Da implementare funzione per controllare se il DNS è stato configurato nella maniera corretta  
function Check-DnsServersSetAsRequired($dnsServers) {
    # not implemented
}

#funzione che ritorna le interfacce di rete abilitate
function Get-EnabledNetPorts(){
    # Ottieni le interfacce di rete abilitate
    $networkInterfaces = Get-NetAdapter | Where-Object { $_.AdminStatus -eq 'Up' }
    Write-Host "Enable Ports:"
    # Stampa le informazioni sulle interfacce di rete
    $listEnableInterfaces = @()
    foreach ($interface in $networkInterfaces) {
        $listEnableInterfaces = "$($interface.Name)" | Format-List
    }
    return $listEnableInterfaces
}

#funzione che ritorna le interfacce di rete disabilitate
function Get-DisabledNetPorts(){
    # Ottieni le interfacce di rete disabilitate
    $networkInterfaces = Get-NetAdapter | Where-Object { $_.AdminStatus -eq 'Down' }
    Write-Host "Disable Ports:"
    # Stampa le informazioni sulle interfacce di rete disabilitate
    $listDisableInterfaces = @()
    foreach ($interface in $networkInterfaces) {
        $listDisableInterfaces = "$($interface.Name)" | Format-List
    }
    return $listDisableInterfaces
}

## funzione che ritorna i local Users
function Get-LocalUsersWithGroups () {
    Get-LocalUser | 
    ForEach-Object { 
        $user = $_
        return [PSCustomObject]@{ 
            "User"   = $user.Name
            "Description" = $user.Description
            "Enabled" = $user.Enabled
            "PasswordExpires" = $user.PasswordExpires
            "AccountExpires" = $user.AccountExpires
            "PasswordRequired" = $user.PasswordRequired
            "LastLogon" = $user.LastLogon
            "Groups" = Get-LocalGroup | Where-Object {  $user.SID -in ($_ | Get-LocalGroupMember | Select-Object -ExpandProperty "SID") } | Select-Object -ExpandProperty "Name"
       
        } | Format-Table | Out-String
    }
}

# funzione che ritorna le TCP connections
function Get-TCPListeningPorts() {
    return (Get-nettcpconnection | Select-Object local*,remote*,state,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | Format-List | Out-String)
}