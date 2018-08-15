USE [CrossmarkMovistaIntegration]
GO
/****** Object:  StoredProcedure [dbo].[CMI_Common_Update_MovistaSyncStatus]    Script Date: 8/15/2018 11:39:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[CMI_Common_Update_MovistaSyncStatus]
(
     @SyncStatusDDID int
    , @EntityTypeID int
    , @SourceEntityID varchar(100)
    , @TargetEntityID varchar(100)
    , @BoomiProcessExecutionID varchar(100)
    , @Comments varchar(1024) = null
	, @MovistaID varchar(100)
)
as
begin

    set nocount on;
	declare @PostedToMovista bit
	declare @SyncAttempts int
	declare @OldSyncStatusDDID int
    begin try

	   begin transaction
	   --determine PUT or POST
	   select @PostedToMovista = PostedToMovista, @SyncAttempts=SyncAttempts,@OldSyncStatusDDID = SyncStatusDDID from dbo.MasterEntityMap where EntityTypeDDID = @EntityTypeID and SourceEntityID = @SourceEntityID
	   if(@PostedToMovista is  NULL or @PostedToMovista = 0  )  --IS Already synced Record
	      BEGIN 
		  set @Comments = 'POST : ' + @Comments
		  END
		  ELSE
		  BEGIN
		  set @Comments = 'PUT : ' + @Comments
		  END
 
          if(@OldSyncStatusDDID = 102 or @SyncStatusDDID = 102) --IS already Failed Record
			Set @SyncAttempts = @SyncAttempts + 1;

		  --The Call was success reset SyncAttempts and update the movistaid
		  if(@SyncStatusDDID = 103) 
	      begin
			 update dbo.MasterEntityMap 
			 set SyncStatusDDID = @SyncStatusDDID
				, LastProcessExecutionID = @BoomiProcessExecutionID
				, Comments = @Comments
				, DateUpdated = getdate()
				, MovistaEntityID = @MovistaID
				, PostedToMovista = 1
				, SyncAttempts = 0
			 where EntityTypeDDID = @EntityTypeID and SourceEntityID = @SourceEntityID   
		  end
		  else if(@SyncStatusDDID = 102) -- The call failed Ignore MovistaEntityID increment the SyncAttempts
		  	 begin
			 update dbo.MasterEntityMap 
			 set SyncStatusDDID = @SyncStatusDDID
				, LastProcessExecutionID = @BoomiProcessExecutionID
				, Comments = @Comments
				, DateUpdated = getdate()
				, SyncAttempts = @SyncAttempts
			 where EntityTypeDDID = @EntityTypeID and SourceEntityID = @SourceEntityID   
		  end

    
 
	   commit transaction
	     
    end try
    begin catch
	   if @@trancount > 0 
	   begin
		  rollback transaction
	   end
	   -- raise error
	   declare @ErrMsg varchar(4000), @ErrSeverity int
	   select  @ErrMsg = error_message(), @ErrSeverity = error_severity()
	   raiserror(@ErrMsg, @ErrSeverity, 1)
    end catch

end
