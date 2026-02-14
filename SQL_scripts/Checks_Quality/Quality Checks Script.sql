-- Check Null and Duplicates values present in Primary Key 
-- Expectation = No Results
select * from "bronze_crm_cust_info" where cst_id is null;

select count(distinct(cst_id))  as dist_cnt_id from "bronze_crm_cust_info"

select count(cst_id) as dup_cnt_id from "bronze_crm_cust_info"

select count(*) as cnt_id from "bronze_crm_cust_info"

select *,
flag_last
from
(
select *,
ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flag_last
from 
"bronze_crm_cust_info"
) t 
where flag_last>1

--- Check Column which are string and remove unwanted spaces 
select * from "bronze_crm_cust_info"

SELECT cst_firstname 
FROM "bronze_crm_cust_info"
where cst_firstname != trim(cst_firstname)

SELECT cst_lastname 
FROM "bronze_crm_cust_info"
where cst_lastname != trim(cst_lastname)

/*SELECT cst_gndr 
FROM "bronze_crm_cust_info"
where cst_gndr != trim(cst_gndr)

SELECT cst_marital_status 
FROM "bronze_crm_cust_info"
where cst_marital_status != trim(cst_marital_status)
*/

-- Data Standardization and Consistency
select distinct cst_marital_status
from "bronze_crm_cust_info"

select distinct cst_gndr
from "bronze_crm_cust_info"

--- 
select * from "bronze_crm_prd_info"

select 
prd_key,
count(*)
from 
"bronze_crm_prd_info"
group by prd_key
having count(*)>1 and prd_key is null

SELECT prd_key 
FROM "bronze_crm_prd_info"
where prd_key != trim(prd_key)

SELECT prd_nm 
FROM "bronze_crm_prd_info"
where prd_nm != trim(prd_nm)

SELECT prd_line 
FROM "bronze_crm_prd_info"
where prd_line != trim(prd_line)

select *,
flag_last
from
(
select *,
ROW_NUMBER() over(partition by prd_id order by prd_id) as flag_last
from 
"bronze_crm_prd_info"
) t 
where flag_last>1

-- check for nulls or negative numbers
-- expectation = no results
select * from "bronze_crm_prd_info" where prd_cost is null or prd_cost<0

-- checks for invalid date orders
select * from "bronze_crm_prd_info" 
where prd_end_dt < prd_start_dt

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