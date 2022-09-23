SELECT TOP( 50 )
	qs.execution_count AS [Execution Count],
	(SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		SUBSTRING(qt2.text,
		1+(CASE WHEN qs.statement_start_offset = 0 THEN 0 ELSE qs.statement_start_offset/2 END),
		1+(CASE WHEN qs.statement_end_offset = -1 THEN DATALENGTH(qt2.text) ELSE qs.statement_end_offset/2 END - (CASE WHEN qs.statement_start_offset = 0 THEN 0 ELSE qs.statement_start_offset/2 END))),
		NCHAR(1),N'?'),NCHAR(2),N'?'),NCHAR(3),N'?'),NCHAR(4),N'?'),NCHAR(5),N'?'),NCHAR(6),N'?'),NCHAR(7),N'?'),NCHAR(8),N'?'),NCHAR(11),N'?'),NCHAR(12),N'?'),NCHAR(14),N'?'),NCHAR(15),N'?'),NCHAR(16),N'?'),NCHAR(17),N'?'),NCHAR(18),N'?'),NCHAR(19),N'?'),NCHAR(20),N'?'),NCHAR(21),N'?'),NCHAR(22),N'?'),NCHAR(23),N'?'),NCHAR(24),N'?'),NCHAR(25),N'?'),NCHAR(26),N'?'),NCHAR(27),N'?'),NCHAR(28),N'?'),NCHAR(29),N'?'),NCHAR(30),N'?'),NCHAR(31),N'?')
		AS [text()]
		FROM sys.dm_exec_sql_text(qs.sql_handle) AS qt2
		FOR XML PATH(''), TYPE) Query_text

--,	CAST(t.[text] AS VARCHAR(MAX)) AS [Query Text]
,	qs.[last_grant_kb]
,	qs.[last_ideal_grant_kb]
,	qs.[last_used_grant_kb]
,	qs.[total_grant_kb]
,	qs.[last_dop]
,	qs.[last_used_threads]
INTO DBA..top_memory_grant
FROM
	sys.dm_exec_query_stats AS qs WITH (NOLOCK)
WHERE
	--DB_NAME(t.[dbid]) = 'AdventureWorks2014'
	--AND
	qs.[total_grant_kb] > 0
ORDER BY
	qs.[total_grant_kb] DESC
OPTION (RECOMPILE);
