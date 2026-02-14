SELECT TOP (1000) [cst_id]
      ,[cst_key]
      ,[cst_firstname]
      ,[cst_lastname]
      ,[cst_marital_status]
      ,[cst_gndr]
      ,[cst_create_date]
  FROM [DataWareHouse].[dbo].[bronze_crm_cust_info]

/* checking null/ duplicate in primary on table [dbo].[bronze_crm_cust_info] 
select 
count(*) as cnt_id,-- 3 null values
count(cst_id) as cnt_dup_id, -- duplicate expect null
count(distinct cst_id) as cnt_dist_id -- 6 duplicate values only not consider null
from 
[dbo].[bronze_crm_cust_info]

select 
cst_id,
count(*) as cnt_id
from 
[dbo].[bronze_crm_cust_info]
group by cst_id
having count(*) > 1 or cst_id is null

select 
*
from 
[dbo].[bronze_crm_cust_info]
where cst_id in ( 29449,
29473,
29433,
NULL,
29483,
29466) order by cst_id  -------------- */


select *
from 
(
select 
*,
ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flg_value
from 
[dbo].[bronze_crm_cust_info]
where cst_id is not null
) t 
where flg_value =1

/* checking for unwanted space in string columnc/values or null 

select cst_key from [dbo].[bronze_crm_cust_info] where  cst_key !=  trim(cst_key)

select cst_firstname, len(cst_firstname) as cst_firstname_len,
trim(cst_firstname) as trim_firstname, len(trim(cst_firstname)) as trim_firstname_len from [dbo].[bronze_crm_cust_info] 
where  cst_firstname !=  trim(cst_firstname)
------------------ */

/* check the consistency of values in low cardinality columns ex: gender or marital_status 
   check date column is not null, correct format 
*/

select * from [dbo].[bronze_crm_cust_info]

select distinct cst_gndr from [dbo].[bronze_crm_cust_info]
select distinct cst_create_date,  cst_id from [dbo].[bronze_crm_cust_info] where cst_create_date is null


select 
cst_id,
cst_key,
upper(trim(cst_firstname)) as cst_firstname,
upper(trim(cst_lastname)) as cst_lastname,
cst_marital_status,
case upper(trim(cst_marital_status))
     when 'S' then 'Single'
     when 'M' then 'Married'
     else 'N/A'
end cst_marital_status,
cst_gndr,
case upper(trim(cst_gndr))
     when 'F' then 'Female'
     when 'M' then 'Male'
     else 'N/A'
end cst_gndr,
cst_create_date
from 
(
select 
*,
ROW_NUMBER() over(partition by cst_id order by cst_create_date desc) as flg_value
from 
[dbo].[bronze_crm_cust_info]
where cst_id is not null
) t 
where flg_value =1