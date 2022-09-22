:connect <primary>
select primary_server, primary_database, last_backup_file, last_backup_date, lsn
from msdb..log_shipping_monitor_primary m
JOIN
(
	SELECT
	b.database_name, Max(b.last_lsn) AS lsn
	FROM msdb..backupset b
	GROUP BY b.database_name
) as l ON m.primary_database = l.database_name
ORDER BY 2
GO

:connect <secondary>
select secondary_server, secondary_database, last_copied_file, last_copied_date, last_restored_file, last_restored_date, lsn
from msdb..log_shipping_monitor_secondary m
JOIN
(
	SELECT
	A.destination_database_name, Max(b.last_lsn) AS lsn
	FROM msdb..restorehistory a
	INNER JOIN msdb..backupset b ON a.backup_set_id = b.backup_set_id
	GROUP BY A.destination_database_name
) as l ON m.secondary_database = l.destination_database_name
ORDER BY 2
GO
