:connect <server_name>
USE [master]
GO
IF NOT EXISTS(select * from sys.syslogins WHERE name = '<user_name>') CREATE LOGIN [<user_name>]] FROM WINDOWS WITH DEFAULT_DATABASE=[master];
GO
USE <DB_name>
GO
IF NOT EXISTS(select * from sys.sysusers WHERE name = '<user_name>') CREATE USER [<user_name>] FOR LOGIN [<user_name>];
-- 2008 version
EXEC sp_addrolemember N'db_datareader',  N'<user_name>'
-- >= 2012 version
ALTER ROLE [db_datareader] ADD MEMBER [<user_name>]
GO
