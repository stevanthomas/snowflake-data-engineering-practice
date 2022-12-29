--The process in loading data is as follows:
    -- Create a storage integration and pull the service account from the integration
    -- Go to the bucket as admin and create a role that enables the storage integration to have read access
    -- Create an external stage in Snowflake 

--Creating A Storage Integration for Google Cloud Storage Bucket
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE STORAGE INTEGRATION gcs_datasets
TYPE = 'EXTERNAL_STAGE'
STORAGE_PROVIDER = 'GCS'
ENABLED = TRUE
STORAGE_ALLOWED_LOCATIONS = (''); --Enter bucket where csv file is stored

DESC STORAGE INTEGRATION gcs_datasets;

CREATE OR REPLACE DATABASE USEDCARS;
USE DATABASE USEDCARS;
USE ROLE ACCOUNTADMIN;
GRANT USAGE ON database USEDCARS TO ROLE SYSADMIN;


--Creating the file format for loading the CSV 
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE FILE FORMAT used_cars_csv
TYPE = 'CSV';


--Creating a table to copy the data into

CREATE OR REPLACE TABLE  USED_CARS_INDIA
(Index INTEGER PRIMARY KEY,
 CarName STRING ,
 Make STRING,
 Model STRING,
 Make_Year INTEGER,
 Color STRING ,
 Body_Type STRING,
 MileageRun INTEGER,
 No_of_Owners STRING,
 Seating_Capacity INTEGER,
 Fuel_Type STRING,
 Fuel_Tank_Capacity INTEGER,
 Engine_Type STRING,
 CC_Displacement INTEGER,
 Transmission STRING,
 Transmission_Type STRING,
 Power INTEGER,
 Torque INTEGER,
 Mileage FLOAT,
 Emission STRING,
 Price INTEGER);
 

--Creating a new role dev to work the project on
USE ROLE ACCOUNTADMIN;
CREATE or REPLACE ROLE  DEV;
GRANT USAGE ON DATABASE USEDCARS TO ROLE DEV;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DEV;
GRANT USAGE ON ALL SCHEMAS IN DATABASE USEDCARS TO ROLE DEV;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA USEDCARS.PUBLIC TO ROLE DEV;
GRANT USAGE ON FILE FORMAT USED_CARS_CSV TO ROLE DEV;
GRANT ROLE DEV TO USER stevanthomas; --Have to specify which account name to give the role access to or else it will just lie unused

GRANT CREATE STAGE ON SCHEMA PUBLIC TO DEV; 
GRANT USAGE ON INTEGRATION GCS_DATASETS TO DEV;


USE ROLE DEV;
USE DATABASE USEDCARS;
USE WAREHOUSE COMPUTE_WH;


--Creating the stage

CREATE STAGE used_cars_stage
URL = '' --Enter URL in Google Cloud Storage Bucket
STORAGE_INTEGRATION = gcs_datasets
FILE_FORMAT = used_cars_csv;

LIST @used_cars_stage;

-- An unknown error kept preventing me from uploading. Hence the 'on_error' statement
COPY INTO USEDCARS.PUBLIC.USED_CARS_INDIA
FROM @used_cars_stage
ON_ERROR = 'CONTINUE';


SELECT *
FROM USED_CARS_INDIA;



USE ROLE ACCOUNTADMIN;
DROP ROLE DEV;
DROP TABLE USEDCARS.PUBLIC.USED_CARS_INDIA
DROP SCHEMA USEDCARS.PUBLIC;
DROP DATABASE USEDCARS;
DROP STAGE used_cars_stage;
