select g.name,  DB_NAME(database_id) db_name, r.replica_server_name, s.redo_queue_size, s.redo_rate, s.last_redone_time,s.* 
from sys.dm_hadr_database_replica_states s JOIN sys.availability_groups g on s.group_id = g.group_id
JOIN sys.availability_replicas r ON s.replica_id = r.replica_id
ORDER BY database_id, g.name
