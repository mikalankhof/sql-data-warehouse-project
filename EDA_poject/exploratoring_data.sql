/*
===============================================================
The following scrips has simple queries to explore the data in my DataWarehouse. 
This allows for a better understanding of the data so we can start analyzing more effectively.
===============================================================
*/

--explore all countries possible
SELECT DISTINCT country FROM gold.dim_customers;

-- Explore all cateogries in products
SELECT DISTINCT category, subcategory, product_name from gold.dim_products
ORDER BY 1,2,3

-- Date exploration

SELECT 
MIN (order_date), 
MAX(order_date) ,
DATEDIFF (year, min(order_date), max(order_date ))
FROM gold.fact_sales

SELECT 
MIN(birthdate),
max(birthdate),
DATEDIFF(year, min(birthdate), GETDATE()) AS OldestCustomer,
DATEDIFF (year, MAX(birthdate), GETDATE()) AS YoungestCustomer
FROM gold.dim_customers

==========================================================
==========================================================
-- seperate analysis
==========================================================
==========================================================
SELECT SUM(sales_amount) TotalSales FROM gold.fact_sales

SELECT COUNT(quantity) NumberofSales FROM gold.fact_sales

SELECT AVG (price) AvgPrice FROM gold.fact_sales

SELECT DISTINCT COUNT(DISTINCT order_number) TotalOrders FROM gold.fact_sales

SELECT COUNT(product_key) totalproducts FROM gold.dim_products

SELECT COUNT(customer_id) TotalCustomers FROM gold.dim_customers


SELECT COUNT(distinct customer_id) TotalCustomers FROM gold.fact_sales

==========================================================
==========================================================
-- creating a report combining all queries:
==========================================================
==========================================================
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name, COUNT(quantity) Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name, AVG(sales_amount) Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders' AS measure_name, COUNT(DISTINCT order_number) Measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Products' AS measure_name, COUNT(DISTINCT product_key) Measure_value FROM gold.dim_products
UNION ALL 
SELECT 'Total Customers' AS measure_name, COUNT(customer_id) Measure_value FROM gold.dim_customers
