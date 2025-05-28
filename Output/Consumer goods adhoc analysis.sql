use gdb023;
show tables;
select* from dim_customer;
select* from dim_product;
select * from fact_gross_price;
select * from fact_manufacturing_cost;
select * from fact_pre_invoice_deductions;
select * from fact_sales_monthly;
select count(*) from fact_sales_monthly;

-- ADHOC REQUEST #01

select market from dim_customer where customer='Atliq Exclusive' and region = 'APAC';

-- ADHOC REQUEST #02

WITH S AS (
    select
        count(distinct case when fiscal_year = 2020 then product_code end) as unique_products_2020,
        count(distinct case when fiscal_year = 2021 then product_code end) as unique_products_2021
    from fact_sales_monthly
)
SELECT
    unique_products_2020,
    unique_products_2021,
    ROUND(
        ((unique_products_2021 - unique_products_2020) * 100.0) / unique_products_2020,2) AS percentage_chg
FROM S;


-- ADHOC REQUEST #03

select segment,count(distinct product_code) as product_count 
from dim_product group by segment order by product_count desc;


-- ADHOC REQUEST #04

with A as (
           select segment, 
             count(distinct case when fiscal_year=2020 then product_code end) as product_count_2020,
			 count(distinct case when fiscal_year=2021 then product_code end) as product_count_2021
           from dim_product join fact_gross_price using (product_code) group by segment)
           select 
              Segment,product_count_2020,product_count_2021,(product_count_2021-product_count_2020) as difference 
           from A 
           order by difference desc limit 1;
           
-- ADHOC REQUEST #05

select 
    product_code,product,manufacturing_cost
from 
    dim_product join fact_manufacturing_cost using (product_code)
where 
    manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    OR
    manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- ADHOC REQUEST #06

select 
customer_code,customer,concat(round(avg(pre_invoice_discount_pct)*100,2),'%') as average_discount_percentage 
from dim_customer join fact_pre_invoice_deductions using (customer_code) 
where fiscal_year=2021 and market= 'india' 
group by customer_code,customer 
order by round(avg(pre_invoice_discount_pct)*100,2) 
desc limit 5;

-- ADHOC REQUEST #07

select 
   month(fsm.date) month_no ,monthname(fsm.date) as month,fsm.fiscal_year as year, 
   concat(round(sum(fgp.gross_price * fsm.sold_quantity)/1000000,2),'M') as Gross_Sales_Amount
from fact_gross_price fgp join fact_sales_monthly fsm using (product_code) 
     join dim_customer dc using(customer_code) 
where dc.customer='Atliq Exclusive' 
group by year,month_no,month 
order by year,month_no;

-- ADHOC REQUEST #08

select 
case when month(date) in (9,10,11) then 'Q1'
     when month(date) in (12,1,2) then 'Q2'
     when month(date) in (3,4,5) then 'Q3'
     else 'Q4'
     end as Quarter,
     concat(round(sum(sold_quantity)/1000000,3),'M') as total_sold_quantity
from fact_sales_monthly where fiscal_year = 2020
group by Quarter order by total_sold_quantity desc;

-- ADHOC REQUEST #09

WITH S AS (
    SELECT 
        dc.channel, 
        SUM(fgp.gross_price * fsm.sold_quantity) / 1000000 AS gross_sales
    FROM fact_gross_price fgp 
    JOIN fact_sales_monthly fsm USING (product_code) 
    JOIN dim_customer dc USING (customer_code)  
    GROUP BY dc.channel)
SELECT 
    channel,
    CONCAT(round((gross_sales),2),' M') AS gross_sales_mn,
    CONCAT(ROUND((gross_sales/ SUM(gross_sales) OVER ()) * 100, 2), '%') AS percentage
FROM S
ORDER BY gross_sales DESC;


-- ADHOC REQUEST #10

WITH ranked_products AS (
    SELECT 
        division,
        product_code,
        product,
        SUM(sold_quantity) AS total_sold_quantity,
        RANK() OVER (PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS rank_order
    FROM dim_product 
    JOIN fact_sales_monthly USING (product_code)
    WHERE fiscal_year = 2021
    GROUP BY division, product_code, product
)
SELECT * 
FROM ranked_products
WHERE rank_order <= 3
ORDER BY division, rank_order;

