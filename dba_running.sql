CREATE view [dbo].[dba_running] 
AS
wWITHith cte( [Spid]  ,[DB] ,[utente]  ,[status]  ,[Wait]  ,[blocked] ,[IndQuery] ,[ParQuery]  ,[Program] ,[open_tran]  ,[Hostname] ,[nt_domain]  ,[start_time]  ,[estfinish] ) as
(
SELECT[Spid] = session_Id
	, [DB] = ltrim(rtrim(DB_NAME(sp.dbid)))
	--, case when coalesce (loginame, nt_username) = '' then ltrim(rtrim(nt_username)) else ltrim(rtrim(coalesce (loginame, nt_username))) end as [utente]
	, loginame AS utente 
	, [status] = ltrim(rtrim(er.status))
	, [Wait] = ltrim(rtrim(wait_type))
	, [blocked] = blocked
	, [IndQuery] = ltrim(rtrim(SUBSTRING (qt.text, 
             er.statement_start_offset/2,
	(CASE WHEN er.statement_end_offset = -1
	       THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
		ELSE er.statement_end_offset END - 
                                er.statement_start_offset)/2)))
	,[ParQuery] = ltrim(rtrim(qt.text))
	, CASE WHEN program_name  LIKE 'SQLAgent - TSQL JobStep (Job % : Step%'  THEN
		( SELECT  ltrim(rtrim('JOB ' + [name] + ' Step: ' +  replace (right (ltrim(rtrim(program_name)), 3), ')', '')))
		FROM msdb.dbo.sysjobs AS j WHERE j.job_id =
		convert (BINARY(16), substring(program_name,30,34) ,1 )  ) 
		ELSE  ltrim(rtrim(program_name)) END AS Program
	, [open_tran] = open_tran
	, ltrim(rtrim(Hostname)) AS Hostname
	, ltrim(rtrim(nt_domain)) AS nt_domain
	, start_time,  
	CASE WHEN estimated_completion_time = 0 THEN NULL ELSE 
	dateadd(second,estimated_completion_time/1000, getdate()) END AS estfinish
    FROM sys.dm_exec_requests er
    INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
    WHERE session_Id > 50             
    AND session_Id NOT IN (@@SPID)
),
 grouped AS (
SELECT   [Spid], count(spid) AS parall
      ,[DB],[IndQuery],[status] ,[Wait]
      ,max([blocked]) AS blocked,[Program],[Hostname]
      ,rtrim(ltrim(max([utente]))) AS utente,[start_time]
      ,[estfinish],sum([open_tran]) AS [open_tran]    
      ,[ParQuery],left(replace(replace(replace ([IndQuery], CHAR(10), ''), CHAR(13), ''), CHAR(9), ''), 200) AS ExcelQuery
    ,[nt_domain]
       
  FROM cte 
  group by [Spid]
      ,[DB]
      ,[status]
      ,[Wait]
      ,[IndQuery]
      ,[ParQuery]
      ,[Program]
      ,[Hostname]
      ,[nt_domain]
      ,[start_time]
      ,[estfinish]
  )
,task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
 , getplans as(
SELECT TSU.session_id,
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
--OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE --EST.text IS NOT NULL OR 
EQP.query_plan IS NOT NULL )
                

SELECT 
	[Spid], parall ,[DB],[IndQuery],[status] ,[Wait], blocked,[Program],[Hostname], utente, query_plan, [internal object MB space],  [internal object dealloc MB space],
	[start_time] ,[estfinish], [open_tran] ,[ParQuery], ExcelQuery ,[nt_domain] 
FROM grouped 
LEFT JOIN  getplans ON getplans.session_id = grouped.spid
GO