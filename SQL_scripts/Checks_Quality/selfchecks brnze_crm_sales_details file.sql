use datawarehouse


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

-- check unwanted space in string columns 
select sls_prd_key from [dbo].[bronze_crm_sales_details] where sls_prd_key != trim(sls_prd_key) 

-- checking sales can be join with dimension tables prod and cust info
select * from [dbo].[bronze_crm_sales_details]
where sls_prd_key in
(select prd_key from silver_crm_prd_info)

select * from [dbo].[bronze_crm_sales_details]
where sls_cust_id  in
(select cst_id from [dbo].[bronze_crm_cust_info])

-- check date column having values <= 0 or Null , check format make in correct 
select sls_order_dt from [dbo].[bronze_crm_sales_details]
where sls_order_dt is null or sls_order_dt <0

select sls_order_dt, nullif(sls_order_dt,0) from [dbo].[bronze_crm_sales_details]
where sls_order_dt = 0

select nullif(sls_order_dt,0) from [dbo].[bronze_crm_sales_details] where len(sls_order_dt) != 8 
or sls_order_dt > 20250101 or sls_order_dt < 19900101

select 
case 
	when len(sls_order_dt) !=8 or sls_order_dt =0 then null
	else cast(cast(sls_order_dt as varchar) as date)
end sls_order_dt
from 
[dbo].[bronze_crm_sales_details]
where sls_order_dt is null

select sls_order_dt ,sls_order_dt, sls_due_dt from [dbo].[bronze_crm_sales_details] 
where sls_order_dt > sls_order_dt or sls_order_dt > sls_due_dt  -- checking invalid order date

---- check measures column values like sales qty price not be < 0 or =0 or null
select sls_sales,sls_quantity,sls_price from [dbo].[bronze_crm_sales_details] where 
sls_sales is null or sls_quantity is null or sls_price is null or
sls_sales <= 0 or sls_quantity <=0 or sls_price <=0 or
sls_sales !=  sls_quantity * sls_price 
order by sls_sales,sls_quantity,sls_price

select 
sls_sales as oldsales,
sls_quantity as oldqty,
sls_price  as oldprice,
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
from [dbo].[bronze_crm_sales_details] where sls_sales is null or sls_sales<=0 
order by sls_sales
