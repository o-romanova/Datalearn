# Модуль 2

Изначально хотела пройти этот модуль с минимальными знаниями SQL, которые успела нахватать не вполне последовательно, решая упражнения на https://sql-ex.ru/ (на момент ноября 2022 года знаний по SQL был ноль). Но, как ни странно, уткнувшись во что-то в установке DBeaver (причём, уже не знаю, что не взлетело, так как потом без проблем всё подключила), решила, что нужна хотя бы чуть более основательная база. 

Прошла 2 c небольшим модуля [курса по SQL](https://datalearn.ru/kurs-po-sql) тут же на Datalearn. Очень крутой курс, спасибо большое ребятам! Кстати, а чего его нет в списке дополнительных материалов для обучения в этом модуле? Я вот из телеграм чата про него прочитала (не обратила внимание на сайте). Дополировала [интерактивным тренажёром на Stepik](https://stepik.org/course/63054/), чуть лучше некоторые вещи уложились в голове. Планирую добить до конца оба курса, но пока решила разнообразить другими задачами. 

В процессе курса Анатолия немного потрогала pgAdmin, сейчас погоняла DBeaver. 

Для загрузки данных из БД Superstore использовала готовые sql файлы, хотя надо бы потом будет попробовать импорт средствами бобра хотя бы. 

В запросах комментарии на английском, потому как мало ли решу использовать для "портфолио". 

## SQL запросы на основе экселевского дашборда

### Считаем KPI в виде Year-over-year
Решила повторить то, что [делала в экселе в первом модуле](https://github.com/Bigdataworm/Datalearn/blob/main/DE-101/Module1/Readme.md).

C SQL получилось решить то, что не получалось красиво сделать в экселе (до некрасивого решения я так и не добралась)). В экселе я для подсчёта процента роста/уменьшения прибыли и других показателей использовала вычисляемое поле сводной таблицы, которое по неизвестным мне причинам знаменатель берёт не по модулю, таким образом расчёт получается в корне неправильным в том случае, если к примеру была отрицательная прибыль. В общем, с SQL это всё решается одним оператором.

#### Прибыль по месяцам в сравнении с аналогичным месяцем предыдущего года (Year-over-year) 

```sql
-- profit per month compared to the same month of the previous year (Year over year comparison)

	-- CTE calculates profit for the current year (by month) and extracts year and month from the order date

with current_year AS
	(select 
		extract(year from order_date) as order_year,
		extract(month from order_date) as order_month,
		to_char(order_date, 'YYYY-MM') as order_year_month,
		sum(profit) over(partition by to_char(order_date, 'YYYY-MM')) as current_profit
	from 
		public.orders)
	-- select the current year data and join it with basically the same table but using year-1 (thus, same month, but previous year), do the calculations
select
	current_year.order_year,
	current_year.order_month,
	current_year.current_profit,
	prev_year.prev_profit,
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
	current_year.order_year,
	current_year.order_month,
	current_year.current_profit,
	prev_year.prev_profit
order by
	1,2;
```
**Остальные KPI (*Sales, Orders, Average discount, Customers, Sales per customer*) считаются аналогично, просто заменяем названия столбцов в основном селекте**

Ну вот только для *Orders* и *Sales per customer* будет немного другое вычисление. 