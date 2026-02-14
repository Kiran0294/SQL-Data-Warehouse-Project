select 
cid
from [dbo].[bronze_erp_loc_a101] 
where cid is null or cid != trim(cid) -- check null or empty space

select 
cid,
REPLACE(cid,'-','') as cidnew,
cntry
from [dbo].[bronze_erp_loc_a101] where REPLACE(cid,'-','') not in 
( select distinct cst_key from [dbo].[silver_crm_cust_info]) -- checking joining is happening or not

select distinct cntry,
case when trim(cntry) = 'DE' then 'Germany'
	 when trim(cntry) in ('US','USA') then 'United States'
	 when trim(cntry) = '' or cntry is null then 'N/A'
	 else cntry
end as cntrynew
from [dbo].[bronze_erp_loc_a101] order by cntry  -- checking null in country and give proper abbreviation

truncate table [dbo].[silver_erp_loc_a101]
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