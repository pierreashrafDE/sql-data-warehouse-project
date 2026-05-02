/*
===========================
Gold layer (views creation)
===========================
This script changes the names of columns of silver tables to be easy to read and deal with.
Also creates three views, one fact view 'gold.fact_sales' and two dim views 'gold.dim_customers' and 'gold.dim_products'.

NOTE:-
	DON'T RUN THE ENTIRE SCRIPT ALL AT ONCE...RUN EACH PART INDIVIDUALY BECAUSE IT CAN BE ONLY ONE VIEW STATEMENT PER QUERY.
	=======================
*/

CREATE VIEW gold.dim_customer AS
SELECT
	ROW_NUMBER() OVER(ORDER BY CI.cst_id) AS customer_key,
	CI.cst_id AS customers_id,
	CI.cst_key AS customer_number,
	CI.cst_firstname AS first_name,
	CI.cst_lastname AS last_name,
	LA.cntry AS country,
	CI.cst_material_status AS marital_status,
	CASE WHEN CI.cst_gndr != 'N/A' THEN CI.cst_gndr
		 ELSE COALESCE(CA.gen, 'N/A') END AS gender,
	CI.cst_create_date AS create_date,
	CA.bdate AS birthdate
FROM silver.crm_cust_info AS CI
LEFT JOIN silver.erp_cust_az12 AS CA
ON CI.cst_key = CA.cid
LEFT JOIN silver.erp_loc_a101 AS LA
ON CI.cst_key = LA.cid


CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY PN.prd_key, PN.prd_start_dt) AS product_key,
	PN.prd_id AS product_id,
	PN.prd_key AS product_number,
	PN.prd_nm AS product_name,
	PN.cat_id AS category_id,
	EP.cat AS category,
	EP.suncat AS subcategory,
	EP.maintenance,
	PN.prd_cost AS cost,
	PN.prd_line AS product_line,
	PN.prd_start_dt AS start_date
FROM silver.crm_prd_info AS PN
LEFT JOIN silver.erp_px_cat_gv2 AS EP
ON PN.cat_id = EP.id


CREATE VIEW gold.fact_sales AS
SELECT
	SD.sls_ord_num AS order_number,
	DP.product_key,
	DC.customer_key,
	SD.sls_order_dt AS order_date,
	SD.sls_ship_dt AS ship_date,
	SD.sls_due_dt AS due_date,
	SD.sls_sales sales_amount,
	SD.sls_quantity,
	SD.sls_price
FROM silver.crm_sales_details AS SD
LEFT JOIN gold.dim_customer AS DC
ON SD.sls_cust_id = DC.customers_id
LEFT JOIN gold.dim_products AS DP
ON SD.sls_prd_key = DP.product_number
