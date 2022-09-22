CREATE VIEW [dbo].[dba_running_mg]
AS

WITH tsu AS (SELECT session_id, SUM(user_objects_alloc_page_count) AS user_objects_alloc_page_count, 
SUM(user_objects_dealloc_page_count) AS user_objects_dealloc_page_count, 
SUM(internal_objects_alloc_page_count) AS internal_objects_alloc_page_count, 
SUM(internal_objects_dealloc_page_count) AS internal_objects_dealloc_page_count FROM sys.dm_db_task_space_usage (NOLOCK) GROUP BY session_id)
SELECT es.session_id, DB_NAME(er.database_id) AS [database_name], OBJECT_NAME(qp.objectid, qp.dbid) AS [object_name],
	(SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		qt.text,
		NCHAR(1),N'?'),NCHAR(2),N'?'),NCHAR(3),N'?'),NCHAR(4),N'?'),NCHAR(5),N'?'),NCHAR(6),N'?'),NCHAR(7),N'?'),NCHAR(8),N'?'),NCHAR(11),N'?'),NCHAR(12),N'?'),NCHAR(14),N'?'),NCHAR(15),N'?'),NCHAR(16),N'?'),NCHAR(17),N'?'),NCHAR(18),N'?'),NCHAR(19),N'?'),NCHAR(20),N'?'),NCHAR(21),N'?'),NCHAR(22),N'?'),NCHAR(23),N'?'),NCHAR(24),N'?'),NCHAR(25),N'?'),NCHAR(26),N'?'),NCHAR(27),N'?'),NCHAR(28),N'?'),NCHAR(29),N'?'),NCHAR(30),N'?'),NCHAR(31),N'?') 
		AS [text()]
		FROM sys.dm_exec_sql_text(er.sql_handle) AS qt
		FOR XML PATH(''), TYPE) AS [running_batch],
	(SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		SUBSTRING(qt2.text,
		1+(CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END),
		1+(CASE WHEN er.statement_end_offset = -1 THEN DATALENGTH(qt2.text) ELSE er.statement_end_offset/2 END - (CASE WHEN er.statement_start_offset = 0 THEN 0 ELSE er.statement_start_offset/2 END))),
		NCHAR(1),N'?'),NCHAR(2),N'?'),NCHAR(3),N'?'),NCHAR(4),N'?'),NCHAR(5),N'?'),NCHAR(6),N'?'),NCHAR(7),N'?'),NCHAR(8),N'?'),NCHAR(11),N'?'),NCHAR(12),N'?'),NCHAR(14),N'?'),NCHAR(15),N'?'),NCHAR(16),N'?'),NCHAR(17),N'?'),NCHAR(18),N'?'),NCHAR(19),N'?'),NCHAR(20),N'?'),NCHAR(21),N'?'),NCHAR(22),N'?'),NCHAR(23),N'?'),NCHAR(24),N'?'),NCHAR(25),N'?'),NCHAR(26),N'?'),NCHAR(27),N'?'),NCHAR(28),N'?'),NCHAR(29),N'?'),NCHAR(30),N'?'),NCHAR(31),N'?') 
		AS [text()]
		FROM sys.dm_exec_sql_text(er.sql_handle) AS qt2
		FOR XML PATH(''), TYPE) AS [running_statement],
	--ot.task_state AS [status],
	er.status,
	er.command,
	--er.command,
	qp.query_plan,
	CASE WHEN qes.query_plan IS NULL THEN 'Lightweight Query Profiling Infrastructure is not enabled' ELSE qes.query_plan END AS [live_query_plan_snapshot],
	er.percent_complete,
	CONVERT(VARCHAR(20),DATEADD(ms,er.estimated_completion_time,GETDATE()),20) AS [ETA_completion_time],
	(er.cpu_time/1000) AS cpu_time_sec,
	(er.reads*8)/1024 AS physical_reads_KB,
	(er.logical_reads*8)/1024 AS logical_reads_KB,
	(er.writes*8)/1024 AS writes_KB,
	(er.total_elapsed_time/1000)/60 AS elapsed_minutes,
	er.wait_type,
	er.wait_resource,
	er.last_wait_type,
	(SELECT CASE
		WHEN pageid = 1 OR pageid % 8088 = 0 THEN 'Is_PFS_Page'
		WHEN pageid = 2 OR pageid % 511232 = 0 THEN 'Is_GAM_Page'
		WHEN pageid = 3 OR (pageid - 1) % 511232 = 0 THEN 'Is_SGAM_Page'
		WHEN pageid IS NULL THEN NULL
		ELSE 'Is_not_PFS_GAM_SGAM_page' END
	FROM (SELECT CASE WHEN er.[wait_type] LIKE 'PAGE%LATCH%' AND er.[wait_resource] LIKE '%:%'
		THEN CAST(RIGHT(er.[wait_resource], LEN(er.[wait_resource]) - CHARINDEX(':', er.[wait_resource], LEN(er.[wait_resource])-CHARINDEX(':', REVERSE(er.[wait_resource])))) AS int)
		ELSE NULL END AS pageid) AS latch_pageid
	) AS wait_resource_type,
	er.wait_time AS wait_time_ms,
	er.cpu_time AS cpu_time_ms,
	er.open_transaction_count,
	DATEADD(s, (er.estimated_completion_time/1000), GETDATE()) AS estimated_completion_time,
	CASE WHEN mg.wait_time_ms IS NULL THEN DATEDIFF(ms, mg.request_time, mg.grant_time) ELSE mg.wait_time_ms END AS [grant_wait_time_ms],
	LEFT (CASE COALESCE(er.transaction_isolation_level, es.transaction_isolation_level)
		WHEN 0 THEN '0-Unspecified'
		WHEN 1 THEN '1-ReadUncommitted'
		WHEN 2 THEN '2-ReadCommitted'
		WHEN 3 THEN '3-RepeatableRead'
		WHEN 4 THEN '4-Serializable'
		WHEN 5 THEN '5-Snapshot'
		ELSE CONVERT (VARCHAR(30), er.transaction_isolation_level) + '-UNKNOWN'
    END, 30) AS transaction_isolation_level,
	mg.requested_memory_kb,
	mg.granted_memory_kb,
	mg.ideal_memory_kb,
	mg.query_cost,
	((((ssu.user_objects_alloc_page_count + tsu.user_objects_alloc_page_count) -
		(ssu.user_objects_dealloc_page_count + tsu.user_objects_dealloc_page_count))*8)/1024) AS user_obj_in_tempdb_MB,
	((((ssu.internal_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) -
		(ssu.internal_objects_dealloc_page_count + tsu.internal_objects_dealloc_page_count))*8)/1024) AS internal_obj_in_tempdb_MB,
	es.[host_name],
	es.login_name,
	--es.original_login_name,
	es.[program_name],
	--ec.client_net_address,
	es.is_user_process,
	g.name AS workload_group
FROM sys.dm_exec_requests (NOLOCK) er
	LEFT OUTER JOIN sys.dm_exec_query_memory_grants (NOLOCK) mg ON er.session_id = mg.session_id AND er.request_id = mg.request_id
	LEFT OUTER JOIN sys.dm_db_session_space_usage (NOLOCK) ssu ON er.session_id = ssu.session_id
	LEFT OUTER JOIN sys.dm_exec_sessions (NOLOCK) es ON er.session_id = es.session_id
	LEFT OUTER JOIN tsu ON tsu.session_id = ssu.session_id
	LEFT OUTER JOIN sys.dm_resource_governor_workload_groups (NOLOCK) g ON es.group_id = g.group_id
	OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) qp 
	OUTER APPLY sys.dm_exec_query_statistics_xml(er.session_id) qes
WHERE er.session_id <> @@SPID AND es.is_user_process = 1

GO
