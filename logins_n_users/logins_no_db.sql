USE MASTER; 

CREATE TABLE #dbusers ( 
  sid VARBINARY(85)) 

EXEC sp_MSforeachdb 
  'insert #dbusers select sid from [?].sys.database_principals where type != ''R''' 

SELECT name, 'DROP LOGIN [' + name + ']'
FROM   sys.server_principals 
WHERE  sid IN (
	SELECT a.sid FROM sys.server_principals a 
	LEFT JOIN sys.server_role_members b ON b.member_principal_id = a.principal_id
	--LEFT JOIN sys.server_principals c ON c.principal_id = b.role_principal_id
	WHERE b.member_principal_id IS NULL AND a.type IN ('G', 'U', 'S')
    EXCEPT 
    SELECT DISTINCT sid 
    FROM   #dbusers
) 
ORDER BY name
GO 

DROP TABLE #dbusers 