# Модуль 2

Изначально хотела пройти этот модуль с минимальными знаниями SQL, которые успела нахватать не вполне последовательно, решая упражнения на https://sql-ex.ru/ (на момент ноября 2022 года знаний по SQL был ноль). Но, как ни странно, уткнувшись во что-то в установке DBeaver (причём, уже не знаю, что не взлетело, так как потом без проблем всё подключила), решила, что нужна хотя бы чуть более основательная база. 

Прошла 2 c небольшим модуля [курса по SQL](https://datalearn.ru/kurs-po-sql) тут же на Datalearn. Очень крутой курс, спасибо большое ребятам! Кстати, а чего его нет в списке дополнительных материалов для обучения в этом модуле? Я вот из телеграм чата про него прочитала (не обратила внимание на сайте). Дополировала [интерактивным тренажёром на Stepik](https://stepik.org/course/63054/), чуть лучше некоторые вещи уложились в голове. Планирую добить до конца оба курса, но пока решила разнообразить другими задачами. И ещё поняла, что надо почитать или пройти курс на английском, чтобы не плавать в терминологии на английском.

В процессе курса Анатолия немного потрогала pgAdmin, сейчас погоняла DBeaver. 

Для загрузки данных из БД Superstore использовала готовые sql файлы, хотя надо бы потом будет попробовать импорт средствами бобра хотя бы. 

В запросах комментарии на английском, потому как мало ли решу использовать для "портфолио". 

## SQL запросы на основе экселевского дашборда

### Считаем KPI в виде Year-over-year
Решила повторить то, что [делала в экселе в первом модуле](https://github.com/Bigdataworm/Datalearn/blob/main/DE-101/Module1/Readme.md).

C SQL получилось решить то, что не получалось красиво сделать в экселе (до некрасивого решения я так и не добралась)). В экселе я для подсчёта процента роста/уменьшения прибыли и других показателей использовала вычисляемое поле сводной таблицы, которое по неизвестным мне причинам знаменатель берёт не по модулю, таким образом расчёт получается в корне неправильным в том случае, если к примеру была отрицательная прибыль. В общем, с SQL это всё решается одним оператором.

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
Другие KPI (*Sales, Average discount*) считаются аналогично, просто заменяем названия столбцов и функцию агрегирования в основном селекте.

Для *Orders*, *Sales per customer* и *Sales per customer* пришлось отказаться от оконных функций, ибо там не работает оператор COUNT DISTINCT (ну или по крайней мере бобёр на меня ругнулся именно так). 


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
	