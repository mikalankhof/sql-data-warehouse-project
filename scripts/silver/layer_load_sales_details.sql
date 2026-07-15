/*
==================================================
Loading sales details into silver layer after data transformation and cleansing.
Following changes have been made:
- order, ship, and due dates changed to correct Data Type (CAST)
- Sales and Price recalculated
==================================================
*/


INSERT INTO silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
    END AS sls_order_dt,
    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
    END AS sls_ship_dt,
    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
    END AS sls_due_dt,
    CASE WHEN sls_sales IS NULL OR sls_sales< 0 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
            END AS sls_sales, -- recalculate sales if original value is wrong or missing
    sls_quantity,
    CASE WHEN sls_price IS NULL OR sls_price <= 0 
            THEN sls_sales/NULLIF(sls_quantity,0)
            ELSE sls_price
            END AS sls_price
FROM Bronze.crm_sales_details;

/*
====================================================
Data Quality Control Checks
====================================================
*/
-- check for invalid date order
SELECT 
*
FROM Silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt


--Check for Business Rules
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales < 0 OR sls_price < 0 OR sls_quantity < 0 
OR sls_price * sls_quantity != sls_sales
OR sls_sales IS NULL OR sls_price IS NULL OR sls_quantity IS NULL
ORDER BY sls_sales, sls_quantity, sls_price



SELECT *
FROM Silver.crm_sales_details
