/*========================= Advanced Data Analytics ================================= */

/*========================= 1. Changes over Time Analysis ===========================
analyze how measures are changing over the time,helps us to track trends and identify seasonality in your data */
-- usually we focus on fact table bcz we have measures and dates --
use DataWareHouse

select 
order_date,
sales_amount,
sum(sales_amount) over(order by order_date) as total_sales_amt,
avg(sales_amount) over(order by order_date) as avg_sales_per_day,
sum(quantity) over(order by order_date) as total_quantity,
avg(price) over(order by order_date) as total_price
from [dbo].[gold_fact_sales]
where order_date is not null  --- total sales by day wise details

-------------- Year Wise measures ----

select distinct
year(order_date)  as yearly,
sum(sales_amount) as tot_sal_amt,
sum(quantity)     as total_quantity,
avg(price)        as total_price,
count(distinct customer_key) as countofcustomer
from [dbo].[gold_fact_sales]
where order_date is not null  
group by year(order_date)
order by year(order_date) asc

select distinct
year(order_date) as yearly,
sum(sales_amount) over(partition by year(order_date) order by year(order_date) asc) as total_sales_amt
--sum(quantity) over(partition by year(order_date) order by year(order_date)) as total_quantity,
--avg(price) over(partition by year(order_date) order by year(order_date))  as total_price,
--count(customer_key) over(partition by year(order_date)) as countofcustomer --- in over clause cant use distinct
from [dbo].[gold_fact_sales]
where order_date is not null
order by year(order_date) asc--- total sales by year wise details
--------------- Month Wise ------------
select distinct
month(order_date)  as monthly,
sum(sales_amount) as tot_sal_amt,
sum(quantity)     as total_quantity,
avg(price)        as total_price,
count(distinct customer_key) as countofcustomer
from [dbo].[gold_fact_sales]
where order_date is not null  
group by month(order_date)
order by month(order_date) asc

select distinct
datetrunc(month,order_date) as Monthly,
sum(sales_amount) over(order by datetrunc(month,order_date)) as total_sales_amt,
sum(quantity) over(order by datetrunc(month,order_date)) as total_quantity,
avg(price) over(order by datetrunc(month,order_date)) as total_price
from [dbo].[gold_fact_sales]
where order_date is not null  --- total sales by monthly wise details
-------------- Year and Month Wise -------
select distinct
year(order_date) as yearly,
month(order_date)  as monthly,
sum(sales_amount) as tot_sal_amt,
sum(quantity)     as total_quantity,
avg(price)        as total_price,
count(distinct customer_key) as countofcustomer
from [dbo].[gold_fact_sales]
where order_date is not null  
group by year(order_date),month(order_date)
order by year(order_date),month(order_date) asc

-------------- 
/*========================= 2. Cumulative Analysis =========================== */
--- running total , moving avg 

--- day wise 
select order_Date,total_sales,
sum(total_sales) over(order by order_Date) as running_tot_Sales
from
(
select 
order_date,
sum(sales_amount) as total_sales
from [dbo].[gold_fact_sales]
where order_date is not null
group by order_date
) t

select  distinct order_date,
totsales
from
(
select 
order_date,
sum(sales_amount) over(order by order_Date) as totsales
from [dbo].[gold_fact_sales]
where order_date is not null) t
order by order_date asc

----- Month Wise running total ----

select Monthly,total_sales,
sum(total_sales) over(order by monthly) as running_tot_Sales
from
(
select 
datetrunc(month,order_date) as Monthly,
sum(sales_amount) as total_sales
from [dbo].[gold_fact_sales]
where order_date is not null
group by datetrunc(month,order_date)
--order by datetrunc(month,order_date)
) t --- month wise running total is taking place

----- year and monthly wise running total ----
select Monthly,total_sales,
sum(total_sales) over(partition by yearly order by monthly) as running_tot_Sales
from
(
select 
datetrunc(year,order_date) as yearly,
datetrunc(month,order_date) as Monthly,
sum(sales_amount) as total_sales
from [dbo].[gold_fact_sales]
where order_date is not null
group by datetrunc(year,order_date),datetrunc(month,order_date)
--order by datetrunc(year,order_date),datetrunc(month,order_date)
) t

--- yearly wise running total
select Yearly,total_sales,
sum(total_sales) over(order by yearly) as running_tot_Sales
from
(
select 
datetrunc(year,order_date) as yearly,
--datetrunc(month,order_date) as Monthly,
sum(sales_amount) as total_sales
from [dbo].[gold_fact_sales]
where order_date is not null
group by datetrunc(year,order_date)
--order by datetrunc(year,order_date)
) t

/*========================= 3. Performance Analysis =========================== */
-- comparing the current value to a target value. it helps measure success and compare performance --
--- current measures - target measures 

--- analyze the yearly performance of products by comparing their sales to both avg sales performance of product and previous year sales --
with cte_yearly_prod_sales as
(
select 
datetrunc(year,f.order_date) as yearly,
p.product_name as prodname,
sum(f.sales_amount) as current_sales
from      [dbo].[gold_fact_sales] f
left join [dbo].[gold_dim_product] p
on        f.product_key=p.product_key
where f.order_date is not null
group by datetrunc(year,f.order_date),p.product_name
--order by datetrunc(year,f.order_date),p.product_name
)
select
yearly,
prodname,
current_sales,
avg(current_sales) over(partition by prodname) as avg_sales,
current_sales - avg(current_sales) over(partition by prodname) as diff_avg,
Case when current_sales - avg(current_sales) over(partition by prodname) > 0 then 'Above Avg'
     when current_sales - avg(current_sales) over(partition by prodname) < 0 then 'Below Avg'
     else 'Avg'
End  avg_change,
--- YOY analysis 
lag(current_sales) over(partition by prodname order by yearly) as prev_year_sales,
current_sales - lag(current_sales) over(partition by prodname order by yearly) as diff_sales,
Case when current_sales - lag(current_sales) over(partition by prodname order by yearly) > 0 then 'Increase'
     when current_sales - lag(current_sales) over(partition by prodname order by yearly) < 0 then 'Decrease'
     else 'No Change'
End  yoy_change
from cte_yearly_prod_sales
order by prodname,yearly

use DataWareHouse


Print '======================= year wise data =================='
select 
	datetrunc(year,order_date) as yearlywise,
	sum(sales_amount) as totalsales,
	sum(quantity) as totalqty,
	avg(price) as avgprice,
	count(customer_key) as customercount
from  [gold_fact_sales]
where order_date is not null
Group by datetrunc(year,order_date)
order by datetrunc(year,order_date) asc 

Print '======================= cumulative year wise data =================='

select 
	yearlywise,
	totalsales,
	sum(totalsales) over(order by yearlywise) as cumulativesales,
	sum(totalsales) over() as allsales,
	Round((cast (totalsales as float) / sum(totalsales) over())  * 100, 2) as  yoy
from
(
		select 
			datetrunc(year,order_date) as yearlywise,
			sum(sales_amount) as totalsales
		/*	sum(quantity) as totalqty,
			avg(price) as avgprice,
			count(customer_key) as customercount */
		from  [gold_fact_sales]
		where order_date is not null
		Group by datetrunc(year,order_date)
		--order by datetrunc(year,order_date) asc 
) t 


Print '======================= segmentation measure by measure =================='
With cte_costsegment as
(
select 
	product_key,
	product_name,
	cost,
	case 
		when cost >=0 and cost<=1000 then 'Low'
		when cost >1000 and cost<=1500 then 'Medium'
		else 'High'
	end as costrange
from [dbo].[gold_dim_product]
) 
select 
costrange,
count(product_key) as prodcount
from cte_costsegment
group by costrange