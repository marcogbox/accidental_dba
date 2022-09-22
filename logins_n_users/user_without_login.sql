EXECUTE master.sys.sp_MSforeachdb 'USE [?];
IF(EXISTS(select * from sys.sysusers u LEFT JOIN master.sys.syslogins l ON u.sid = l.sid
where l.sid IS NULL AND issqlrole = 0 AND u.isntname = 1 AND u.name != ''dbo''))
BEGIN
	select ''?'',* from sys.sysusers u LEFT JOIN master.sys.syslogins l ON u.sid = l.sid
	where l.sid IS NULL AND issqlrole = 0 AND u.isntname = 1 --AND u.name != ''dbo'' --AND hasdbaccess = 1
	ORDER BY 4
END'
GO