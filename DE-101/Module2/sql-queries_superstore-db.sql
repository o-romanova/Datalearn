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

WITH sales_customer AS 
	(
    SELECT 
        date_trunc('month', order_date) AS order_month,
        COUNT(distinct customer_id) AS customer_count,
        SUM(sales) AS sales,
        SUM(sales) / COUNT(distinct customer_id) AS customer_sales_by_month,
        LAG(SUM(sales), 12) OVER w AS sales_prev,
        LAG(COUNT(distinct customer_id), 12) OVER w AS customers_prev_period
    FROM 
        orders
    GROUP BY
        date_trunc('month', order_date)
    WINDOW w AS (ORDER BY date_trunc('month', order_date))
	)
SELECT
    order_month,
    ROUND(customer_sales_by_month, 1),
    ROUND(sales_prev / customers_prev_period, 1) AS customer_sales_prev,
    ROUND((customer_sales_by_month - sales_prev/customers_prev_period) / (sales_prev / customers_prev_period) * 100, 1) AS percent_difference
FROM
    sales_customer
ORDER BY 
    order_month;


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
	--date_trunc('year', order_date) as order_year,
	date_trunc('month', order_date) as order_year_month,
	ROUND(sum(profit), 2) as profit_sum
from 
	public.orders
group by 
	order_year	
	--order_year_month
order by
	order_year_month
	--order_year_month;	


/* Sales and profit by product category and subcategory */
select
	date_trunc('month', order_date) as order_year_month,	
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
	date_trunc('month', order_date) = '2019-03-01'
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
	date_trunc('year', order_date) = '2018-01-01'
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
	