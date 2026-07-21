/*
===================================================
This script creates a ready to use customer report as a view in the gold layer. 
The view is made up out of multiple CTE's, doing various transformations to get an easy to use and read report about the customers.
===================================================

*/
CREATE VIEW gold.report_customers AS

WITH base_query AS

(
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_id,
c.customer_number,
CONCAT(c.first_name, '', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_id = c.customer_id
WHERE order_date IS NOT NULL
)
,customer_aggregation AS
(
SELECT 
    customer_id,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS lastorder,
    DATEDIFF(month, min(order_date), MAX(order_date))AS life_span
FROM base_query
GROUP BY 
    customer_id,
    customer_number,
    customer_name,
    age
)

SELECT  
    customer_id,
    customer_number,
    customer_name,
    age,
      CASE WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 and 29 THEN '20-29'
        WHEN age BETWEEN 30 and 39 THEN '30-39'
        WHEN age BETWEEN 40 and 49 THEN '40-49'
        ELSE '50 and above'
        END AS age_group,
    CASE WHEN life_span >= 12 AND total_sales >5000 THEN 'VIP'
        WHEN life_span >= 12 AND total_sales <=5000 THEN 'Regular'
        ELSE 'New'
        END AS customer_segment,
    lastorder,
    DATEDIFF(month, lastorder, GETDATE()) AS recency,
    total_orders,
    total_products,
    total_quantity,
    total_sales,
    life_span,
    total_sales/total_orders AS avg_order_value,
    CASE WHEN life_span = 0 THEN total_sales
        ELSE total_sales/life_span
        END AS monthly_spend

FROM customer_aggregation
