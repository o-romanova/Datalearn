/*Profit per month compared to the same month of the previous year (Year over year comparison)*/

SELECT
	date_trunc('month', order_date) AS order_month,
	ROUND(SUM(profit), 1) AS profit_by_month,
	ROUND(LAG(SUM(profit), 12) OVER w, 1) AS profit_prev_period,
	ROUND((SUM(profit)/LAG(SUM(profit), 12) OVER w - 1) * 100, 1) AS percent_difference
FROM
	orders o
GROUP BY
	order_month
WINDOW w AS (ORDER BY date_trunc('month', order_date))
ORDER BY 
	order_month;

--Yearly KPI change, change is shown in percent

SELECT
	date_trunc('year', order_date) as year,
	ROUND(SUM(profit), 1) AS profit,
	ROUND((SUM(profit) / LAG(SUM(profit)) OVER w - 1) * 100, 1) AS profit_change,
	ROUND(SUM(sales), 1) AS sales,
	ROUND((SUM(sales) / LAG (SUM(sales)) OVER w - 1) * 100, 1) AS sales_change,
	COUNT(distinct order_id) AS orders,
	ROUND((count(distinct order_id)::numeric / LAG(count(distinct order_id)::numeric) OVER w - 1) * 100, 1) AS orders_change,
	ROUND(SUM(profit)/SUM(sales) *100, 1) AS profit_margin,
	ROUND(((SUM(profit)/SUM(sales)) / LAG(SUM(profit)/SUM(sales)) OVER w - 1) * 100, 1) AS profit_margin_change
FROM
        public.orders
GROUP BY
    year
WINDOW w AS (ORDER BY date_trunc('year', order_date))
ORDER BY
    year;


/* Number of orders per month compared to the same month of the previous year (Year over year comparison) */

WITH order_count AS 
	(
    SELECT 
        date_trunc('month', order_date) AS order_month,
        COUNT(distinct order_id) AS orders_by_month,
        LAG(COUNT(distinct order_id), 12) OVER(ORDER BY date_trunc('month', order_date)) AS orders_prev_period
    FROM 
        orders
    GROUP BY
        date_trunc('month', order_date)
	)
SELECT
    order_month,
    orders_by_month,
    orders_prev_period,
    ROUND((orders_by_month - orders_prev_period) * 100.0 / orders_prev_period, 1) AS percent_difference
FROM
    order_count
ORDER BY 
    order_month;



/* Average discount per month compared to the same month of the previous year (Year over year comparison) */

SELECT
	date_trunc('month', order_date) AS order_month,
	ROUND(AVG(discount) * 100, 1) AS discount_by_month,
	ROUND(LAG(AVG(discount) *100, 12) OVER w, 1) AS discount_prev_period,
	ROUND((AVG(discount) / LAG(AVG(discount), 12) OVER w - 1) * 100, 1) AS percent_difference
FROM
	orders o
GROUP BY
	date_trunc('month', order_date)
WINDOW w AS (ORDER BY date_trunc('month', order_date))
ORDER BY 
	date_trunc('month', order_date);


/* Number of customers per month compared to the same month of the previous year (Year over year comparison) */

WITH customer_count AS 
	(
    SELECT 
        date_trunc('month', order_date) AS order_month,
        COUNT(distinct customer_id) AS customers_by_month,
        LAG(COUNT(distinct customer_id), 12) OVER(ORDER BY date_trunc('month', order_date)) AS customers_prev_period
    FROM 
        orders
    GROUP BY
        date_trunc('month', order_date)
	)
SELECT
    order_month,
    customers_by_month,
    customers_prev_period,
    ROUND((customers_by_month - customers_prev_period) * 100.0 / customers_prev_period, 1) AS percent_difference
FROM
    customer_count
ORDER BY 
    order_month;


/* Sales per customer per month compared to the same month of the previous year (Year over year comparison) */

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
	