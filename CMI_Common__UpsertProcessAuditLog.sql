USE [CrossmarkMovistaIntegration]
/****** Object:  StoredProcedure [dbo].[CMI_Common__UpsertProcessAuditLog]    Script Date: 8/15/2018 11:44:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[CMI_Common__UpsertProcessAuditLog]
(
    @ProcessID  int
  , @ExecutionID as varchar(100)
  , @StatusID int
  , @StartTime datetime
  , @EndTime datetime
  , @Comments varchar(1024) = null
)
as
begin

    set nocount on;
	Declare @oldComments varchar(1024)
    begin try
	   begin transaction

	   --if not exist insert the process audit log
	   if not Exists (Select id FROM dbo.ProcessAuditLog where LastProcessExecutionID =@ExecutionID  )
	   begin
		   insert into dbo.ProcessAuditLog (ProcessID, StartDate, ProcessStateDDID, LastProcessExecutionID, Comments)
		   values (@ProcessID, @StartTime, @StatusID, @ExecutionID, @Comments)
	   end
	   else  --if   exist update the process audit log
	   BEGIN
	       --Select @oldComments = Comments FROM dbo.ProcessAuditLog where LastProcessExecutionID =@ExecutionID 
		   --set @Comments = @oldComments + '::' + @Comments
	   	   update dbo.ProcessAuditLog
		   set ProcessStateDDID = @StatusID
			  , EndDate = @EndTime
			  , Comments = isnull(@Comments, '')  
		   where LastProcessExecutionID = @ExecutionID

		   -- if the process run is successful update LastSyncTimestamp and DateUpdated
		   if (@StatusID = 103) 
		   begin
			  update dbo.ProcessMaster
			  set LastSyncTimestamp = @StartTime
				 , DateUpdated = getdate()
			  where ID = @ProcessID
		   end
		   END
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
