-- create schema
-- create and populate dimension tables (calendar, geography, shipping, customer, product, discount, order_status)
-- fix data quality problem (geography)
-- create and populate sales_fact table
-- match number of rows between staging and dw (business layer)



--creating dw schema and dimention tables

CREATE SCHEMA IF NOT EXISTS dw;

-- ************************************* CALENDAR

-- creating a table
DROP TABLE IF EXISTS dw.calendar_dim;
CREATE TABLE dw.calendar_dim
	(
 	 date_id  serial  NOT NULL,
 	 date 	  date 	  NOT NULL,
	 year     int  	  NOT NULL,
	 year_month varchar(20) NOT NULL,
	 quarter  int  	  NOT NULL,
	 month    int  	  NOT NULL,
	 week     int 	  NOT NULL,
	 week_day varchar(20) NOT NULL,
	 CONSTRAINT PK_calendar_dim PRIMARY KEY ( date_id )
	);

-- deleting rows
TRUNCATE TABLE dw.calendar_dim;

-- using a function 'generate_series' to populate calendar_dim
INSERT INTO dw.calendar_dim 
SELECT 
	to_char(date,'yyyymmdd')::int AS date_id, 
	date::date,
    date_part('isoyear', date) AS year,
    to_char(date, 'YYYY-MM') as order_year_month,
    date_part('quarter', date) AS quarter,
    date_part('month', date) AS month,
    date_part('week', date) AS week,
    date_part('dow', date) AS week_day
FROM 
	generate_series(date '2000-01-01',
                    date '2030-01-01',
                    interval '1 day')
    as t(date);

-- checking
SELECT 
	* 
FROM 
	dw.calendar_dim; 

-- ************************************** GEOGRAPHY

-- creating a table
DROP TABLE IF EXISTS dw.geography_dim;
CREATE TABLE dw.geography_dim
(
 geo_id       int GENERATED ALWAYS AS IDENTITY,
 country      varchar(30) NOT NULL,
 city         varchar(30) NOT NULL,
 "state"      varchar(25) NOT NULL,
 postal_code  varchar(10) NOT NULL, -- check that the source data has varchar format; in case of integer, leading zeros will be lost 
 region       varchar(20) NOT NULL,
 manager_name varchar(50) NOT NULL,
 CONSTRAINT PK_geography_dim PRIMARY KEY ( geo_id )
);

-- deleting rows
TRUNCATE TABLE dw.geography_dim;

-- inserting data from orders and people tables
INSERT INTO dw.geography_dim
	(country, city, state, postal_code, region, manager_name)
SELECT DISTINCT  
	o.country,
	o.city,
	o.state,
	o.postal_code,
	o.region,
	p.person
FROM
	stg.orders AS o
JOIN
	stg.people AS p
USING
	(region);

--data quality check
SELECT
	*
FROM 
	dw.geography_dim
WHERE 
	country IS NULL 
	OR 
	city IS NULL 
	OR 
	postal_code IS NULL;

-- City Burlington, Vermont postal code is missing. There are 5 zip codes for this area, we'll use the zip code for the most populated area.
UPDATE
	dw.geography_dim 
SET 
	postal_code = '05401'
WHERE 
	city = 'Burlington' 
	AND
	state = 'Vermont'
	AND
	postal_code IS NULL;	

--updating source data (otherwise, joins won't work as intended)
UPDATE
	stg.orders  
SET 
	postal_code = '05401'
WHERE 
	city = 'Burlington' 
	AND
	state = 'Vermont'
	AND
	postal_code IS NULL;	

-- checking
SELECT
	*
FROM 
	dw.geography_dim
ORDER BY 
	city;

-- ************************************** SHIPPING

-- creating a table
DROP TABLE IF EXISTS dw.shipping_dim;
CREATE TABLE dw.shipping_dim
(
 ship_id   int generated always as identity,
 ship_mode varchar(20) NOT NULL,
 CONSTRAINT PK_shipping_dim PRIMARY KEY ( ship_id )
);

-- deleting rows
TRUNCATE TABLE dw.shipping_dim;

-- inserting data from orders
INSERT INTO dw.shipping_dim
(ship_mode)
SELECT DISTINCT
	ship_mode
FROM
	stg.orders;

-- checking
SELECT
	*
FROM 
	dw.shipping_dim;

-- ************************************** CUSTOMER
-- creating a table
DROP TABLE IF EXISTS dw.customer_dim;
CREATE TABLE dw.customer_dim
(
 cust_id   	   int generated always as identity,
 customer_id   varchar(8) NOT NULL,
 customer_name varchar(50) NOT NULL,
 segment       varchar(30) NOT NULL,
 CONSTRAINT PK_customer_dim PRIMARY KEY ( cust_id )
);

-- deleting rows
TRUNCATE TABLE dw.customer_dim;

-- inserting data from orders
INSERT INTO dw.customer_dim	
	(customer_id, customer_name, segment)
SELECT DISTINCT
	customer_id,	
	customer_name,
	segment
FROM
	stg.orders;

-- checking
SELECT 	
	*,
	count(*) over ()
FROM 
	dw.customer_dim
order by
	cust_id;

-- ************************************** PRODUCT

-- creating a table
DROP TABLE IF EXISTS dw.product_dim;
CREATE TABLE dw.product_dim
(
 prod_id      int generated always as identity,
 product_id	  varchar(50)  NOT NULL,
 product_name varchar(130) NOT NULL,
 category     varchar(20)  NOT NULL,
 subcategory varchar(25)  NOT NULL,
 CONSTRAINT PK_product_dim PRIMARY KEY ( prod_id )
);

-- deleting rows
TRUNCATE TABLE dw.product_dim;

-- inserting data from orders
INSERT INTO dw.product_dim
(product_id, product_name, category, subcategory)
SELECT DISTINCT
	product_id,
	product_name,
	category,
	subcategory
FROM
	stg.orders;	

-- checking
SELECT 	
	*,
	count(*) over()
FROM 
	dw.product_dim
ORDER BY
	product_id;
	
-- ************************************** DISCOUNT

-- creating a table
DROP TABLE IF EXISTS dw.discount_dim;
CREATE TABLE dw.discount_dim
(
 discount_id     int generated always as identity,
 discount_percent numeric(9,4) NOT NULL,
 discount_descr  varchar(50),
 CONSTRAINT PK_discount_dim PRIMARY KEY ( discount_id )
);

-- deleting rows
TRUNCATE TABLE dw.discount_dim;

-- inserting data from orders
INSERT INTO dw.discount_dim
(discount_percent)
SELECT DISTINCT
	discount
FROM
	stg.orders;

-- checking
SELECT 	
	*,
	count(*) over()
FROM 
	dw.discount_dim;

-- ************************************** ORDER_STATUS

-- creating a table
DROP TABLE IF EXISTS dw.order_status_dim;
CREATE TABLE dw.order_status_dim
(
 status_id int GENERATED ALWAYS AS IDENTITY,
 returned  boolean NOT NULL,
 CONSTRAINT PK_order_status_dim PRIMARY KEY ( status_id )
);

-- deleting rows
TRUNCATE TABLE dw.order_status_dim;

-- generating data
INSERT INTO dw.order_status_dim
(returned)
VALUES (true),
	   (false);
	
-- checking
SELECT 	
	*
FROM 
	dw.order_status_dim;

-- ************************************** SALES_FACT

-- creating a table
DROP TABLE IF EXISTS dw.sales_fact;
CREATE TABLE dw.sales_fact
(
 row_id        serial NOT NULL,
 order_id      varchar(50) NOT NULL,
 order_date_id serial NOT NULL,
 ship_date_id  serial NOT NULL,
 sales_amount  numeric(9,4) NOT NULL,
 quantity      integer NOT NULL,
 profit        numeric(9,4) NOT NULL,
 status_id     int,
 ship_id       int NOT NULL,
 geo_id        int NOT NULL,
 prod_id       int,
 cust_id   	   int,
 discount_id   int,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( row_id )
);

-- deleting rows
TRUNCATE TABLE dw.sales_fact;

-- inserting data from orders, joining with dim tables
INSERT INTO dw.sales_fact
	(
	 row_id, 
	 order_id, 
	 order_date_id, 
	 ship_date_id, 
	 sales_amount, 
	 quantity, 
	 profit, 
	 status_id,
	 ship_id,
	 geo_id, 
	 prod_id, 
	 cust_id, 
	 discount_id
	 )
SELECT
	o.row_id,
	o.order_id,
	to_char(o.order_date, 'yyyymmdd')::int as order_date_id,
	to_char(o.ship_date, 'yyyymmdd')::int as ship_date_id,
	o.sales,
	o.quantity,
	o.profit,
	CASE WHEN r.returned = 'Yes' THEN 1 ELSE 2 END AS status_id,
	s.ship_id,
	g.geo_id,
	p.prod_id,
	c.cust_id,
	d.discount_id
FROM
	stg.orders AS o
LEFT JOIN
	(SELECT
		DISTINCT order_id,
		returned
	FROM
		stg.returns) AS r
ON o.order_id = r.order_id
JOIN 
	dw.shipping_dim AS s
ON
	o.ship_mode = s.ship_mode
JOIN 
	dw.geography_dim AS g 
ON 
	o.country = g.country
	AND
	o.city = g.city
	AND 
	o.state = g.state
	AND 
	o.postal_code = g.postal_code
JOIN 
	dw.product_dim AS p
ON
	o.product_id = p.product_id
	AND 
	o.product_name = p.product_name
	AND 
	o.category = p.category
	AND 
	o.subcategory = p.subcategory
JOIN 
	dw.customer_dim AS c
ON
	o.customer_id = c.customer_id
	AND 
	o.customer_name = c.customer_name
JOIN 
	dw.discount_dim AS d
ON 
	o.discount = d.discount_percent
;

-- checking
SELECT 
	count(*) OVER(), -- should be 9994 rows 
	*
FROM 
	dw.sales_fact