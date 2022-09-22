use distribution
go
select * from MSrepl_errors order by time desc
GO

exec sp_browsereplcmds 'xact_seqno', 'xact_seqno'

/*
https://support.microsoft.com/en-us/help/3066750/how-to-troubleshoot-error-20598-the-row-was-not-found-at-the-subscribe
*/
