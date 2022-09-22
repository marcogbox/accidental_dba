select DISTINCT
	s.name as schema_,
    t.name as tablename,
    u.type_desc,
    f.file_id,
    f.name,
    f.physical_name--,
    --f.size,
    --f.max_size,
    --f.growth,
    --u.total_pages,
    --u.used_pages,
    --u.data_pages,
    --p.partition_id,
    --p.rows
from sys.allocation_units u
    join sys.database_files f on u.data_space_id = f.data_space_id
    join sys.partitions p on u.container_id = p.hobt_id
	JOIN sys.tables t ON p.object_id = t.object_id
	join sys.schemas s ON t.schema_id = s.schema_id
where
    u.type in (1, 3)
	and physical_name LIKE '%DDS_STOCK%'
	--and OBJECT_NAME(p.object_id) = 'PageSplits'
GO
