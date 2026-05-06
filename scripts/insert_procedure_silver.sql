/*
====================================
Data inserting (silver layer tables)
====================================
This script (Stored Procedure) truncate silver layers tables and then insert data to it from the sources.
Also it gives some info as loading time, current process and if it is loaded successfuly or not by the error handling sys.
You can execute it by using this code: 'EXEC silver.load_silver'
NOTE: 
	THIS STORED PROCEDURE DOES NOT ACCEPT ANY PARAMETERS
*/

CREATE OR ALTER PROCEDURE silver.load_silver 
AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME,
			@batch_start_time DATETIME, @batch_end_time DATETIME
	SET @batch_start_time = GETDATE();
	/*
	==============================
	INSERTING DATA TO 'CRM' TABLES
	==============================
	*/
	--CLEANING [CRM_CUST_INFO]
	BEGIN TRY
		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT 'Inserting data into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			T.cst_id,
			T.cst_key,
			TRIM(T.cst_firstname) AS cst_firstname,
			TRIM(T.cst_lastname) AS cst_lastname,
			CASE UPPER(TRIM(T.cst_marital_status))
				WHEN 'S' THEN 'Single'
				WHEN 'M' THEN 'Married'
				ELSE 'N/A' END AS cst_marital_status,
			CASE UPPER(TRIM(T.cst_gndr))
				WHEN 'M' THEN 'Male'
				WHEN 'F' THEN 'Female'
				ELSE 'N/A' END AS cst_gndr,
			T.cst_create_date
		FROM (
			SELECT
				*,
				ROW_NUMBER() OVER(PARTITION BY CI.cst_id ORDER BY cst_create_date DESC) AS FLAG
			FROM bronze.crm_cust_info AS CI ) T
		WHERE T.FLAG = 1 AND T.cst_id IS NOT NULL
		SET @end_time = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';


		--CLEANING [CRM_PRD_INFO]
		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT 'Inserting data into: silver.crm_prd_info';
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
			CPI.prd_id,
			REPLACE(SUBSTRING(CPI.prd_key, 1, 5), '-', '_') AS cat_id,
			SUBSTRING(CPI.prd_key, 7, LEN(CPI.prd_key)) AS prd_key,
			CPI.prd_nm,
			ISNULL(CPI.prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(CPI.prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'N/A' END AS prd_line,
			CAST(CPI.prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(CPI.prd_start_dt) OVER(PARTITION BY CPI.prd_key ORDER BY CPI.prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info AS CPI
		SET @end_time = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';


		--CLEANING [CRM_SALES_DETAILS]
		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT 'Inserting data into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
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
			SD.sls_ord_num,
			SD.sls_prd_key,
			SD.sls_cust_id,
			CASE WHEN LEN(SD.sls_order_dt) != 8 OR SD.sls_order_dt = 0 THEN NULL
				 ELSE CAST(CAST(SD.sls_order_dt AS NVARCHAR) AS DATE) END AS sls_order_dt,
			CASE WHEN LEN(SD.sls_ship_dt) != 8 OR SD.sls_ship_dt = 0 THEN NULL
				 ELSE CAST(CAST(SD.sls_ship_dt AS NVARCHAR) AS DATE) END AS sls_ship_dt,
			CASE WHEN LEN(SD.sls_due_dt) != 8 OR SD.sls_due_dt = 0 THEN NULL
				 ELSE CAST(CAST(SD.sls_due_dt AS NVARCHAR) AS DATE) END AS sls_due_dt,
			CASE WHEN SD.sls_sales IS NULL OR SD.sls_sales < 0 OR SD.sls_sales != SD.sls_quantity * ABS(SD.sls_price)
					THEN SD.sls_quantity * ABS(SD.sls_price)
				 ELSE SD.sls_sales END AS sls_sales,
			SD.sls_quantity,
			CASE WHEN SD.sls_price IS NULL OR SD.sls_price <= 0
					THEN SD.sls_sales / NULLIF(SD.sls_quantity, 0)
				 ELSE SD.sls_price END AS sls_price
		FROM bronze.crm_sales_details as SD
		SET @end_time = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';


		/*
		==============================
		INSERTING DATA TO 'ERP' TABLES
		==============================
		*/
		--CLEANING [ERP_CUST_AZ12]
		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT 'Inserting data into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
		SELECT
			CASE WHEN EC.cid LIKE 'NAS%' THEN SUBSTRING(EC.cid, 4, LEN(EC.cid))
				 ELSE EC.cid END AS cid,
			CASE WHEN EC.bdate > GETDATE() THEN NULL
				 ELSE EC.bdate END AS bdate,
			CASE WHEN UPPER(TRIM(EC.GEN)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(EC.GEN)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'N/A' END AS gen
		FROM bronze.erp_cust_az12 AS EC
		SET @end_time = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';


		--CLEANING [ERP_LOC_A101]
		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT 'Inserting data into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT 
			REPLACE(EL.cid, '-', '') AS cid,
			CASE WHEN TRIM(EL.cntry) = 'DE' THEN 'Germany'
				 WHEN TRIM(EL.cntry) IN ('US', 'USA') THEN 'United States'
				 WHEN TRIM(EL.cntry) = '' OR EL.cntry IS NULL THEN 'N/A'
				 ELSE TRIM(EL.cntry) END AS cntry
		FROM bronze.erp_loc_a101 AS EL
		SET @end_time = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';


		--CLEANING [ERP_PX_CAT_GV2]
		SET @start_time = GETDATE();
		PRINT 'Truncating table: silver.erp_px_cat_gv2';
		TRUNCATE TABLE silver.erp_px_cat_gv2;
		PRINT 'Inserting data into: silver.erp_px_cat_gv2';
		INSERT INTO silver.erp_px_cat_gv2 (
			id,
			cat,
			suncat,
			maintenance
		)
		SELECT
			EPC.id,
			EPC.cat,
			EPC.subcat,
			EPC.maintenance
		FROM bronze.erp_px_cat_g1v2 AS EPC
		SET @end_time = GETDATE();
		PRINT 'Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';
		--Loading time for the whole batch
		SET @batch_end_time = GETDATE();
		PRINT '=================================';
		PRINT 'Loading silver layer is completed';
		PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds';
	END TRY

	--Error handeling
	BEGIN CATCH
		PRINT '=========================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT '=========================================';
		PRINT '# Error message: ' + ERROR_MESSAGE();
		PRINT '# Error number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
	END CATCH
END

--Execution script
EXEC silver.load_silver
