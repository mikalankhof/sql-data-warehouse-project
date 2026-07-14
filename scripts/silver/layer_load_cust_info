/*-- Silver Layer Load 1
============================================
this script cleans and transforms data before loading it into the silver_cust_info table
what is changed:
- trimmed first and lastname
- marital status and gender changed to full words in stead of single letters for easier reading/understanding
- removed any PK duplicates by ranking them DESC to only use most recently created cust_id
============================================
*/


INSERT INTO silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)

SELECT
cst_id,
cst_key,
TRIM (cst_firstname) AS cst_firstname,
TRIM (cst_lastname) AS cst_lastname,
CASE 
    WHEN TRIM(UPPER(cst_marital_status)) = 'S' THEN 'Single'
    WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Married'
    ELSE 'n/a'
    END cst_marital_status,
CASE 
    WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
    WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
    ELSE 'n/a'
    END cst_gndr,
cst_create_date
FROM (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_last
FROM Bronze.crm_cust_info
WHERE cst_ID IS NOT NULL
)t 
WHERE Flag_last = 1
