- Al Distributor
	=> Aggiungere come Publishers le due istanze (Primario e Secondario)
		
		exec sp_adddistpublisher 
				@publisher = N'DEVDRI02\VIKPOC01', 
				@distribution_db = N'distribution', 
				@security_mode = 1, 
				@working_directory = N'\\devdri04.ywebfarm.lcl\repldata', 
				@trusted = N'false', 
				@thirdparty_flag = 0, 
				@publisher_type = N'MSSQLSERVER'
		GO

		exec sp_adddistpublisher 
			@publisher = N'DEVDRI03\VIKPOC02', 
			@distribution_db = N'distribution', 
			@security_mode = 1, 
			@working_directory = N'\\devdri04.ywebfarm.lcl\repldata', 
			@trusted = N'false', 
			@thirdparty_flag = 0, 
			@publisher_type = N'MSSQLSERVER'
		GO
		
- Al Primario
	=> Aggiungere il distributor
		use master
		exec sp_adddistributor @distributor = N'DEVDRI04\DISTPOC', @password = N'Password01'
		GO
		
	=> Creare la Replica Merge	
		use [Fashion]
			exec sp_replicationdboption @dbname = N'Fashion', @optname = N'merge publish', @value = N'true'
			GO
			-- Adding the merge publication
			use [Fashion]
			exec sp_addmergepublication @publication = N'POC_NAV2013_DDT_Interface', 
			@description = N'Merge publication of database ''Fashion'' from Publisher ''DEVDRI02\VIKPOC01''.', 
			@sync_mode = N'native', 
			@retention = 14, 
			@allow_push = N'true', 
			@allow_pull = N'true', 
			@allow_anonymous = N'true',
			 @enabled_for_internet = N'false', 
			 @snapshot_in_defaultfolder = N'true',
			  @compress_snapshot = N'false', 
			  @ftp_port = 21, 
			  @allow_subscription_copy = N'false',
			   @add_to_active_directory = N'false', 
			   @dynamic_filters = N'false', 
			   @conflict_retention = 14, 
			   @keep_partition_changes = N'false', 
			   @allow_synctoalternate = N'false', 
			   @max_concurrent_merge = 0, 
			   @max_concurrent_dynamic_snapshots = 0, 
			   @use_partition_groups = null, 
			   @publication_compatibility_level = N'100RTM', 
			   @replicate_ddl = 1, 
			   @allow_subscriber_initiated_snapshot = N'false',
				@allow_web_synchronization = N'false', 
				@allow_partition_realignment = N'true', 
				@retention_period_unit = N'days', 
				@conflict_logging = N'both',
				 @automatic_reinitialization_policy = 0
			GO

			exec sp_addpublication_snapshot 
				@publication = N'POC_NAV2013_DDT_Interface', 
				@frequency_type = 1, @frequency_interval = 14, @frequency_relative_interval = 1, 
				@frequency_recurrence_factor = 0, @frequency_subday = 1, @frequency_subday_interval = 5, 
				@active_start_time_of_day = 500, @active_end_time_of_day = 235959, @active_start_date = 0, @active_end_date = 0,
				 @job_login = null, @job_password = null, @publisher_security_mode = 1

			-- NOTA: parametro @article_resolver => comanda il Subscriber
			use [Fashion]
			exec sp_addmergearticle @publication = N'POC_NAV2013_DDT_Interface', @article = N'DDT Interface', @source_owner = N'dbo', 
			@source_object = N'DDT Interface', @type = N'table', @description = N'', @creation_script = null, @pre_creation_cmd = N'truncate', 
			@schema_option = 0x000000010C034FD1, @identityrangemanagementoption = N'manual', @destination_owner = N'dbo', @force_reinit_subscription = 1, 
			@column_tracking = N'false', 
			@article_resolver = N'Microsoft SQL Server Subscriber Always Wins Conflict Resolver', 
			@subset_filterclause = null, @vertical_partition = N'false', @verify_resolver_signature = 0, @allow_interactive_resolver = N'false', 
			@fast_multicol_updateproc = N'true', @check_permissions = 0, @subscriber_upload_options = 0, @delete_tracking = N'true', @compensate_for_errors = N'false', 
			@stream_blob_columns = N'false', @partition_options = 0
			GO
			
			use [Fashion]
			exec sp_addmergesubscription @publication = N'POC_NAV2013_DDT_Interface', @subscriber = N'DEVDRB01\NAVPOC', @subscriber_db = N'PhoenixFashion', @subscription_type = N'Push', @sync_type = N'Automatic', @subscriber_type = N'Global', @subscription_priority = 75, @description = null, @use_interactive_resolver = N'False'
			exec sp_addmergepushsubscription_agent @publication = N'POC_NAV2013_DDT_Interface', @subscriber = N'DEVDRB01\NAVPOC', @subscriber_db = N'PhoenixFashion', @job_login = null, @job_password = null, @subscriber_security_mode = 1, @publisher_security_mode = 1, @frequency_type = 4, @frequency_interval = 1, @frequency_relative_interval = 1, @frequency_recurrence_factor = 1, @frequency_subday = 4, @frequency_subday_interval = 15, @active_start_time_of_day = 0, @active_end_time_of_day = 235959, @active_start_date = 20180627, @active_end_date = 99991231, @enabled_for_syncmgr = N'False'
			GO
			
			exec sp_addlinkedserver 'DEVDRB01\NAVPOC'
			GO
			
	- Al Secondario
		EXEC sp_adddistributor   @distributor = 'DEVDRI04\DISTPOC',  @password = 'Password01'; 
		GO

		exec sp_addlinkedserver 'DEVDRB01\NAVPOC'
		GO
		
		
	- Sul Distributor
		USE distribution;  
		GO  
		EXEC sys.sp_redirect_publisher   
		@original_publisher = 'DEVDRI02\VIKPOC01',  
			@publisher_db = 'Fashion',  
			@redirected_publisher = 'VIKPOCLSN'; 

		EXEC sys.sp_redirect_publisher   
		@original_publisher = 'DEVDRI03\VIKPOC02',  
			@publisher_db = 'Fashion',  
			@redirected_publisher = 'VIKPOCLSN'; 


		USE distribution;  
		GO  
		DECLARE @redirected_publisher sysname;  
		EXEC sys.sp_validate_replica_hosts_as_publishers  
			@original_publisher = 'DEVDRI02\VIKPOC01',  
			@publisher_db = 'Fashion',  
			@redirected_publisher = @redirected_publisher output;
		SELECT @redirected_publisher


		USE distribution;  
		GO  
		DECLARE @redirected_publisher sysname;  
		EXEC sys.sp_validate_replica_hosts_as_publishers  
			@original_publisher = 'DEVDRI03\VIKPOC02',  
			@publisher_db = 'Fashion',  
			@redirected_publisher = @redirected_publisher output;
		SELECT @redirected_publisher