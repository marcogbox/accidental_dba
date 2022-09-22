# force command deletion from distributor DB

This query returns the descending list of xact_seqno before the date set in the where condition, the major must be taken into account

```sql
SELECT top 100 * FROM MSrepl_transactions
WHERE publisher_database_id = 4 AND entry_time <= '2019-08-05'
ORDER BY entry_time DESC
```
**sp_MSdelete_publisherdb_trans** performs the cleanup without any check of all the commands and transactions queued in the distributor, prior to the passed xact_seqno.

Use the xact_seqno value returned by the previous query.

**ATTENTION: the command could cancel commands not yet delivered and break some subscriptions**
```sql
DECLARE @num_transactions INT, @num_commands INT

EXEC [dbo].[sp_MSdelete_publisherdb_trans]
    @publisher_database_id = 4,
    @max_xact_seqno = 0x004D467A0000C7920009,
	@max_cutoff_time ='2019-08-05',
    @num_transactions = @num_transactions,
    @num_commands = @num_commands
```

The following query is extracted from the stored procedure sp_MSmaximum_cleanup_seqno, returns the maximum xact_seqno which can be deleted without breaking any subscriptions.

The first xact_seqno returned is the one related to the subscription with the lowest xact_seqno.

The second xact_seqno returned if null indicates that the subscription identified by the previous xact_seqno is blocking the normal cleanup, otherwise if a value is returned it indicates that the cleanup is not blocked and it will delete all commands and transactions preceding the returned xact_seqno.

```sql
    DECLARE
    	@publisher_database_id int = <publisher_database_id>,
    	@min_cutoff_time datetime = dateadd(hour, -48, getdate()),
    	@max_cleanup_xact_seqno varbinary(16)

    	declare @min_agent_sub_xact_seqno varbinary(16)
    				,@max_agent_hist_xact_seqno varbinary(16)
    				,@active int
    				,@initiated int
    				,@agent_id int
    				,@min_xact_seqno varbinary(16)


    	-- set @min_xact_seqno to NULL and reset it with the first prospect of min_seqno we found later
    	select @min_xact_seqno = NULL

    	set nocount on

    	select @active = 2
    	select @initiated = 3

    	--
    	-- cursor through each agent with it's smallest sub xact seqno
    	--
    	declare #tmpAgentSubSeqno cursor local forward_only  for
    	select a.id, min(s2.subscription_seqno) from
                            MSsubscriptions s2
                            join MSdistribution_agents a
                            on (a.id = s2.agent_id)
                            where
    	                        s2.status in( @active, @initiated ) and
    	                        /* Note must filter out virtual anonymous agents !!!
                                          a.subscriber_id <> @virtual_anonymous and */
                                -- filter out subscriptions to immediate_sync publications
                                not exists (select * from MSpublications p where
                                            s2.publication_id = p.publication_id and
                                            p.immediate_sync = 1) and
    	                        a.publisher_database_id = @publisher_database_id
    	                        group by a.id
    	open #tmpAgentSubSeqno
    	fetch #tmpAgentSubSeqno into @agent_id, @min_agent_sub_xact_seqno

        if (@@fetch_status = -1) -- rowcount = 0 (no subscriptions)
        begin
            -- If we have a publication which allows for init from backup with a min_autonosync_lsn set
            --   we don't want this proc to signal cleanup of all commands
            -- Note that if we filter out immediate_sync publications here as they will already have the
            --   desired outcome.  The difference is that those with min_autonosync_lsn set have a watermark
            --   at which to begin blocking cleanup.
    		if not exists (select * from dbo.MSpublications msp
                    join MSpublisher_databases mspd ON mspd.publisher_id = msp.publisher_id
                        and mspd.publisher_db = msp.publisher_db
                    where mspd.id = @publisher_database_id and msp.immediate_sync = 1)
    		begin
                select top(1) @min_xact_seqno = msp.min_autonosync_lsn from dbo.MSpublications msp
                        join MSpublisher_databases mspd ON mspd.publisher_id = msp.publisher_id
                            and mspd.publisher_db = msp.publisher_db
                        where mspd.id = @publisher_database_id
                            and msp.allow_initialize_from_backup <> 0
                            and msp.min_autonosync_lsn is not null
                            and msp.immediate_sync = 0
    					order by msp.min_autonosync_lsn asc
    		end
        end

        while (@@fetch_status <> -1)
    	begin
    	    --
    	    --always clear the local variable, next query may not return any resultset
    	    --
    	    set @max_agent_hist_xact_seqno = NULL

    	    --
    	    --find last history entry for current agent, if no history then the query below should leave @max_agent_xact_seqno as NULL
    	    --
    	    select top 1 @max_agent_hist_xact_seqno = xact_seqno from MSdistribution_history where agent_id = @agent_id
    	             order by timestamp desc

    	    --
    	    --now find the last xact_seqno this agent has delivered:
    	    --if last history was written after initsync, use histry xact_seqno otherwise use initsync xact_seqno
    	    --
    	    if isnull(@max_agent_hist_xact_seqno, @min_agent_sub_xact_seqno) <= @min_agent_sub_xact_seqno
    	    begin
    	         set @max_agent_hist_xact_seqno = @min_agent_sub_xact_seqno
    	    end
    	    --@min_xact_seqno was set to NULL to start with, the first time we get here, it'll gets set to a non-NULL value
    	    --then we graduately move to the smallest hist/sub seqno
    	    if ((@min_xact_seqno is null) or (@min_xact_seqno > @max_agent_hist_xact_seqno))
    	    begin
    	        set @min_xact_seqno = @max_agent_hist_xact_seqno
    	    end
    	    fetch #tmpAgentSubSeqno into @agent_id, @min_agent_sub_xact_seqno
    	end
    	close #tmpAgentSubSeqno
    	deallocate #tmpAgentSubSeqno

    	/*
    	** Optimized query to get the maximum cleanup xact_seqno
    	*/
    	/*
    	** If the query below returns nothing, nothing can be deleted.
    	** Reset @max_cleanup_xact_seqno to 0.
    	*/
    	SELECT @min_xact_seqno

    --	select @max_cleanup_xact_seqno = 0x00
    	-- Use top 1 to avoid warning message of "Null in aggregate..." which will make
    	-- sqlserver agent job having failing status
    	select top 1 xact_seqno
    	    from MSrepl_transactions with (nolock)
    	    where
    	        publisher_database_id = @publisher_database_id and
    	        (xact_seqno < @min_xact_seqno
    	        	or @min_xact_seqno IS NULL) and
    	        entry_time <= @min_cutoff_time
    	        order by xact_seqno desc
```

This query, with xact_seqno extracted from the previous query, returns the subscription that is blocking the cleanup

```sql
SELECT DISTINCT a.name, h.* FROM
(
	SELECT agent_id, MAX(xact_seqno) xact_seqno FROM MSdistribution_history
	GROUP BY agent_id
) h
JOIN MSdistribution_agents a ON h.agent_id = a.id
where xact_seqno = <xact_seqno>
```

```sql
SELECT DISTINCT h.xact_seqno, a.* FROM
(
	SELECT agent_id, MAX(xact_seqno) xact_seqno FROM MSdistribution_history
	GROUP BY agent_id
) h
JOIN MSdistribution_agents a ON h.agent_id = a.id
where xact_seqno = 0x00000000000000000000000000000000
and publisher_database_id = <publisher_database_id>
and subscriber_db <> 'virtual'
```
