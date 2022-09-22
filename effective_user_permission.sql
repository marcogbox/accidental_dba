EXECUTE AS login = '<user account>'

SELECT SUSER_NAME(), USER_NAME();
 
SELECT DISTINCT 'OBJECT Level Aggregate' AS entity_class,
        permission_name
FROM sys.objects
CROSS APPLY fn_my_permissions(QUOTENAME(NAME), 'OBJECT') a

SELECT 'OBJECT' AS entity_class,
        NAME,
        subentity_name,
        permission_name
FROM sys.objects
CROSS APPLY fn_my_permissions(QUOTENAME(NAME), 'OBJECT') a

SELECT 'DATABASE' AS entity_class,
        NAME,
        subentity_name,
        permission_name
FROM sys.databases
CROSS APPLY fn_my_permissions(QUOTENAME(NAME), 'DATABASE') a
WHERE name = '<db_name>'

SELECT 'SERVER' AS entity_class,
        @@SERVERNAME AS NAME,
        subentity_name,
        permission_name
FROM fn_my_permissions(NULL, 'SERVER')
 
REVERT