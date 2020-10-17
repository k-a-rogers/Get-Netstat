Function Get-Netstat {
<#
.Synopsis
A function for parsing the output from netstat for perusal and subsequent manipulation.

.Description
This function will invoke the netstat command with the parameters -a (show all connections and listening ports), -f (show fully qualified domain names for foreign addresses), -n (show addresses and port numbers in numerical form), -o (show the owning process ID associated with each connection) and -q (show all connections, listening ports, and bound nonlistening TCP ports). The output of this command is then parsed to populate an array with one object per connection. Each object has properties for the protocol (TCP or UDP), protocol type (IPv4 or IPv6), source and destination addresses and ports, connection state, process ID, process imagename and session id. 

.Inputs

None. You cannot pipe objects to Get-Netstat.

.Outputs

System.Management.Automation.PSCustomObject. Get-Netstat returns an array populated with a custom object for each connection.

.Example
PS> Get-Netstat
This will call netstat, parse the data and return it to the shell.

Protocol   : TCP
Type       : IPv4
SourceIP   : 0.0.0.0
SourcePort : 135
DestIP     : 0.0.0.0
DestPort   : 0
State      : LISTENING
PID        : 876
ImageName  : svchost
SessionId  : 0

.Example
PS> Get-Netstat | Out-Gridview
This will call netstat, parse the data and return it in a custom GridView GUI. This allows for easy filtering & sorting of the output.

.Example
PS> Get-Netstat | Export-CSV -Path C:\Temp\Get-Netstat.csv -Encoding UTF8 -NoTypeInformation
This will call netstat, parse the data, and pass it along the pipeline to Export-CSV for export to C:\Temp\Get-Netstat.csv.

.Notes
AUTHOR:	Kyle Rogers

.Link
http://powershellshocked.wordpress.com
#>
	$netstat = cmd /c "netstat -a -f -n -o"
	$connections=@()
	foreach ($line in $netstat) {
		if ($line -match "^  TCP|^  UDP") {
			# Create new object
			$Obj = New-Object PSObject

			# Protocol
			Add-Member -InputObject $Obj -MemberType NoteProperty -Name Protocol -Value ($line -split " " | ? {$_ -ne ""})[0]

			# Source IP & Port. Can be IPv4 or v6
			if (($line -split " " | ? {$_ -ne ""})[1] -match "\[") {
				# IPv6
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name Type -Value "IPv6"
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name SourceIP -Value $((($line -split " " | ? {$_ -ne ""})[1] -split "]:")[0]+"]")
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name SourcePort -Value (($line -split " " | ? {$_ -ne ""})[1] -split "]:")[1]
			} else {
				# IPv4
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name Type -Value "IPv4"
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name SourceIP -Value (($line -split " " | ? {$_ -ne ""})[1] -split ":")[0]
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name SourcePort -Value (($line -split " " | ? {$_ -ne ""})[1] -split ":")[1]
			}
			# Destination IP & Port. Can be IPv4 or v6
			if (($line -split " " | ? {$_ -ne ""})[2] -match "\[") {
				# IPv6
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name DestIP -Value $((($line -split " " | ? {$_ -ne ""})[2] -split "]:")[0]+"]")
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name DestPort -Value (($line -split " " | ? {$_ -ne ""})[2] -split "]:")[1]
			} else {
				# IPv4
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name DestIP -Value (($line -split " " | ? {$_ -ne ""})[2] -split ":")[0]
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name DestPort -Value (($line -split " " | ? {$_ -ne ""})[2] -split ":")[1]
			}
			
			# Connection state - only relevant for TCP connections so check protocol property
			if ($Obj.Protocol -eq "TCP") {
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name State -Value ($line -split " " | ? {$_ -ne ""})[3]
			} else {
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name State -Value $null
			}
			
			# PID 
			if ($Obj.Protocol -eq "TCP") {
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name PID -Value ($line -split " " | ? {$_ -ne ""})[4]
			} else {
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name PID -Value ($line -split " " | ? {$_ -ne ""})[3]
			}
			
			# Additional process information
			try {
				$procinfo=get-Process -PID ($obj.PID) -ErrorAction Stop
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name ImageName -Value $($procinfo.Name)
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name SessionId -Value $($procinfo.SessionId)
			} catch {
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name ImageName -Value "Unknown"
				Add-Member -InputObject $Obj -MemberType NoteProperty -Name SessionId -Value "Unknown"
			}

			# Add to connections array, remove variables
			$connections+=$Obj
			Remove-Variable -Name Obj,procinfo -Force -ErrorAction SilentlyContinue
		}
	}
	Remove-variable -name netstat -force -erroraction silentlycontinue

	return $connections
}