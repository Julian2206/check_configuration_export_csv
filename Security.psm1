#funzione che ritorna le porte abilitate
function Get-FirewallEnablePorts(){
    $enabledPorts = Get-NetFirewallRule | Where-Object {$_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Profile -ne 'Any'}
    Write-Host "Enabled Ports:"
    $enabledPorts | Select-Object -Property Name, DisplayName | Format-Table
}

#funzione che ritorna le porte disabilitate
function Get-FirewallDisablePorts(){
    $disabledPorts = Get-NetFirewallRule | Where-Object {$_.Enabled -eq 'False' -and $_.Direction -eq 'Inbound' -and $_.Profile -ne 'Any'}
    Write-Host "Disabled Ports:"
    $disabledPorts | Select-Object -Property Name, DisplayName | Format-Table       
}

##
## funzione che ritorna le regole del firewall e il n. delle porte filtrate + le porte abilitate 
function Get-FirewallRules () {
    Get-NetFirewallRule | 
    ForEach-Object { 
        $rule = $_
        $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
        $addressFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule
        return [PSCustomObject]@{ 
            "Name"   = $rule.Name
            "Display name" = $rule.DisplayName 
            "Filtered ports" = $portFilter.LocalPort 
            "Filtered addresses" = $addressFilter.RemoteAddress
			## proprietà Enabled dell’oggetto $rule
			"Enabled" = $rule.Enabled			
        } | Format-List | Out-String
    }
}

# VERIFY: PC NOT IN DOMAIN HAVE JUST TWO OPTION (PRIVATE AND PUBLIC PROFILES) BUT COUNT RETURNS EVER 3 AS A RESULT
function Check-FirewallIsEnabled() {
    return ((Get-NetFirewallProfile | select name,enabled) | where { $_.Enabled -eq $True } | measure ).Count -eq 3
}

# funzione che ritorna i firewall logs
function Get-WindowsFirewallLog {
    param(
        [parameter(Position=0,Mandatory=$false)]
        [ValidateScript({Test-Path $_})]
        [string]$LogFilePath = "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"
    )

    # CSV header fields, to be used later when converting each line of the tailed log from CSV
    $headerFields = @("date","time","action","protocol","src-ip","dst-ip","src-port","dst-port","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path")
 
    # Read in the firewall log
    $firewallLogs = Get-Content $LogFilePath | ConvertFrom-Csv -Header $headerFields -Delimiter ' '

    # Output logs into a gridview
    return ($firewallLogs | Out-GridView | Out-String)
}

function Check-WindowsFirewallLoggingLocally {
    param(
        [parameter(Position=0,Mandatory=$false)]
        [ValidateScript({Test-Path $_})]
        [string]$LogFilePath = "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"
    )
 
    # Read in the firewall log
    $firewallLogs = Get-Content $LogFilePath

    if([String]::IsNullOrWhiteSpace($firewallLogs)){
        return $false
    }
    return $true
}

function Check-ExecutionPolicyIsDefault() {
    if ((Get-ExecutionPolicy) -eq "Default") {
        return $true
    }
    return $false
}

## Set execution Policy to Default
Set-ExecutionPolicy -ExecutionPolicy Default
