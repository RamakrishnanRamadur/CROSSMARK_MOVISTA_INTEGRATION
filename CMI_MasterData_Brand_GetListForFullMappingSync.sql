USE [CrossmarkMovistaIntegration]
GO
/****** Object:  StoredProcedure [dbo].[CMI_MasterData_Brand_GetListForFullMappingSync]    Script Date: 8/15/2018 11:31:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CMI_MasterData_Brand_GetListForFullMappingSync]
AS
BEGIN

	SET NOCOUNT ON;
	SELECT 
	   [ImageURL] as imageurl
      ,[Manufacturer_Code] as manufacturer_id
      ,[Manufacturer_Name] as manufacturer_name
	  ,[Code] as brand_id
      ,Case when UPPER([IsActive_Name])= 'YES' Then 'ACTIVE' Else 'INACTIVE'  end as brand_status
	  --,Name+' {'+  CAST(code AS nvarchar) +'}' AS brand_title
	  ,Name AS brand_title
	  ,M.[TargetEntityID],[SyncStatusDDID],SourceEntityID
      ,Case when  PostedToMovista  IS NULL  Then '0' else PostedToMovista end as PostedToMovista
	FROM 
	 dbo.MasterEntityMap (nolock) AS M 
	INNER JOIN [PRODUCTCATALOGDBSERVER].MDS2.[mdm].[viw_PC_Brand] AS B (nolock) ON B.Code = M.[SourceEntityID] and M.EntityTypeDDID = 112
	WHERE 
	M.SyncStatusDDID = 101 or (M.SyncStatusDDID  = 102 and SyncAttempts  < 5  )
	-- 101 is POST or PUT ready  and 102 is Failed earlier 

END


