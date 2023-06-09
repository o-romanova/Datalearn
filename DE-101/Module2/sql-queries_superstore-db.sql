/*Profit per month compared to the same month of the previous year (Year over year comparison)*/

-- calculating profit by month and extracting year and month from the order date for using  
-- in join clause in the main SELECT statement.

with current_year AS
	(select 
		date_part('year', order_date) as order_year,
		date_part('month', order_date) as order_month,
		to_char(order_date, 'YYYY-MM') as order_year_month,
		sum(profit) over(partition by to_char(order_date, 'YYYY-MM')) as current_profit
	from 
		public.orders)
		
select
	current_year.order_year_month,
	ROUND(current_year.current_profit, 2) as current_profit,
	ROUND(prev_year.prev_profit, 2) as prev_profit,
	ROUND((current_year.current_profit / prev_year.prev_profit - 1) * 100) as percent_diff
from
	current_year
-- join data from CTE with the same table (from subquery) but using year-1
left join
	(select
		date_part('year', order_date) as order_year,
		date_part('month', order_date) as order_month,
		to_char(order_date, 'YYYY-MM') as order_year_month,
		SUM(profit) over(partition by to_char(order_date, 'YYYY-MM')) as prev_profit	
	 from 
	 	public.orders) as prev_year
ON 
	prev_year.order_year = current_year.order_year - 1 
	and
	prev_year.order_month = current_year.order_month
group by 
	current_year.order_year_month,
	current_year.current_profit,
	prev_year.prev_profit
order by
	1,2;

--Yearly KPI change, change is shown in percent

SELECT
	year,
	ROUND(SUM(profit), 1) AS profit,
	ROUND((SUM(profit) / LAG(SUM(profit)) OVER w - 1) * 100, 1) AS profit_change,
	ROUND(SUM(sales), 1) AS sales,
	ROUND((SUM(sales) / LAG (SUM(sales)) OVER w - 1) * 100, 1) AS sales_change,
	COUNT(distinct order_id) AS orders,
	ROUND((count(distinct order_id)::numeric / LAG(count(distinct order_id)::numeric) OVER w - 1) * 100, 1) AS orders_change,
	ROUND(SUM(profit)/SUM(sales) *100, 1) AS profit_margin,
	ROUND(((SUM(profit)/SUM(sales)) / LAG(SUM(profit)/SUM(sales)) OVER w - 1) * 100, 1) AS profit_margin_change
FROM
    (
	SELECT
        date_part('year', order_date) AS year,
        profit,
        sales,
        order_id
    FROM
        public.orders
    ) subquery
GROUP BY
    year
WINDOW w AS (ORDER BY year)
ORDER BY
    year;


/* Number of orders per month compared to the same month of the previous year (Year over year comparison) */

--Two CTEs are identical, they count orders (by month) and extract year and month 
--from the order date to be used in the join clause.

with order_current AS
	(select 
			date_part('year', order_date) as order_year,
			date_part('month', order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			count(distinct order_id) as order_count
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month),
		
	order_prev as	
	(select 
			date_part('year', order_date) as order_year,
			date_part('month', order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			count(distinct order_id) as order_count
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month)

select
	order_current.order_year_month,
	order_current.order_count as current_month_orders,
	order_prev.order_count as previous_orders,
	ROUND((SUM(order_current.order_count) / SUM(order_prev.order_count) - 1) * 100, 1) as percent_diff
from
	order_current
-- join two tables on year and month but using year-1 
left join
	order_prev
on
	order_prev.order_year = order_current.order_year - 1 
	and
	order_prev.order_month = order_current.order_month
group by
	order_current.order_year_month,
	--order_prev.order_year_month,
	order_current.order_count,
	order_prev.order_count
order by 
	order_current.order_year_month;



/* Average discount per month compared to the same month of the previous year (Year over year comparison) */

-- CTE calculates average discount by month and extracts year and month from the order date 
-- for using in join clause in the main SELECT statement

with current_year AS
	(select 
		date_part('year', order_date) as order_year,
		date_part('month', order_date) as order_month,
		to_char(order_date, 'YYYY-MM') as order_year_month,
		avg(discount) over(partition by to_char(order_date, 'YYYY-MM')) as current_discount
	from 
		public.orders)

select
	current_year.order_year_month,
	ROUND(current_year.current_discount * 100, 1) AS current_year_discount,
	ROUND(prev_year.prev_discount * 100, 1) as previous_year_discount,
	ROUND((current_year.current_discount / prev_year.prev_discount -1) * 100, 1) as percent_diff
from
	current_year
-- join with the same table (from subquery) but using year-1 
left join
	(select
		date_part('year', order_date) as order_year,
		date_part('month', order_date) as order_month,
		to_char(order_date, 'YYYY-MM') as order_year_month,
		avg(discount) over(partition by to_char(order_date, 'YYYY-MM')) as prev_discount	
	 from 
	 	public.orders) as prev_year
ON 
	prev_year.order_year = current_year.order_year - 1 
	and
	prev_year.order_month = current_year.order_month
group by 
	current_year.order_year_month,
	current_year.current_discount,
	prev_year.prev_discount
order by
	1;


/* Number of customers per month compared to the same month of the previous year (Year over year comparison) */

-- Two CTEs are identical, they count customers (by month) and extract year and month from the order date to be used in the join clause

with order_current AS
	(select 
			date_part('year', order_date) as order_year,
			date_part('month', order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			count (distinct customer_id) as customer_count
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month),
	order_prev as	
	(select 
			date_part('year', order_date) as order_year,
			date_part('month', order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			count(distinct customer_id) as customer_count
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month)
select
	order_current.order_year_month,
	order_current.customer_count AS customer_count,
	SUM(order_prev.customer_count) as prev_customer_count,
	ROUND((SUM(order_current.customer_count) / SUM(order_prev.customer_count) - 1) * 100, 1) AS percent_diff
from
	order_current
-- join two CTEs on year and month but using year-1 
left join
	order_prev
on
	order_prev.order_year = order_current.order_year - 1 
	and
	order_prev.order_month = order_current.order_month
group by
	order_current.order_year_month,
	order_current.customer_count,
	order_prev.customer_count
order by 
	order_current.order_year_month;



/* Sales per customer per month compared to the same month of the previous year (Year over year comparison) */

--Two CTEs are identical, they sum sales per customer (by month) and extract year and month from the order date to be used in the join clause

with order_current AS
	(select 
			date_part('year', order_date) as order_year,
			date_part('month', order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			sum(sales)/count(distinct customer_id) as sales_customer
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month),
	
	order_prev as	
	(select 
			date_part('year', order_date) as order_year,
			date_part('month', order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			sum(sales)/count(distinct customer_id) as sales_customer
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month)

select
	order_current.order_year_month,
	ROUND(order_current.sales_customer, 1) as sales_per_customer,
	ROUND(order_prev.sales_customer, 1) as prev_sales_per_customer,
	ROUND((order_current.sales_customer / order_prev.sales_customer -1) * 100, 1) as percent_diff
from
	order_current
-- join two CTEs on year and month but using year-1 
left join
	order_prev
on
	order_prev.order_year = order_current.order_year - 1 
	and
	order_prev.order_month = order_current.order_month
order by 
	order_current.order_year_month;



/* Lost profit. Returned orders by state */

select
	state,
	SUM(sales) as returned_sales_sum,
	COUNT(returned) as returned_order_count
from
	public.orders as o
join
	(select
		distinct order_id,
		returned
	from
		public."returns") as r
on o.order_id = r.order_id
group by
	state,
	r.returned
order by
	returned_sales_sum desc;

	
/* Profit dynamics */
select
	date_part('year', order_date) as order_year,
	--to_char(order_date, 'YYYY-MM') as order_year_month,
	ROUND(sum(profit), 2) as profit_sum
from 
	public.orders
group by 
	order_year	
	--order_year_month
order by
	order_year;	


/* Sales and profit by product category and subcategory */
select
	to_char(order_date, 'YYYY-MM') as order_year_month,	
	category,
	subcategory,
	ROUND(SUM(sales), 2) as sales_sum,
	ROUND(SUM(profit), 2) as profit_sum
from 
	public.orders
group by
	category,
	subcategory,
	order_year_month
having 
	to_char(order_date, 'YYYY-MM') = '2019-03'
order by
profit_sum DESC,	
category;


/* Top 10 product by profit */
select
	product_name,
	ROUND(SUM(profit), 2) as profit_sum
from
	public.orders
group by
	product_name,
	orders.order_date
--filter by year if necessary
having 
	date_part('year', order_date) = '2018'
order by
	SUM(profit) desc
limit 
	10;	

/* Region managers by profit */
select 
	person,
	SUM(profit) as profit_manager
from
	public.people
join
	public.orders
using
	(region)
group by
	person
order by
	SUM(profit) DESC;
	