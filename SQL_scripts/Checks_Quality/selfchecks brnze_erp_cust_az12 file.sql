SELECT * FROM [dbo].[bronze_erp_cust_az12]

SELECT cid FROM [dbo].[bronze_erp_cust_az12] where cid is null
SELECT COUNT(*) FROM [dbo].[bronze_erp_cust_az12]
SELECT COUNT(cid) FROM [dbo].[bronze_erp_cust_az12] 

SELECT cid FROM [dbo].[bronze_erp_cust_az12] WHERE cid != TRIM(cid)

SELECT * FROM [dbo].[bronze_erp_cust_az12] WHERE cid in 
( SELECT cst_key FROM [dbo].[bronze_crm_cust_info]) -- 7441

SELECT * FROM [dbo].[bronze_erp_cust_az12] WHERE cid not in 
( SELECT cst_key FROM [dbo].[bronze_crm_cust_info]) -- 11042

select bdate from [dbo].[bronze_erp_cust_az12] where bdate is null or 
bdate < '1924-01-01' or bdate > GETDATE() -- identify outof range date

select distinct gen ,
case when upper(trim(gen)) in ('F','Female') then 'Female'
	 when upper(trim(gen)) in ('M','Male') then 'Male'
	 else 'N/A'
end as gender
from [dbo].[bronze_erp_cust_az12] -- check string null and give proper abbreviation

TRUNCATE TABLE [dbo].[silver_erp_cust_az12]
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