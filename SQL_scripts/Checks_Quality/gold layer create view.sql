select cst_id, count(*) as cnt from
(
select 
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	ci.cst_marital_status as marital_status,
	case when ci.cst_gndr != 'N/A' then ci.cst_gndr
		 else coalesce(cu.gen,'N/A')
	end as gender,
	ci.cst_create_date as create_date,
	cu.bdate as birth_date,
	lo.cntry as country
from [dbo].[silver_crm_cust_info] as ci
left join [dbo].[silver_erp_cust_az12] as cu
on		  ci.cst_key=cu.cid
left join [dbo].[silver_erp_loc_a101] as lo
on        ci.cst_key=lo.cid
)t
group by cst_id
having count(*)>1  -- checks after joining if any null or duplicate are present


select distinct
	ci.cst_gndr,
		cu.gen,
	case when ci.cst_gndr != 'N/A' then ci.cst_gndr
		 else coalesce(cu.gen,'N/A')
	end as newgender
from [dbo].[silver_crm_cust_info] as ci
left join [dbo].[silver_erp_cust_az12] as cu
on		  ci.cst_key=cu.cid
left join [dbo].[silver_erp_loc_a101] as lo
on        ci.cst_key=lo.cid
order by ci.cst_gndr

-----
--drop view gold_dim_customer
CREATE VIEW gold_dim_customer AS
select 
	ROW_NUMBER() OVER(ORDER BY cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	lo.cntry as country,
	ci.cst_marital_status as marital_status,
	case when ci.cst_gndr != 'N/A' then ci.cst_gndr
		 else coalesce(cu.gen,'N/A')
	end as gender,
	cu.bdate as birth_date,	
	ci.cst_create_date as create_date	
from [dbo].[silver_crm_cust_info] as ci
left join [dbo].[silver_erp_cust_az12] as cu
on		  ci.cst_key=cu.cid
left join [dbo].[silver_erp_loc_a101] as lo
on        ci.cst_key=lo.cid

---====================================================
select count(*) from [dbo].[silver_crm_prd_info]  -- 397
select count(*) from [dbo].[silver_erp_px_cat_g1v2] -- 37

select prd_id , count(*) from (
select 
pr.prd_id,
pr.cat_id,
pr.prd_key,
pr.prd_nm,
pr.prd_cost,
pr.prd_line,
pr.prd_start_dt,
ca.cat,
ca.subcat,
ca.maintenance
from [dbo].[silver_crm_prd_info] as pr
left join [dbo].[silver_erp_px_cat_g1v2] as ca
on        pr.cat_id = ca.id
where     pr.prd_end_dt is null  -- 295 filtering out all historical data keeping only current data
)t 
group by prd_id
having count(*)>1  --- checking after joining master prd table to catgory table if anything duplicate rows are presnt or not

CREATE VIEW gold_dim_product AS
select 
ROW_NUMBER() OVER(ORDER BY prd_start_dt,prd_key) AS product_key,
pr.prd_id as product_id,
pr.prd_key as product_number,
pr.prd_nm as product_name,
pr.cat_id as category_id,
ca.cat as category,
ca.subcat as subcategory,
ca.maintenance,
pr.prd_cost as cost,
pr.prd_line as product_line,
pr.prd_start_dt as start_date
from [dbo].[silver_crm_prd_info] as pr
left join [dbo].[silver_erp_px_cat_g1v2] as ca
on        pr.cat_id = ca.id
where     pr.prd_end_dt is null

/*========================================================================================*/
DROP VIEW gold_fact_sales
CREATE VIEW gold_fact_sales AS
select 
sl.sls_ord_num as order_number,
pr.product_key,
cu.customer_key,
sl.sls_order_dt as order_date,
sl.sls_ship_dt as ship_date,
sl.sls_due_dt as due_date,
sl.sls_sales as sales_amount,
sl.sls_quantity as quantity,
sl.sls_price as price
from [dbo].[silver_crm_sales_details] as sl
left join  [dbo].[gold_dim_product] as pr
on         sl.sls_prd_key=pr.product_number
left join  [dbo].[gold_dim_customer] as cu
on         sl.sls_cust_id=cu.customer_id


/* ============ --- FOREIGN KEY INTEGRITY CHECK (DIMENSIONS)
--- check if all dimenison table can succesfully join to the fact table ========== */

select * from [dbo].[gold_fact_sales] as sl
left join     [dbo].[gold_dim_customer] as cu
on            sl.customer_key = cu.customer_key
where         cu.customer_key is null

select * from [dbo].[gold_fact_sales] as sl
left join     [dbo].[gold_dim_product] as pr
on            sl.product_key = pr.product_key
where         pr.product_key is null
