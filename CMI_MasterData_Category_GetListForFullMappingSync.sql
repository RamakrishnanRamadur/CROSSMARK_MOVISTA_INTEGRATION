USE [CrossmarkMovistaIntegration]
GO
/****** Object:  StoredProcedure [dbo].[CMI_MasterData_Category_GetListForFullMappingSync]    Script Date: 8/15/2018 11:32:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CMI_MasterData_Category_GetListForFullMappingSync]
AS
BEGIN

	SET NOCOUNT ON;
	SELECT 
       [Manufacturer_Code] as manufacturer_id
      ,[Manufacturer_Name] as manufacturer_name
	  ,[Code] as category_id
      , Case when UPPER([IsActive_Name])= 'YES' Then 'ACTIVE' Else 'INACTIVE'  end as category_status
	  --,Name+' {'+  CAST(code AS nvarchar) +'}' AS category_title
	  ,Name  AS category_title
	  ,M.TargetEntityID,[SyncStatusDDID],SourceEntityID
	  ,Case when  PostedToMovista  IS NULL  Then '0' else PostedToMovista end as PostedToMovista
	FROM 
	 dbo.MasterEntityMap (nolock) AS M 
	INNER JOIN [PRODUCTCATALOGDBSERVER].MDS2.[mdm].[viw_PC_Category] AS C (nolock) ON C.Code = M.[SourceEntityID] and M.EntityTypeDDID = 114
	WHERE 
	M.SyncStatusDDID = 101 or (M.SyncStatusDDID  = 102 and SyncAttempts  < 5  )
	and C.Validationstatus= 'Validation Succeeded'
	-- 101 and 102 are Ready to Sync and SyncFailed respectively
	
END


