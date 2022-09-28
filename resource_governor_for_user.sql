-----------------------------------------------
-- Step 1: Create Resource Pool
-----------------------------------------------
-- Creating Resource Pool for BIDWH
CREATE RESOURCE POOL BIDWH_ResourcePool
WITH
( 
MIN_CPU_PERCENT=0,
MAX_CPU_PERCENT=30,
MIN_MEMORY_PERCENT=0,
MAX_MEMORY_PERCENT=30)
GO

-- Creating Workload Group for BIDWH
CREATE WORKLOAD GROUP BIDWH_WorkloadGroup
USING BIDWH_ResourcePool ;
GO


-----------------------------------------------
-- Step 3: Create UDF to Route Workload Group
-----------------------------------------------
CREATE FUNCTION dbo.RGClassifierByUserName()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
DECLARE @WorkloadGroup AS SYSNAME
IF(SUSER_NAME() = 'user_name')
SET @WorkloadGroup = 'BIDWH_WorkloadGroup'
ELSE
SET @WorkloadGroup = 'default'
RETURN @WorkloadGroup
END
GO

-----------------------------------------------
-- Step 4: Enable Resource Governer
-- with UDFClassifier
-----------------------------------------------
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION=dbo.RGClassifierByUserName);
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-- Check Pool of current sessions
SELECT
    Sess.session_id,
    Sess.program_name,
    Sess.host_name,
    Sess.login_name,
    Sess.nt_domain,
    Sess.nt_user_name,
    Sess.original_login_name,
    RG_WG.pool_id,
    RG_P.name as Pool_Name,
    Sess.group_id,
    RG_WG.name as WorkGroup_Name
FROM sys.dm_exec_sessions Sess
    INNER JOIN sys.dm_resource_governor_workload_groups RG_WG
        ON Sess.group_id = RG_WG.group_id
    INNER JOIN sys.dm_resource_governor_resource_pools RG_P
        ON RG_WG.pool_id = RG_P.pool_id
WHERE