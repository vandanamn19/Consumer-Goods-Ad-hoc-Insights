1. List of markets in which customer "Atliq Exclusive" operates its business in the APAC region. 
SELECT DISTINCT
    (market)
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC'
ORDER BY market;

2. What is the percentage of unique product increase in 2021 vs. 2020? 
 SELECT 
    (cnt2 - cnt1) * 100 / cnt1 AS percent_increase
FROM
    (SELECT 
        COUNT(DISTINCT (product_code)) AS cnt1
    FROM
        fact_sales_monthly
    WHERE
        fiscal_year = 2020) AS y_2020,
    (SELECT 
        COUNT(DISTINCT (product_code)) AS cnt2
    FROM
        fact_sales_monthly
    WHERE
        fiscal_year = 2021) AS y_2021;
        
3. The unique product counts for each segment and sort them in descending order of product counts. 
SELECT 
    segment, COUNT(DISTINCT (product_code)) AS no_of_products
FROM
    dim_product
GROUP BY segment
ORDER BY no_of_products DESC;

4. Which segment had the most increase in unique products in 2021 vs 2020? 
WITH cte1 AS (  
SELECT   
    segment, 
    Count(DISTINCT(product_code)) AS 2020_cnt  
FROM     dim_product  
JOIN     fact_sales_monthly 
using    (product_code)  
WHERE    fiscal_year = 2020  
GROUP BY segment), 
cte2 AS (  
SELECT   
    segment, 
    Count(DISTINCT(product_code)) AS 2021_cnt  
FROM     dim_product  
JOIN     fact_sales_monthly 
using    (product_code)  
WHERE    fiscal_year = 2021  
GROUP BY segment)

SELECT 
    segment,
    2021_cnt AS product_count_2021,       
    2020_cnt AS product_count_2020,       
    2021_cnt-2020_cnt AS difference
FROM   cte1 
JOIN   cte2 
USING  (segment);

5. Get the products that have the highest and lowest manufacturing costs. 
SELECT 
    product_code, product, manufacturing_cost
FROM
    dim_product
        JOIN
    fact_manufacturing_cost USING (product_code)
WHERE
    manufacturing_cost IN (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost UNION SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY product_code;

6. Top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
SELECT 
    customer_code,
    customer,
    ROUND(AVG(pre_invoice_discount_pct) * 100, 2) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions
        JOIN
    dim_customer USING (customer_code)
WHERE
    fiscal_year = 2021 AND market = 'India'
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

7. Gross sales amount for the customer “Atliq Exclusive” for each month.
SELECT 
    MONTHNAME(fsm.date),
    fsm.fiscal_year,
    ROUND(SUM(gross_price * sold_quantity)) AS total_gross_price
FROM
    fact_sales_monthly AS fsm
        JOIN
    fact_gross_price USING (product_code)
        JOIN
    dim_customer AS c ON c.customer_code = fsm.customer_code
WHERE
    c.customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(fsm.date) , fsm.fiscal_year;

8. In which quarter of 2020, got the maximum total_sold_quantity? 
SELECT 
    CONCAT('Q',
            QUARTER(DATE_ADD(DATE_FORMAT(date, '%Y-%m-01'),
                    INTERVAL 4 MONTH))) AS qrtr,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY qrtr
ORDER BY total_sold_quantity DESC;

9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
WITH cte1 AS (
SELECT 
    channel,
    ROUND(SUM(gross_price * sold_quantity) / 100000,
            2) AS total_gross_price_mln
FROM
    fact_sales_monthly AS fsm
        JOIN
    fact_gross_price USING (product_code)
        JOIN
    dim_customer AS c ON c.customer_code = fsm.customer_code
WHERE
    fsm.fiscal_year = 2021
GROUP BY channel)

SELECT 
    channel,
    total_gross_price_mln,
    round((total_gross_price_mln*100/sum(total_gross_price_mln) OVER()),2) as percentage_contribution
FROM cte1
GROUP BY channel;

10. The top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021.
WITH cte1 AS (
SELECT 
    division,
    product_code,
    SUM(sold_quantity) AS total_sold_quantity
FROM
    dim_product
        JOIN
    fact_sales_monthly USING (product_code)
WHERE
    fiscal_year = 2021
GROUP BY division , product_code
),
cte2 as (
SELECT
    division,
    product_code,
    total_sold_quantity,
    DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS drank
FROM cte1 )
SELECT 
    division, product_code, total_sold_quantity, drank
FROM
    cte2
WHERE
    drank <= 3
