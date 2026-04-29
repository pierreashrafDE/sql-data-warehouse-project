/*
====================================
Data inserting (bronze layer tables)
====================================
This script (Stored Procedure) truncate bronze layers tables and then insert data to it from the sources.
You can execute it by using this code: 'EXEC bronze.load_bronze'
NOTE: 
	THIS STORED PROCEDURE DOES NOT ACCEPT ANY PARAMETERS
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
	PRINT '====================';
	PRINT 'Loading Bronze Layer';
	PRINT '====================';

	--truncate and insert data to table: 'crm_cust_info'
	PRINT '--=[Loading CRM Tables]=--';
	PRINT 'Truncating Table: bronze.crm_cust_info';
	TRUNCATE TABLE bronze.crm_cust_info;

	PRINT 'Inserting Data into: bronze.crm_cust_info';
	BULK INSERT bronze.crm_cust_info
	FROM 'C:\datasets\source_crm\cust_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	--truncate and insert data to table: 'crm_prd_info'
	PRINT 'Truncating Table: bronze.crm_prd_info';
	TRUNCATE TABLE bronze.crm_prd_info;

	PRINT 'Inserting Data into: bronze.crm_prd_info';
	BULK INSERT bronze.crm_prd_info
	FROM 'C:\datasets\source_crm\prd_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	--truncate and insert data to table: 'crm_sales_details'
	PRINT 'Truncating Table: bronze.crm_sales_details';
	TRUNCATE TABLE bronze.crm_sales_details;

	PRINT 'Inserting Data into: bronze.crm_sales_details';
	BULK INSERT bronze.crm_sales_details
	FROM 'C:\datasets\source_crm\sales_details.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	PRINT '--=[Loading ERP Tables]=--';
	--truncate and insert data to table: 'erp_cust_az12'
	PRINT 'Truncating Table: bronze.erp_cust_az12';
	TRUNCATE TABLE bronze.erp_cust_az12;

	PRINT 'Inserting Data into: bronze.erp_cust_az12';
	BULK INSERT bronze.erp_cust_az12
	FROM 'C:\datasets\source_erp\CUST_AZ12.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	--truncate and insert data to table: 'erp_loc_a101'
	PRINT 'Truncating Table: bronze.erp_loc_a101';
	TRUNCATE TABLE bronze.erp_loc_a101;

	PRINT 'Inserting Data into: bronze.erp_loc_a101';
	BULK INSERT bronze.erp_loc_a101
	FROM 'C:\datasets\source_erp\LOC_A101.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);

	--truncate and insert data to table: 'erp_px_cat_gv2'
	PRINT 'Truncating Table: bronze.erp_px_cat_gv2';
	TRUNCATE TABLE bronze.erp_px_cat_gv2;

	PRINT 'Inserting Data into: bronze.erp_px_cat_gv2';
	BULK INSERT bronze.erp_px_cat_gv2
	FROM 'C:\datasets\source_erp\PX_CAT_G1V2.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
	);
END

--Execution script
EXEC bronze.load_bronze
