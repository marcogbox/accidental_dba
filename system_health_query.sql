SET NOCOUNT ON

IF (SUBSTRING(CAST(SERVERPROPERTY ('ProductVersion') AS varchar(50)),1,CHARINDEX('.',CAST(SERVERPROPERTY ('ProductVersion') AS varchar(50)))-1) >= 11)
BEGIN

DECLARE @UTDDateDiff int
SET @UTDDateDiff = DATEDIFF(mi,GETUTCDATE(),GETDATE())

-- Fetch information about the XEL file location
DECLARE @filename varchar(8000) ;
SELECT @filename = CAST(target_data as XML).value('(/EventFileTarget/File/@name)[1]', 'varchar(8000)')
FROM sys.dm_xe_session_targets
WHERE target_name = 'event_file' and event_session_address = (select address from sys.dm_xe_sessions where name = 'system_health');

SET @filename = 'C:\temp\system_health\system_health_0_132292464209770000.xel'
--SELECT SUBSTRING(@filename,1,CHARINDEX('system_health',@filename,1)-1) + '*.xel';
 
-- Read the XEL files to get the System Health Session Data
SELECT object_name,CAST(event_data as XML) as XMLData
INTO #tbl_sp_server_diagnostics
FROM sys.fn_xe_file_target_read_file(@filename, null, null, null)
WHERE object_name = 'sp_server_diagnostics_component_result'

SELECT
DATEADD(mi,@UTDDateDiff,XMLData.value('(/event/@timestamp)[1]','datetime')) as EventTime,
XMLData.value('(/event/data/text)[1]','varchar(255)') as Component,
XMLData.value('(/event/data/text)[2]','varchar(255)') as [State]
FROM #tbl_sp_server_diagnostics
WHERE  --XMLData.value('(/event/data/text)[2]','varchar(255)')  <> 'CLEAN'
/*and */XMLData.value('(/event/data/text)[1]','varchar(255)') = 'QUERY_PROCESSING'
ORDER BY EventTime DESC

SELECT
DATEADD(mi,@UTDDateDiff,XMLData.value('(/event/@timestamp)[1]','datetime')) as [Event Time],
XMLData.value('(/event/data/text)[1]','varchar(255)') as Component,
XMLData.value('(/event/data/value/queryProcessing/@maxWorkers)[1]','bigint') as [Max Workers],
XMLData.value('(/event/data/value/queryProcessing/@workersCreated)[1]','bigint') as [Workers Created],
XMLData.value('(/event/data/value/queryProcessing/@workersIdle)[1]','bigint') as [Idle Workers],
XMLData.value('(/event/data/value/queryProcessing/@pendingTasks)[1]','bigint') as [Pending Tasks],
XMLData.value('(/event/data/value/queryProcessing/@hasUnresolvableDeadlockOccurred)[1]','int') as [Unresolvable Deadlock],
XMLData.value('(/event/data/value/queryProcessing/@hasDeadlockedSchedulersOccurred)[1]','int') as [Deadlocked Schedulers],
XMLData
FROM #tbl_sp_server_diagnostics
WHERE XMLData.value('(/event/data/text)[1]','varchar(255)') = 'QUERY_PROCESSING'
--and XMLData.value('(/event/data/text)[2]','varchar(255)') <> 'CLEAN'
ORDER BY [Event Time] DESC

DROP TABLE #tbl_sp_server_diagnostics

END

SET NOCOUNT OFF
