#
# RUN THIS SCRIPT ON MACHINE WHERE YOU WHANT TO START SQL INSTANCE
#
#

#cluster group name
#in case of dubbit run Get-ClusterResource
#utilizzato solo se si vuole recuperare automaticamente il vIP di SQL
#$cluster_group = 'SVCINET'

#SQL Server instance name
#$sql_instance = 'SVCSQL'

#MSSQLSERVER if default
$sql_instance = 'MSSQLSERVER'

# set PS to stop at first error
$ErrorActionPreference = "Stop"

#get SQL Instance's IP from cluster group resources (to be tested)
#$sql_ip_resource = Get-ClusterGroup $cluster_group | Get-ClusterResource | where-object {$_.ResourceType -eq "IP Address"}
#$sql_ip = (Get-ClusterResource $sql_ip_resource.Name | Get-ClusterParameter | where-object {$_.Name -eq "Address"}).value

#set the SQL Server's vIP manually
$sql_ip = ""

$sql_instance_key = (Get-ItemProperty -Path 'hklm:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\').$sql_instance

#get SQL instance path and port from registry
$key_path = 'hklm:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $sql_instance_key + '\Setup\'
$key_port = 'hklm:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $sql_instance_key + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'

$sql_path = (Get-ItemProperty -Path $key_path).SQLPath
$sql_port = (Get-ItemProperty -Path $key_port).TcpPort

#run SQL instance in minimal mode into a CMD window
$slq_svc_cmd = '/c ""' + $sql_path + '\Binn\sqlservr.exe" -s ' + $sql_instance + ' -f -m"SQLCMD""'
Start-Process -FilePath "cmd.exe" -ArgumentList $slq_svc_cmd

#run a SQLCMD and connect to the SQLServer instance started into the other cmd window. it should!!!!
$sql_cli_cmd = '/c "sqlcmd -S ' + $sql_ip + ',' + $sql_port + ' -E -q"SELECT @@servername;""'
Start-Process -FilePath "cmd.exe" -ArgumentList $sql_cli_cmd
