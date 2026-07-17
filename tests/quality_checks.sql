/*
================================================
Quality Checks
================================================
Script Purpose:
  This script performs various quality checks for and standardization across the 'silver' schema.
  It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.
Usage Notes:
  - Run these checks after data loading Silver Layer.
  - Investigate and resolve any discrepancies found during the checks.
*/



===================================
--prd_info table
===================================
-- Quality Check, Nulls or Duplicates in Primary Key
-- Expectation: no result

SELECT
prd_id,
count(*)
FROM Silver.crm_prd_info
GROUP BY prd_id
HAVING count(*) >1 OR prd_id IS NULL

-- no unwanted spaces check or
SELECT 
prd_nm
FROM Silver.crm_prd_info
WHERE prd_nm!= TRIM(prd_nm)

--Check for nulls/negatives
SELECT
prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data standardization & consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info


-- check for invalid dates
SELECT
*
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt


SELECT
*
FROM silver.crm_prd_info



================================
--sales_details table checks
================================

-- check for invalid date order
SELECT 
*
FROM Silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;


--Check for Business Rules
SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales < 0 OR sls_price < 0 OR sls_quantity < 0 
OR sls_price * sls_quantity != sls_sales
OR sls_sales IS NULL OR sls_price IS NULL OR sls_quantity IS NULL
ORDER BY sls_sales, sls_quantity, sls_price;


===============================
--px_cat_g1v2 table checks
===============================
-- check for unwanted spaces
SELECT 
id,
cat,
subcat,
maintenance
FROM Bronze.erp_PX_CAT_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- data standardization and consistency
SELECT DISTINCT 
maintenance 
FROM Bronze.erp_PX_CAT_g1v2

SELECT * from Silver.erp_PX_CAT_g1v

===============================
--px_loc_a101 table checks
===============================

-- data standardization & consistency
SELECT DISTINCT 
loc_country 
FROM silver.erp_loc_a101
