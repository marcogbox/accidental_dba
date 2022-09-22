# SQL Server Emergency Connection
This procedure describes the emergency start of an SQL instance that can be used in many scenarios.

### Step 1:
Connect via RDP to physical node of WFC/stand alone machine where SQL instance is running

### Step 2:
- If SQL Instance is clustered move SQL resource group to the node you are connected.
Bring offline following resources:  SQL Server, SQL Server Agent, vName.
keep online: all disk resources and IP address resource.

- If SQL instance is stand-alone, stop SQL Server an SQL Server Agent services via SQL Configuration Manager.

### Step 3:
Open a command prompt with elevated privileges (run as administrator), navigate to Binn folder of SQL Server (usually `%Program Files%\Microsoft SQL Server\MSSQL<version>.<instance_name>\MSSQL\Binn\`), start SQL Server in single user mode with following command:
```
sqlservr.exe -s MSSQLSERVER -f -m"SQLCMD"
```

If SQL Server fails, the error can be deducted from the messages shown in the CMD itself:
```
2008-11-23 21:26:32.59 Server      Error: 17058, Severity: 16, State: 1.
2008-11-23 21:26:32.59 Server      initerrlog: Could not open error log file 'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\ERRORLOG'. Operating system error = 32(The process cannot access the file because it is being used by another process.).
2008-11-23 21:26:32.64 Server      Error: 17054, Severity: 16, State: 1.
2008-11-23 21:26:32.64 Server      The current event was not reported to the Windows Events log. Operating system error = 1502(The event log file is full.). You may need to clear the Windows Events log if it is full.
2008-11-23 21:26:32.95 Server      Error: 17058, Severity: 16, State: 1.
2008-11-23 21:26:32.95 Server      initerrlog: Could not open error log file 'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\ERRORLOG'. Operating system error = 32(The process cannot access the file because it is being used by another process.).
2008-11-23 21:26:33.26 Server      Error: 17058, Severity: 16, State: 1.
2008-11-23 21:26:33.26 Server      initerrlog: Could not open error log file 'C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\ERRORLOG'. Operating system error = 32(The process cannot access the file because it is being used by another process.).
```
Check command prompt is in elevated mode or try to start SQL Server instance as following (you have to set paths correctly):
```
sqlservr.exe -m -sMSSQLSERVER -d"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\master.mdf" -e"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Log\ERRORLOG" -l"C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\mastlog.ldf"
```
### Step 4:

Open a command prompt with elevated privileges (run as administrator), connect to SQL Server instance using SQLCMD with following command:
```
sqlcmd -S <IP_address>,<port> -E
```
- **stand alone default instance**, -S parameter can be omitted (run SQLCMD.EXE is enough);
- **stand alone named instance**, -S <servername\instancename> parameter must be specified;
- **cluster instance**, –S <vIP>,<port> parameter must be specified;

**vIP** and **port** value can be recovered from the failover cluster manager (no port), can be recovered from registry, from SQL Server configuration manager or from messages shown into CMD where you started SQL Server instance.

Alternatively to step 3 and 4 `dba_run_book_emergency_connection.ps1` PS script, appropriately configured, can be launched in an elevated mode PowerShell windows.
