/*
===================================================================
Stored Procedure: Loading Data into silver layer
===================================================================
This script creates a Stored Procedure for inserting data into the silver tables.
By running this script you:
- truncate the tables
- insert data into tables

Parameters:
  None

how to execute:
  EXEC silver.load_silver;
====================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN 
    DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===========================';
        PRINT 'Loading Silver Layer';
        PRINT '===========================';
        PRINT '---------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '---------------------------';
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info'
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting Data into: silver.crm_cust_info'
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
        WHERE Flag_last = 1;
        SET @end_time = GETDATE();
        PRINT'>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '------------------------';

        SET @start_time = GETDATE()
        PRINT '>> Truncating Table: silver.crm_prd_info'
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting Data into: silver.crm_prd_info'
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key,1, 5), '-' , '_') AS cat_id, -- extract category ID
        SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extract product key
        prd_nm,
        ISNULL(prd_cost, 0) AS prd_cost,
        CASE UPPER(TRIM(prd_line))   --standardize data
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
                END AS prd_line,
        CAST (prd_start_dt AS DATE) AS prd_start_dt,
        CAST(LEAD (prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt -- calculate end date as one day before next start date
        FROM Bronze.crm_prd_info
        SET @end_time = GETDATE();
        PRINT'>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '------------------------';

        SET @start_time = GETDATE()
        PRINT '>> Truncating Table: silver.crm_sales_details'
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting Data into: silver.crm_sales_details'
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
         SET @end_time = GETDATE();
        PRINT'>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '------------------------';

        SET @start_time = GETDATE()
        PRINT '>> Truncating Table: silver.erp_cust_az12'
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting Data into: silver.erp_cust_az12'

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
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT'>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '------------------------';

        SET @start_time = GETDATE()
        PRINT '>> Truncating Table: silver.erp_loc_a101'
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting Data into: silver.erp_loc_a101'
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
        FROM Bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT'>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '------------------------';

        SET @start_time = GETDATE()
        PRINT '>> Truncating Table: silver.erp_PX_CAT_g1v2'
        TRUNCATE TABLE silver.erp_PX_CAT_g1v2;
        PRINT '>> Inserting Data into: silver.erp_PX_CAT_g1v2'
        INSERT INTO silver.erp_PX_CAT_g1v2(
            id, cat, subcat, maintenance
        )
        SELECT 
        id,
        cat,
        subcat,
        maintenance
        FROM Bronze.erp_PX_CAT_g1v2;
         SET @end_time = GETDATE();
        PRINT'>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '------------------------';
    END TRY
      SET @batch_end_time = GETDATE();
        PRINT '====================================='
        PRINT 'Loading silver Layer is completed';
        PRINT ' - Total Load Duration Batch: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds'
        PRINT '====================================='
     BEGIN CATCH
        PRINT '=============================='
        PRINT 'ERROR Ocurred during Load Silver Layer'
        PRINT  'ERROR MESSAGE' + ERROR_MESSAGE();
        PRINT  'ERROR MESSAGE' + CAST(ERROR_NUMBER()AS NVARCHAR);
        PRINT  'ERROR MESSAGE' + CAST(ERROR_STATE()AS NVARCHAR);
        PRINT '=============================='
    END CATCH
END
