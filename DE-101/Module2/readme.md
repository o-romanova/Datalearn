# Модуль 2

Изначально хотела пройти этот модуль с минимальными знаниями SQL, которые успела нахватать не вполне последовательно, решая упражнения на https://sql-ex.ru/ (на момент ноября 2022 года знаний по SQL был ноль). Но, как ни странно, уткнувшись во что-то в установке DBeaver (причём, уже не знаю, что не взлетело, так как потом без проблем всё подключила), решила, что нужна хотя бы чуть более основательная база. 

Прошла 2 c небольшим модуля [курса по SQL](https://datalearn.ru/kurs-po-sql) тут же на Datalearn. Очень крутой курс, спасибо большое ребятам! Кстати, а чего его нет в списке дополнительных материалов для обучения в этом модуле? Я вот из телеграм чата про него прочитала (не обратила внимание на сайте). Дополировала [интерактивным тренажёром на Stepik](https://stepik.org/course/63054/), чуть лучше некоторые вещи уложились в голове. Планирую добить до конца оба курса, но пока решила разнообразить другими задачами. И ещё поняла, что надо почитать или пройти курс на английском, чтобы не плавать в терминологии на английском.

В процессе курса Анатолия немного потрогала pgAdmin, сейчас погоняла DBeaver. 

Для загрузки данных из БД Superstore использовала готовые sql файлы, хотя надо бы потом будет попробовать импорт средствами бобра например. Сразу же изменила тип данных в postal_code на varchar, иначе потом криво добавляется недостающий индекс (исчезает первый ноль). 

В запросах комментарии на английском, потому как мало ли решу использовать для "портфолио". 

## SQL запросы на основе экселевского дашборда

### Считаем KPI в виде Year-over-year
Решила повторить то, что [делала в экселе в первом модуле](https://github.com/Bigdataworm/Datalearn/blob/main/DE-101/Module1/Readme.md).

C SQL получилось решить то, что не получалось красиво сделать в экселе (до некрасивого решения я так и не добралась)). В экселе я для подсчёта процента роста/уменьшения прибыли и других показателей использовала вычисляемое поле сводной таблицы, которое по неизвестным мне причинам знаменатель берёт не по модулю, таким образом расчёт получается в корне неправильным в том случае, если к примеру была отрицательная прибыль. В общем, с SQL это всё решается одной функцией.

Решила использовать оконные функции и CTE, пока не разобралась, что лучше: две CTE или CTE и подзапрос, как у меня получилось (случайно, но потом уже не стала переделывать, хотя с двумя CTE по-моему как минимум читается проще). 

#### Прибыль по месяцам в сравнении с аналогичным месяцем предыдущего года (Year-over-year) 

```sql
/*Profit per month compared to the same month of the previous year (Year over year comparison). 
 * Shows change in dollars and in percent.*/

/*CTE calculates profit by month and extracts year and month from the order date for using in window function 
 * and join clause in the main SELECT statement. 
 * I decided to use window functions in order to avoid the GROUP BY clause in the CTE */

with current_year AS
	(select 
		extract(year from order_date) as order_year,
		extract(month from order_date) as order_month,
		to_char(order_date, 'YYYY-MM') as order_year_month,
		sum(profit) over(partition by to_char(order_date, 'YYYY-MM')) as current_profit
	from 
		public.orders)
		
/* select the current year data from CTE and join it with basically the same table (from subquery) but using year-1
 * (thus, same month, but previous year), then do the calculations*/
select
	current_year.order_year_month,
	ROUND(current_year.current_profit, 2) as profit,
	ROUND(current_year.current_profit - prev_year.prev_profit, 2) as profit_YoY,
	ROUND((current_year.current_profit - prev_year.prev_profit) / ABS(prev_year.prev_profit) * 100) as percent_diff
from
	current_year
left join
	(select
		extract(year from order_date) as order_year,
		extract(month from order_date) as order_month,
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
```

Другие KPI (`Sales`, `Average discount`) считаются аналогично, просто заменяем названия столбцов и функцию агрегирования в основном селекте.

Для `Orders`, `Customers` и `Sales per customer` пришлось отказаться от оконных функций, ибо там не работает оператор `COUNT DISTINCT` (ну или по крайней мере бобёр на меня ругнулся именно так). 


#### Количество заказов по месяцам в сравнении с аналогичным месяцем предыдущего года (Year-over-year) 

```sql
/* Number of orders per month compared to the same month of the previous year (Year over year comparison). 
 * Shows change in order number and in percent.*/

/* Two CTEs are identical, they count orders (by month) and extract year and month from the order date to be used in the join clause. 
 * I had to use group by clause instead of window functions as COUNT DISTINCT function is not implemented in window functions */

with order_current AS
	(select 
			extract(year from order_date) as order_year,
			extract(month from order_date) as order_month,
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
			extract(year from order_date) as order_year,
			extract(month from order_date) as order_month,
			to_char(order_date, 'YYYY-MM') as order_year_month,
			count(distinct order_id) as order_count
		from 
			public.orders
	group by 
		order_year,
		order_month,
		order_year_month)
		
/* here, we select the columns from CTEs above and join two tables on year and month but using year-1 
 * (thus, same month, but previous year), then do the calculations*/
select
	order_current.order_year_month,
	order_current.order_count,
	SUM(order_current.order_count) - SUM(order_prev.order_count) as order_yoy,
	ROUND((SUM(order_current.order_count) - SUM(order_prev.order_count))/order_prev.order_count*100, 2) as percent_diff
from
	order_current
left join
	order_prev
on
	order_prev.order_year = order_current.order_year - 1 
	and
	order_prev.order_month = order_current.order_month
group by
	order_current.order_year_month,
	order_prev.order_year_month,
	order_current.order_count,
	order_prev.order_count
order by 
	order_current.order_year_month;
```

### Смотрим остальные показатели 
В разных запросах показала разные фильтры/группировки, так надо от конкретной задачи отталкиваться, конечно.

#### Упущенная прибыль по штатам (смотрим продажи, где заказ был отменён, плюс фильтр по году)
```sql
--Lost profit
--Returned orders by state and filtered by year
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
	order_date,
	r.returned
--filter by year-month and if the order was returned
	having 
		extract(year from order_date) = '2017'
order by
	sales_sum_state desc;
```

#### Динамика прибыли
```sql
--Profit dynamics	
select
	extract(year from order_date) as order_year,
	to_char(order_date, 'YYYY-MM') as order_year_month,
	ROUND(sum(profit), 2) as profit_sum
from 
	public.orders
group by 
	order_year,	
	order_year_month
--filter by year-month
having extract(year from order_date) = 2019
order by
	order_year_month;	
```

#### Продажи и прибыль по категориям и подкатегориям
```sql
--Sales and profit by product category and subcategory
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
--filter by year-month
having 
	to_char(order_date, 'YYYY-MM') = '2019-03'
order by
	category,
	profit_sum;
```

####  Топ-10 продуктов по прибыли
```sql
--Top 10 product by profit
select
	product_name,
	ROUND(SUM(profit), 2) as profit_sum
from
	public.orders
group by
	product_name,
	orders.order_date
--filter by year
having 
	extract(year from order_date) = '2018'
order by
	SUM(profit) desc
limit 
	10;	
```
#### Рейтинг менеджеров по прибыли
```sql
--Region managers by profit
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
```
Ну и так далее. Остальное, что я реализовала в экселе, делается аналогично. 

## Модель данных
Для построения модели данных использовала [SqlDBM](https://sqldbm.com) и функцию forward engineering для создания таблиц.

![Физическая модель данных](data_model_superstoredb.png)

Немного изменила структуру данных - добавила таблицы-`dimensions`: 
- `calendar` использует генерируемые даты в заданном интервале;
- `geography` содержит всякие пространственные данные;
- отдельно вынесла `discount` для упрощения ввода скидочных программ и пр;
- возвраты тоже вынесены отдельно в `order_status`, теоретически могут добавляться другие характеристики заказа. 


Скрипт можно посмотреть тут. Может быть незначительное расхождение со схемой, я редактировала скрипт уже по ходу.

[Обратно в начало репозитория :leftwards_arrow_with_hook:](https://github.com/Bigdataworm/Datalearn)