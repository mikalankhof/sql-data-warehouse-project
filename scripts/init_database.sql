/*
==================================
Create Database and Schemas
==================================
This script creates a new database : Datawarehouse, after checking if it already exists. 
if it exists, it is dropped and then recreated. Additionally, the script creates three schemas, Bronze, Silver, and Gold.

WARNING: this scrips drops the database if it already exists with all data inside it permanently. 
Proceed with Caution and create backups if needed before running script.
*/

USE Master;
GO

-- Drop and recreate DWH if already exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN 
  ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE
  DROP DATABASE DataWarehouse;
END
GO

-- Create Database 'DataWarehouse'
CREATE DATABASE DataWarehouse;

GO

USE DataWarehouse;

GO 

-- Create Schemas
CREATE SCHEMA Bronze;
GO
CREATE SCHEMA Silver;
GO
CREATE SCHEMA Gold;
