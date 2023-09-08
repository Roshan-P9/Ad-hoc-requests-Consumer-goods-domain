
-- 1.  Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.



select distinct market from dim_customer
where region = 'APAC' and customer ='Atliq Exclusive';

-- 2. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.


with ct as(
select 
(case when fiscal_year = 2020 then product_code end ) as a,
(case when fiscal_year = 2021 then product_code end ) as b
from fact_sales_monthly),
cte2 as (
select count(distinct a) as unique_products_2020,
count(distinct b) as unique_products_2021
from ct )
select * ,
round(100 *  (unique_products_2021-unique_products_2020)/unique_products_2020,2) as percentage_chg
 from cte2;
 
--  3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

 
 select segment , count(distinct product_code) as product_count
 from dim_product
 group 	by segment
 order by product_count desc;

-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

with ct as(
select segment,
(case when fiscal_year = 2020 then s.product_code end ) as a,
(case when fiscal_year = 2021 then s.product_code end ) as b
from fact_sales_monthly as s
right join dim_product as p
on p.product_code=s.product_code)
select segment, count(distinct a) as product_count_2020,
count(distinct b) as unique_products_2021,
count(distinct b) - count(distinct a) as difference
 from ct 
 group by segment
 order by difference desc;
 
--  5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

 
 with ct as(
 select m.product_code, p.product, manufacturing_cost
 from fact_manufacturing_cost as m
 left join dim_product as p
 on p.product_code=m.product_code
order by manufacturing_cost desc
limit 1),
 ct2 as(
 select m.product_code, p.product, manufacturing_cost
 from fact_manufacturing_cost as m
 left join dim_product as p
 on p.product_code=m.product_code
order by manufacturing_cost asc
limit 1)
select*from ct
union 
select * from ct2;

-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage


select c.customer_code, c.customer,
avg(pre_invoice_discount_pct) as average_discount_percentage
from fact_sales_monthly as s
join dim_customer c
 on c.customer_code=s.customer_code
 join fact_pre_invoice_deductions as pi
 on pi.customer_code=c.customer_code
 and s.fiscal_year=pi.fiscal_year
 where s.fiscal_year=2021 and c.market='India'
 group by c.customer_code, c.customer
 order by average_discount_percentage desc
 limit 5;
 
-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select MONTHNAME(s.date) as month, s.fiscal_year as year,
sum( gp.gross_price*s.sold_quantity ) as gross_sales_amount
from fact_sales_monthly as s
join dim_product as p
on p.product_code=s.product_code
join fact_gross_price as gp
on p.product_code=gp.product_code
join dim_customer as c
on c.customer_code=s.customer_code
where c.customer='Atliq Exclusive'
group by month,year
order by year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity


select 
CASE
        WHEN MONTH(date) >= 9 THEN CEILING((MONTH(date) - 8) / 3)
        ELSE CEILING((12 - (9 - MONTH(date) - 1)) / 3)
    END AS Quarter,
    sum(sold_quantity) as total_sold_quantity
FROM
 fact_sales_monthly
 where fiscal_year = 2020
 group by quarter
 order by total_sold_quantity desc;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage


with cte as(
select c.channel, 
round((sum(s.sold_quantity * g.gross_price))/1000000 ,2) as gross_sales_mln
from fact_sales_monthly as s
join dim_customer as c
on c.customer_code=s.customer_code
join dim_product as p
on p.product_code=s.product_code
join fact_gross_price as g
on g.product_code=p.product_code
where s.fiscal_year=2021
group by c.channel)
select channel, concat(gross_sales_mln,' M') as gross_sales_mln ,
 concat(round(100 * gross_sales_mln/(select sum(gross_sales_mln) from cte),2),' %') as percentage
from cte;
	
-- 10. Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code


with cte_product as(
select division,p.product_code,concat(product,' [', variant,']') as product
from dim_product as p),
cte_sales as(
select division,p.product_code, product,
sum( sold_quantity) as total_sold_quantity
from fact_sales_monthly as s
left join cte_product as p
on p.product_code=s.product_code
where s.fiscal_year=2021
group by division,p.product_code,product),
rnk as(
select *, 
dense_rank() over (partition by division order by total_sold_quantity desc) as rank_order
from cte_sales)
select * from rnk
where rank_order <=3;

