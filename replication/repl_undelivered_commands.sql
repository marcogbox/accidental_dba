use distribution
GO

declare @xact_seqno varbinary(16)
select @xact_seqno = max(xact_seqno) from MSsubscriptions
inner join MSpublications
on MSpublications.publication_id = MSsubscriptions.publication_id
inner join MSdistribution_history
on MSdistribution_history.agent_id = MSsubscriptions.agent_id
Where Publication = 'cat_schede'

Print @xact_seqno

declare @str varchar(255)
set @str = master.dbo.fn_varbintohexstr (@xact_seqno)
set @str = left(@str, len(@str) - 8)

exec sp_browsereplcmds @xact_seqno_start = @str, @article_id = 32