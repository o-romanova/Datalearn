-- query for importing data to Data visualization tools
SELECT
	sf.row_id,
	sf.order_id,
	to_date(order_date_id::text, 'YYYYMMDD')::date AS order_date,
	cd.year_month,
	to_date(ship_date_id::text, 'YYYYMMDD')::date AS shipping_date,
	sf.sales_amount,
	sf.quantity,
	sf.profit,
	osd.returned,
	sd.ship_mode,
	gd.country,
	gd.city,
	gd.state,
	gd.postal_code,
	gd.region,
	gd.manager_name,
	pd.product_id,
	pd.product_name,
	pd.category,
	pd.subcategory,
	c.customer_id,
	c.customer_name, 
	c.segment,
	dd.discount_percent
FROM
	dw.sales_fact AS sf
JOIN
	dw.calendar_dim cd 
ON
	order_date_id = cd.date_id
JOIN 
	dw.shipping_dim sd 
USING
	(ship_id)
JOIN
	dw.geography_dim gd 
USING
	(geo_id)
JOIN
	dw.product_dim pd 
USING
	(prod_id)
JOIN
	dw.customer_dim c
USING
	(cust_id)
JOIN
	dw.discount_dim dd 
USING
	(discount_id)
JOIN
	dw.order_status_dim osd 
USING
	(status_id);

-- checking data quality


SELECT 
	cd.year,
	ROUND(SUM(profit), 1) AS profit,
	ROUND(SUM(sales_amount), 1) AS sales
FROM
	dw.sales_fact AS sf 
JOIN
	dw.calendar_dim AS cd
ON
	order_date_id = cd.date_id
GROUP BY
	cd.year
ORDER BY 
	cd.year;
	

	
	