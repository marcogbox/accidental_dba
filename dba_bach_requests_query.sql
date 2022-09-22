DECLARE @v1 BIGINT, @delay SMALLINT = 5, @time DATETIME;

SELECT @time = DATEADD(SECOND, @delay, '00:00:00');
 
SELECT @v1 = cntr_value 
FROM master.sys.dm_os_performance_counters
WHERE counter_name = 'Batch Requests/sec';
 
WAITFOR DELAY @time;
 
SELECT (cntr_value - @v1)/@delay
FROM master.sys.dm_os_performance_counters
WHERE counter_name='Batch Requests/sec';