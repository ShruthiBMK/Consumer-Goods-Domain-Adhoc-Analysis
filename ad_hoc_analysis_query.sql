-- 1. Which quarter of 2020 got the maximum total_sold_quantity?
SELECT (
    CASE WHEN MONTH(DATE) BETWEEN 9
        AND 11
        THEN "Q1"
    WHEN MONTH(DATE) IN (12, 1, 2)
        THEN "Q2"
    WHEN MONTH(DATE) BETWEEN 3 AND 5
        THEN "Q3"
    WHEN MONTH(DATE) BETWEEN 6 AND 8
        THEN "Q4"
    END
) AS quarter,
SUM(sold_quantity) AS sold_quantity
FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY sold_quantity DESC;
-- Q2 Provide a report with the Gross Sales Amount for the customer “Atliq Exclusive” for each month.
WITH cte AS (SELECT dc.customer,year(fs.date) as year, 
MONTHNAME(fs.date) as months, MONTH(fs.date) as month_no,
(fs.sold_quantity* fg.gross_price) as gross_sales 
FROM fact_sales_monthly fs 
JOIN dim_customer dc ON fs.customer_code = dc.customer_code
JOIN fact_gross_price fg ON fs.product_code= fg.product_code
WHERE dc.customer= "Atliq Exclusive")
SELECT months,year, CONCAT(ROUND(SUM(gross_sales)/1000000 ,2), 'M') AS gross_sales FROM cte
GROUP BY year,months
ORDER BY year,month_no;

-- 3. Which channel contributed the most to gross sales in FY 2021 and calculate its percentage contribution? 
WITH cte1 AS (SELECT dc.channel,fs.fiscal_year, 
sum(fs.sold_quantity* fg.gross_price) as gross_sales 
FROM fact_sales_monthly fs 
JOIN dim_customer dc ON fs.customer_code = dc.customer_code
JOIN fact_gross_price fg ON fs.product_code= fg.product_code
WHERE fs.fiscal_year =2021
GROUP BY dc.channel
ORDER BY gross_sales DESC )
SELECT channel, ROUND(gross_sales/1000000 ,2) AS gross_sales_in_mln,
round(gross_sales/(sum(gross_sales) OVER())*100,2) AS percnt_contri FROM cte1;

-- 4. Identify the top 3 products in each division based on total sold quantities for the fiscal year 2021.

with cte2 as (SELECT fs.product_code,concat(dp.product,"(",dp.variant,")") AS product,dp.division,fs.fiscal_year, 
sum(fs.sold_quantity) as tot_sold_qty,
RANK() OVER (
        PARTITION BY dp.division
        ORDER BY SUM(fs.sold_quantity) DESC
    ) AS product_rank
FROM fact_sales_monthly fs 
JOIN dim_product dp ON fs.product_code = dp.product_code
WHERE fs.fiscal_year =2021
GROUP BY dp.division, fs.product_code)
SELECT product, division, tot_sold_qty FROM cte2
where product_rank<=3;

-- 5.Which segment had the most significant increase in unique products from 2020 to 2021?
WITH prod_table AS (SELECT  dp.segment, fs.fiscal_year, count(distinct fs.product_code)  as prod_count
                   FROM fact_sales_monthly fs join dim_product dp ON fs.product_code= dp.product_code 
                   GROUP BY dp.segment, fs.fiscal_year)
	SELECT prod_2020.segment, prod_2020.prod_count as prod_count_2020,
    prod_2021.prod_count as prod_count_2021,
    prod_2021.prod_count-prod_2020.prod_count AS difference
    FROM prod_table prod_2020
    JOIN prod_table prod_2021 ON prod_2020.segment=prod_2021.segment
    AND prod_2020.fiscal_year=2020  AND prod_2021.fiscal_year=2021
    ORDER BY difference DESC;
    
    -- 6. Analyze the unique product counts for each segment and sort them in descending order of product counts.
    
SELECT  segment,  count(distinct product_code)  as prod_count
                   FROM  dim_product 
                   GROUP BY segment
                   ORDER BY prod_count desc;
                   
-- 7. Identify the markets in which the customer "Atliq Exclusive" operates its business in the APAC region. Present the findings in an insightful way.
SELECT DISTINCT market FROM dim_customer 
WHERE region ="APAC" AND customer ="Atliq Exclusive";

-- 8.Compare the unique product counts between 2020 and 2021. Calculate the percentage change and present the analysis.
WITH unique_products as (SELECT fiscal_year,count(distinct product_code) as unique_products
         from fact_sales_monthly 
         group by fiscal_year)
SELECT 
    up_2020.unique_products as unique_products_2020,
    up_2021.unique_products as unique_products_2021,
    round((up_2021.unique_products - up_2020.unique_products)/up_2020.unique_products * 100,2) as percentage_change
FROM 
    unique_products up_2020
CROSS JOIN 
    unique_products up_2021
WHERE 
    up_2020.fiscal_year = 2020  AND  up_2021.fiscal_year = 2021;
    
-- 9.Identify the products with the highest and lowest manufacturing costs. Include their respective details and highlight the findings.

SELECT m.product_code, concat(product," (",variant,")") AS product, manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
WHERE manufacturing_cost= 
(SELECT min(manufacturing_cost) FROM fact_manufacturing_cost)
OR
manufacturing_cost = 
(SELECT max(manufacturing_cost) FROM fact_manufacturing_cost) 
ORDER BY manufacturing_cost DESC;

-- 10.Analyze the top 5 customers who received the highest average pre-invoice discount percentage for the fiscal year 2021 
 --  and in the Indian market.
SELECT c.customer_code, c.customer, round(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage
FROM fact_pre_invoice_deductions d
JOIN dim_customer c ON d.customer_code = c.customer_code
WHERE c.market = "India" AND fiscal_year = "2021"
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;



