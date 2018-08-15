USE [CrossmarkMovistaIntegration]
GO
/****** Object:  StoredProcedure [dbo].[CMI_MasterData_Product_GetListForFullMappingSync]    Script Date: 8/15/2018 11:33:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CMI_MasterData_Product_GetListForFullMappingSync] 
AS
BEGIN

	SET NOCOUNT ON;

			

	SELECT 
	   [UPC-A] as upc
      ,case when [ImageURL] is null then '' else [ImageURL]  end as imageurl
      ,[Code] as product_id
      ,[Manufacturer_Code] as manufacturer_id 
      ,[Manufacturer_Name] as manufacturer_name
      ,[Brand_Code] as brand_id 
      ,[Brand_Name] + ' {MFR: '+  manufacturer_name +'}' as brand_name
      ,[CMK Product Description] as cmk_product_description
      ,case when ([UPC-E] is null or [UPC-E] = '') then '' else [UPC-E]  end   as upc_e
      ,case when ([EAN-13] is null or [EAN-13] = '') then '' else [EAN-13]  end as ean_13
      ,case when ([EAN-14] is null or [EAN-14] = '') then '' else [EAN-14]  end as  ean_14
      ,[ContentsAmount] as contents_amount
      ,[Unit_Name] as unit
      ,[CasePack] as case_pack
      ,[Category_Code] as category_id 
	  ,	Case When category_name IS NULL then NULL
			else category_name  + ' {MFR: '+  manufacturer_name +'}' END AS category_name
      ,[IsActive_Code] as product_status_id
      , Case when UPPER([IsActive_Name])= 'YES' Then 'ACTIVE' Else 'INACTIVE'  end as product_status
	  ,	Case When LEN(ISNULL([CMK Product Description],'')) > 0 then [CMK Product Description]
	    	else Name END  AS product_title
		--	else Name END + ' {UPC: '+ COALESCE([UPC-A],[UPC-E],[EAN-13], [EAN-14]) +'}' AS product_title
	  ,M.TargetEntityID
	  , ltrim(rtrim([UPC-A])) +ISNULL('|' +NULLIF(LTRIM(RTRIM([UPC-E])), ''), '') +ISNULL('|' +NULLIF(LTRIM(RTRIM([EAN-13])), ''), '')+ISNULL('|' +NULLIF(LTRIM(RTRIM([EAN-14])), ''), '') as upc_scan_key
	  , [SyncStatusDDID],M.SourceEntityID
	  ,Case when  PostedToMovista  IS NULL  Then '0' else PostedToMovista end as PostedToMovista

	FROM 
	 dbo.MasterEntityMap (nolock) AS M 
	INNER JOIN [PRODUCTCATALOGDBSERVER].MDS2.[mdm].[viw_PC_Product] AS P (nolock) ON P.Code = M.SourceEntityID and M.EntityTypeDDID = 111
	WHERE 
	M.SyncStatusDDID = 101 or (M.SyncStatusDDID  = 102 and SyncAttempts  < 5  )
 
	 --101 and 102 are Ready to Sync and SyncFailed respectively

END
