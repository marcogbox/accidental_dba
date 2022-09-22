USE distribution
GO

SELECT *
FROM MSarticles a (NOLOCK) JOIN MSpublications p (NOLOCK) ON a.publication_id = p.publication_id
WHERE publication = '<publication_name>'

select DATEDIFF(hour, t.entry_time, GETDATE()) as hours_old, COUNT(*) AS no_of_commands
from msrepl_transactions t (nolock)
join msrepl_commands c (nolock) on t.xact_seqno = c.xact_seqno
WHERE c.article_id = 97
GROUP BY DATEDIFF(hour, t.entry_time, GETDATE())
ORDER BY 1

select distinct @@SERVERNAME as ServerName, a.article_id, a.Article, p.Publication, SUBSTRING(agents.[name], 16, 35) as [Name], s.agent_id, s.UndelivCmdsInDistDB, s.DelivCmdsInDistDB, UndelivCmdsInDistDB + DelivCmdsInDistDB as TotalTrans
from dbo.MSdistribution_status(nolock) as s
inner join dbo.MSdistribution_agents(nolock) as agents on agents.[id] = s.agent_id
inner join dbo.MSpublications(nolock) as p on p.publication = agents.publication
inner join dbo.MSarticles(nolock) as a on a.article_id = s.article_id
	and p.publication_id = a.publication_id
where 1 = 1
	and s.UndelivCmdsInDistDB <> 0
	and agents.subscriber_db not like 'virtual'
