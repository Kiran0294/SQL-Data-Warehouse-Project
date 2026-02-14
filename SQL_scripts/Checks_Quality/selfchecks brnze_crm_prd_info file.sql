/* -------------
(
select 
*,
ROW_NUMBER() over(partition by prd_id order by cst_create_date desc) as flg_value
from 
[dbo].[bronze_crm_prd_info]
where cst_id is not null
) t 
where flg_value =1

select 
count(*) as cnt_id,-- 3 null values
count(prd_key) as cnt_dup_id, -- duplicate expect null
count(distinct prd_key) as cnt_dist_id -- 6 duplicate values only not consider null
from 
[dbo].[bronze_crm_prd_info]

select 
prd_key,
count(*) as prdid
from 
[dbo].[bronze_crm_prd_info]
group by prd_key
having count(*) > 1 or prd_key is null

--select * from [dbo].[bronze_crm_prd_info] where prd_key = 'AC-HE-HL-U509'

select * from [dbo].[bronze_crm_prd_info] where prd_cost < 0 or prd_cost is null 
------------------ */

select
prd_id,
prd_key,
replace(SUBSTRING(trim(prd_key),1,5),'-','_') as cid,
SUBSTRING(trim(prd_key),7,len(trim(prd_key))) as prd_key_sales,
prd_nm,
prd_cost,
coalesce(prd_cost,'0') as newcost,
prd_line,
prd_start_dt,
prd_end_dt
from
[dbo].[bronze_crm_prd_info]


where replace(SUBSTRING(trim(prd_key),1,5),'-','_') not in
(select id from [dbo].[bronze_erp_px_cat_g1v2]) --- filter out unmatched data after applying trasnformation

/*
select top 5 * from [dbo].[bronze_erp_px_cat_g1v2]
select top 5 * from [dbo].[bronze_crm_sales_details] where sls_prd_key like 'HL%'

select top 5 * from [dbo].[bronze_crm_prd_info]
select top 5 * from [dbo].[bronze_erp_px_cat_g1v2]
select top 5 * from [dbo].[bronze_crm_sales_details]

select top 5 * from [dbo].[bronze_erp_cust_az12]
select top 5 * from [dbo].[bronze_erp_loc_a101]
select top 5 * from [dbo].[bronze_crm_cust_info]
*/

