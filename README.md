# Get-Netstat
A Powershell wrapper/parser for netstat

PowerShell has native commands for retrieving network connection details - <a href="https://docs.microsoft.com/en-us/powershell/module/nettcpip/get-nettcpconnection">Get-NetTCPConnection</a> and <a href="https://docs.microsoft.com/en-us/powershell/module/nettcpip/get-netudpendpoint">Get-NetUDPEndpoint</a>. I thought it might be useful to have a PS wrapper/parser for the command-line netstat function, so that a single command can return information about both TCP and UDP connections in a format that allows for easy manipulation.

The current version does not accept any inputs or have any parameters. It invokes the netstat command with the parameters -a (show all connections and listening ports), -f (show fully qualified domain names for foreign addresses), -n (show addresses and port numbers in numerical form), -o (show the owning process ID associated with each connection) and -q (show all connections, listening ports, and bound nonlistening TCP ports). The output of this command is then parsed line-by-line to populate an array with one object per connection. Each object has properties for the protocol (TCP or UDP), protocol type (IPv4 or IPv6), source and destination addresses and ports, connection state, process ID, process imagename and session id.

It's not a particularly complex function - it's essentially a series of string-split operations that add properties to a custom object - but it's commented enough to make sense, and has comment-based help as well.
