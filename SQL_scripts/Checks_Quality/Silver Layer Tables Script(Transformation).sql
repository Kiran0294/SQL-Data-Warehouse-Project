/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
--use DataWareHouse
--select * from "silver_crm_cust_info"
CREATE OR ALTER PROCEDURE silver_load_silver AS 
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-- Loading silver.crm_cust_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
TRUNCATE TABLE dbo.silver_crm_cust_info
		PRINT '>> Inserting Data Into: silver.crm_cust_info';
insert into dbo.silver_crm_cust_info(
	dbo.cst_id,
	dbo.cst_key,
	dbo.cst_firstname,
	dbo.cst_lastname,
	dbo.cst_marital_status,
	dbo.cst_gndr, 
	dbo.cst_create_date )
select
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
case when upper(trim(cst_marital_status)) = 'S' then 'Single'
	 when upper(trim(cst_marital_status)) = 'M' then 'Married'
	 else 'N/A'
end  cst_marital_status,
case when upper(trim(cst_gndr)) = 'F' then 'Female'
	 when upper(trim(cst_gndr)) = 'M' then 'Male'
	 else 'N/A'
end cst_gndr,
cst_create_date
from
(
select *,
ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flag_last
from 
"bronze_crm_cust_info"
where cst_id is not null
) t 
where flag_last=1
 -- Select the most recent record per customer
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

/*=======================================================================================================*/
-- SELECT * FROM "silver_crm_prd_info"
-- Loading silver.crm_prd_info
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
TRUNCATE TABLE silver_crm_prd_info
		PRINT '>> Inserting Data Into: silver.crm_prd_info';
insert into silver_crm_prd_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
select 
prd_id,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
SUBSTRING(prd_key,7,len(prd_key)) as prd_key,
prd_nm,
coalesce(prd_cost,0) as prd_cost,
case when upper(trim(prd_line)) = 'M' then 'Mountain'
	 when upper(trim(prd_line)) = 'R' then 'Road'
	 when upper(trim(prd_line)) = 'S' then 'Other Sales'
	 when upper(trim(prd_line)) = 'T' then 'Touring'
	 else 'N/A'
end  prd_line,
cast(prd_start_dt as DATE) AS prd_start_dt,
CAST(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 AS DATE) as prd_end_dt
from
"bronze_crm_prd_info"
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
/*==============================================================================================*/
--- SELECT * FROM silver_crm_sales_details
        -- Loading crm_sales_details
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
TRUNCATE TABLE silver_crm_sales_details
		PRINT '>> Inserting Data Into: silver.crm_sales_details';
INSERT INTO silver_crm_sales_details(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)

select 
sls_ord_num,
sls_prd_key,
sls_cust_id,
case 
	when len(sls_order_dt) !=8 or sls_order_dt =0 then null
	else cast(cast(sls_order_dt as varchar) as date)
end sls_order_dt,
case 
	when len(sls_ship_dt) !=8 or sls_ship_dt =0 then null
	else cast(cast(sls_ship_dt as varchar) as date)
end sls_ship_dt,
case 
	when len(sls_due_dt) !=8 or sls_due_dt =0 then null
	else cast(cast(sls_due_dt as varchar) as date)
end sls_due_dt,
case 
	when sls_sales !=  abs(sls_quantity) * abs(sls_price) or sls_sales is null or sls_sales <=0 
			then  abs(sls_quantity) * abs(sls_price) 
	else sls_sales
end sls_sales,
sls_quantity,
case 
	when  sls_price is null or sls_price <=0 
			then abs(sls_sales)/abs(sls_quantity)
	else sls_price
end sls_price
from
[dbo].[bronze_crm_sales_details]
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

/*==================================================================================*/
-- SELECT * FROM [dbo].[silver_erp_cust_az12]
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12';
TRUNCATE TABLE [dbo].[silver_erp_cust_az12]
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
INSERT INTO [dbo].[silver_erp_cust_az12] (
cid,
bdate,
gen
)

SELECT 
case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
	 else cid
end cid,
case when bdate > GETDATE() then null
	 else bdate
end bdate,
case when upper(trim(gen)) in ('F','Female') then 'Female'
	 when upper(trim(gen)) in ('M','Male') then 'Male'
	 else 'N/A'
end as gen
FROM [dbo].[bronze_erp_cust_az12]
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

/*===========================================================*/
-- select * from [dbo].[silver_erp_loc_a101]
       -- Loading erp_loc_a101
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
truncate table [dbo].[silver_erp_loc_a101]
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
insert into [dbo].[silver_erp_loc_a101]
(
cid,
cntry
)
select 
REPLACE(cid,'-','') as cid,
case when trim(cntry) = 'DE' then 'Germany'
	 when trim(cntry) in ('US','USA') then 'United States'
	 when trim(cntry) = '' or cntry is null then 'N/A'
	 else cntry
end as cntry
from [dbo].[bronze_erp_loc_a101]
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
/*===========================================================*/
--select * from [dbo].[silver_erp_px_cat_g1v2]
		-- Loading erp_px_cat_g1v2
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
truncate table [dbo].[silver_erp_px_cat_g1v2]
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
insert into [dbo].[silver_erp_px_cat_g1v2]
(
id,
cat,
subcat,
maintenance
)
select * from [dbo].[bronze_erp_px_cat_g1v2]

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END 

EXEC silver_load_silver