USE [CrossmarkMovistaIntegration]
GO
/****** Object:  StoredProcedure [dbo].[CMI_MasterData_Product_PrepareSyncList]    Script Date: 8/15/2018 11:26:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CMI_MasterData_Product_PrepareSyncList]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @LastSyncTime DATETIME
	DECLARE @ProductList TABLE (
		RowID INT IDENTITY(1, 1)
		,EnterpriseProductIdentifier VARCHAR(100),LastChgDateTime datetime,IsActive_Name varchar(5)
		)
	DECLARE @RemoteServerTimeTable TABLE (
		CurrentTime DATETIME
		)
	DECLARE @CurrentTime DATETIME
	DECLARE @CurrentTargetEntityID VARCHAR(100)
	DECLARE @CurrentCount INT
	DECLARE @LOOP_EnterpriseProductIdentifier VARCHAR(100)
	DECLARE @LOOP_IsActive_Name VARCHAR(5)
	DECLARE @TotalRowCount INT		,@CurrentRowID INT

BEGIN TRY
	BEGIN TRANSACTION

	--get and set Productcatepog RemoteServerTime 	
	INSERT INTO @RemoteServerTimeTable (CurrentTime) (SELECT* FROM OPENQUERY([PRODUCTCATALOGDBSERVER], 'SELECT getdate()') )

	--get and set last sync time
	SELECT @LastSyncTime = LastSyncTimestamp
	FROM [ProcessMaster](NOLOCK)
	WHERE  ID = 1009

	--Prepare product list from productcatalog and set number of products to insert / update	 
	INSERT INTO @ProductList (EnterpriseProductIdentifier,LastChgDateTime,IsActive_Name)
	SELECT top 10 Code,LastChgDateTime, IsActive_Name
	FROM  [PRODUCTCATALOGDBSERVER].[MDS2].[mdm].[viw_PC_Product]
	WHERE (
			((LastChgDateTime IS NOT NULL) AND (LastChgDateTime >@LastSyncTime))
			and Validationstatus= 'Validation Succeeded' and IsActive_code = '1'
			)

	SELECT @TotalRowCount = COUNT(*)
	FROM @ProductList

	--process the prepared list	
	SELECT @CurrentRowID = 1

	WHILE @CurrentRowID <= @TotalRowCount
	BEGIN

		--get manufacturer source id from product cataloag list
		SELECT @LOOP_EnterpriseProductIdentifier = EnterpriseProductIdentifier,@LOOP_IsActive_Name =IsActive_Name 
		FROM @ProductList
		WHERE RowID = @CurrentRowID
 
		--set the Target ID
		SELECT @CurrentTargetEntityID = 'PR'+@LOOP_EnterpriseProductIdentifier
		FROM [MasterEntityMap](NOLOCK)
		WHERE [SourceEntityID] = @LOOP_EnterpriseProductIdentifier
		AND [EntityTypeDDID] = 111

		--check if not exist the insert, set 101 and reset sync count
		--else update set 101 and 
		SELECT @CurrentCount = COUNT(1)
		FROM [MasterEntityMap](NOLOCK)
		WHERE [SourceEntityID] = @LOOP_EnterpriseProductIdentifier
		AND [EntityTypeDDID] = 111
		--print @CurrentCount
		IF (@CurrentCount < 1)
		BEGIN
			INSERT INTO [dbo].[MasterEntityMap] (
				[EntityTypeDDID]
				,[SourceEntityID]
				,[SyncStatusDDID]
				,[TargetEntityID]
				,[DateCreated]
				,[DateUpdated]
				,[SyncAttempts]
				)
			VALUES (
				'111'
				,@LOOP_EnterpriseProductIdentifier
				,CASE when upper(@LOOP_IsActive_Name)= 'YES' then 101 else 104 end
				,'PR'+cast(@LOOP_EnterpriseProductIdentifier as varchar),getdate(),getdate()
				,0
				)
				--101 is ready to sync
		END
		ELSE
		BEGIN
			UPDATE [dbo].[MasterEntityMap]
			SET [SyncStatusDDID] = 101
			WHERE [SourceEntityID] = @LOOP_EnterpriseProductIdentifier
			AND [EntityTypeDDID] = 111
		END

		SET @CurrentRowID = @CurrentRowID + 1
	END
 
 	-- update processmaster last sync time
	UPDATE [CrossmarkMovistaIntegration].[dbo].[ProcessMaster]
	SET [LastSyncTimestamp] = (SELECT CurrentTime FROM @RemoteServerTimeTable)
	WHERE ID = 1009

	SELECT @TotalRowCount

COMMIT TRANSACTION

END TRY

BEGIN CATCH
		IF @@TRANCOUNT > 0 
			BEGIN
				ROLLBACK TRANSACTION
			END

		--Raise Error
		DECLARE @ErrMsg varchar(4000), @ErrSeverity int
		SELECT   @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()
		RAISERROR (@ErrMsg, @ErrSeverity, 1)
END CATCH

		--SELECT * FROM [tblMasterDataEntityMap] WHERE EntityType_DDID = 111
END