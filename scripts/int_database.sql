/*
===========================
Create Database and Schemas
===========================
Script purpose:
	This script creates a new database named 'DataWareHouse' after checking if it is already exists.
	IF the database exists, it will be dropped and recreated. Also, this script sets up three schemas
	within the database: 'bronze', 'silver', 'gold'.
*/

USE master;
GO

--Drop and recreate the 'DataWareHouse' database
IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE name = 'DataWareHouse')
BEGIN
	ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWareHouse;
END;
GO


--Create the 'DataWareHouse' database
CREATE DATABASE DataWareHouse;
GO

USE DataWareHouse;
GO

--Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
