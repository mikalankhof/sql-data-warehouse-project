--ERP tables clean and load
/*
==============================================
Following scripst clean, transform and load data into silver ERP tables
==============================================
*/
INSERT INTO silver.erp_cust_az12(
    cid,
    birthdate,
    gender
)
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Removes 'NAS' as prefix if present
    ELSE cid
    END cid,
CASE WHEN birthdate > GETDATE ()THEN NULL -- gets rid of birthdates in future
    ELSE birthdate
    END birthdate,
  CASE 
        WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gender)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gender --normalizes gender values and handles unknown
FROM bronze.erp_cust_az12

--========================================
-- Data standardization and consistency
--========================================
SELECT DISTINCT 
gender -- should only be three, n/a, female, and male
FROM silver.erp_cust_az12;

--Invalid dates
SELECT birthdate FROM silver.erp_cust_az12 WHERE birthdate > GETDATE()-- no future birthdates


SELECT DISTINCT
    gender,
    CASE 
        WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gender)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gender
FROM Bronze.erp_cust_az12;



--==================================
--silver.erp_loc_a101 transformation and load
--==================================
INSERT INTO silver.erp_loc_a101(
    loc_cid,
    loc_country
)

SELECT 
REPLACE (loc_cid, '-' , '') cid,--gets rid of '-' in ID to connect to customer key in crm_cst_info table
CASE    WHEN TRIM(loc_country) = 'DE' THEN 'Germany'
        WHEN TRIM (loc_country) IN ( 'US' , 'USA') THEN 'United States'
        WHEN TRIM (loc_country) = '' OR loc_country IS NULL THEN 'n/a'
        ELSE TRIM (loc_country)
        END AS loc_country -- normalize and handle missing country values

FROM Bronze.erp_loc_a101



-- data standardization & consistency
SELECT DISTINCT 
loc_country 
FROM silver.erp_loc_a101


SELECT * FROM silver.erp_loc_a101




-- erp_cat_g1v2 table
INSERT INTO silver.erp_PX_CAT_g1v2(
    id, cat, subcat, maintenance
)
SELECT 
id,
cat,
subcat,
maintenance
FROM Bronze.erp_PX_CAT_g1v2

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

SELECT * from Silver.erp_PX_CAT_g1v2
