USE [distribution]
GO

CREATE VIEW [dbo].[ArticleList_mg]
AS
SELECT [MSpublications].publisher_db, [MSpublications].publication, [MSarticles].source_object AS a, [MSarticles].destination_object as b --, subscriber_id
	, subscriber_id as nomesub, [MSarticles].article_id, [MSreplservers].srvname
from [distribution].[dbo].[MSpublications]
inner join [distribution].[dbo].[MSarticles] on [MSarticles].publication_id = [MSpublications].publication_id
inner join [distribution].[dbo].[MSsubscriptions] on [MSarticles].publication_id = [MSsubscriptions].publication_id
	and [MSarticles].article_id = [MSsubscriptions].article_id
	and subscriber_db <> 'virtual'
JOIN [distribution].[dbo].[MSreplservers] on [MSsubscriptions].subscriber_id = [MSreplservers].srvid
GO

