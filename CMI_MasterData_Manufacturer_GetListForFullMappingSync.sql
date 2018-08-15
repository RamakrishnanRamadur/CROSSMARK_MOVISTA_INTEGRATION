USE [CrossmarkMovistaIntegration]
GO
/****** Object:  StoredProcedure [dbo].[CMI_MasterData_Manufacturer_GetListForFullMappingSync]    Script Date: 8/15/2018 11:29:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CMI_MasterData_Manufacturer_GetListForFullMappingSync]
AS
BEGIN

	SET NOCOUNT ON;
	SELECT 
	   [ImageURL] as imageurl
      ,[Code] as manufacturer_id
      , Case when UPPER([IsActive_Name])= 'YES' Then 'ACTIVE' Else 'INACTIVE'  end as manufacturer_status
	  --,Name+' {'+  CAST(code AS nvarchar) +'}' AS manufacturer_title
	  ,Name AS manufacturer_title
	  ,M.[TargetEntityID],[SyncStatusDDID],SourceEntityID
	  ,Case when  PostedToMovista  IS NULL  Then '0' else PostedToMovista end as PostedToMovista
	FROM 
	 dbo.MasterEntityMap (nolock) AS M 
	INNER JOIN [PRODUCTCATALOGDBSERVER].MDS2.[mdm].[viw_PC_Manufacturer]  AS Mf (nolock) ON Mf.Code = M.[SourceEntityID] and M.EntityTypeDDID = 113
	WHERE 
	M.SyncStatusDDID  = 101 or (M.SyncStatusDDID  = 102 and SyncAttempts  < 5  )
	-- 101 is POST or PUT ready  and 102 is Failed earlier 

END


