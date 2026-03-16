-- This is a SQL Data Cleaning Project of database cafe_sales. 

-- The cafe sales dataset contains 10,000 rows of synthetic data representing sales transactions in a cafe. 
-- This dataset is intentionally "dirty," with missing values, inconsistent data, and errors introduced to provide a realistic scenario for data cleaning. 
-- https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training

SELECT *
FROM cafe_sales;

-- Creating a staging table (copy of original table)- I will work in and clean the data on this table to avoid issues with raw data.
CREATE TABLE cafe_sales_data_cleaning.cafe_sales_staging 
LIKE cafe_sales_data_cleaning.cafe_sales;

SELECT *
FROM cafe_sales_staging;
INSERT cafe_sales_staging
SELECT * FROM cafe_sales_data_cleaning.cafe_sales;

-- STEPS FOR DATA CLEANING
-- 1. check if the column names are SQL complaint
-- 2. check for duplicates and remove any
-- 3. standardize data and fix errors
-- 4. Look at null values and fill where possible or ignore
-- 5. remove any columns and rows that are not necessary 

-- I will do each of the following steps depending on the data step b step to make data cleaning easier.

-- 1. Change column names to SQL complaint names
-- our column names contain spaces which are not SQL complaint

SELECT *
FROM cafe_sales_staging;

ALTER TABLE cafe_sales_staging RENAME COLUMN `Transaction ID` TO transaction_id;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Item` TO item;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Quantity` TO quantity;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Price Per Unit` TO price_per_unit;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Total Spent` TO total_spent;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Payment Method` TO payment_method;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Location` TO location;
ALTER TABLE cafe_sales_staging RENAME COLUMN `Transaction Date` TO transaction_date;

-- 2. Check for duplicates 
SELECT *
FROM cafe_sales_staging;

-- I am assigning row numbers and partitioning by every column. 

SELECT transaction_id, item, quantity, price_per_unit, total_spent, payment_method, location, transaction_date,
		ROW_NUMBER() OVER (
			PARTITION BY transaction_id, item, quantity, price_per_unit, total_spent, payment_method, location, transaction_date
			) AS row_num
	FROM 
		cafe_sales_data_cleaning.cafe_sales_staging;

-- row_num =1 is assigned to unique rows.
-- I want to see if any row numbers have a row number >1. these are the rows that need to be deleted since they are duplicates.

SELECT *
FROM ( SELECT transaction_id, item, quantity, price_per_unit, total_spent, payment_method, location, transaction_date,
		ROW_NUMBER() OVER (
			PARTITION BY transaction_id, item, quantity, price_per_unit, total_spent, payment_method, location, transaction_date
			) AS row_num
	FROM 
		cafe_sales_data_cleaning.cafe_sales_staging
) duplicates
WHERE 
	row_num > 1;
    
-- Since there are no row_num > 1, it means there are no duplicates, removing them wont be necessary in this project.


-- 3. Standardize data

-- I am checking the distinct items and their price to fix the unknown values and errors
SELECT DISTINCT item, price_per_unit
FROM cafe_sales_staging
ORDER BY price_per_unit;

-- Cookie costs 1, Tea- 1.5, Coffee- 2, Cake- 3, Juice- 3, Sandwich - 4, Smoothie - 4, Salad - 5
-- Since cookie, tea, coffee and salad have unique prices- the data can be added for the unknown values with the same price.

SELECT item,price_per_unit
FROM cafe_sales_staging
WHERE price_per_unit = 1;

UPDATE cafe_sales_staging
SET item = 'Cookie'
WHERE price_per_unit = 1;

UPDATE cafe_sales_staging
SET item = 'Tea'
WHERE price_per_unit = 1.5;

UPDATE cafe_sales_staging
SET item = 'Coffee'
WHERE price_per_unit = 2;

UPDATE cafe_sales_staging
SET item = 'Salad'
WHERE price_per_unit = 5;

SELECT item,price_per_unit
FROM cafe_sales_staging;

UPDATE cafe_sales_staging
SET item = 'UNKNOWN'
WHERE item = '' OR item = 'ERROR';

-- now to calculate total_spent, we multiply quantity with price_per_unit where total_spent = '' or error or unknown 

UPDATE cafe_sales_staging
SET total_spent = ROUND(quantity * price_per_unit,1)
WHERE total_spent IS NULL OR total_spent = 0;

SELECT item, quantity, price_per_unit, total_spent
FROM cafe_sales_staging;

-- 4. Look at null values and fill where possible or ignore
-- for consistency in data, the blank and error/unknown values in payment method,location need to be 'UNKNOWN'

UPDATE cafe_sales_staging
SET payment_method = 'UNKNOWN'
WHERE payment_method = 'ERROR' OR payment_method = '' OR payment_method IS NULL;

SELECT *
FROM cafe_sales_staging;

UPDATE cafe_sales_staging
SET location = 'UNKNOWN'
WHERE location = 'ERROR' OR location = '' OR location IS NULL;

-- for date, we first check whether it is in date format data type.
DESCRIBE cafe_sales_staging;

-- the date is in text data type. we need to change it to date type.

UPDATE cafe_sales_staging
SET `transaction_date` = STR_TO_DATE(`transaction_date`, '%Y-%m-%d')
WHERE `transaction_date` IS NOT NULL 
  AND (`transaction_date` != 'ERROR' OR `transaction_date` != '' OR `transaction_date` != 'UNKNOWN');
  -- this code seems to give us continous errors so I will proceed step by step and clean up the date column values first
  
-- first we clean the date values
UPDATE cafe_sales_staging 
SET `transaction_date` = NULL
WHERE `transaction_date` = 'ERROR' 
   OR `transaction_date` = 'error'
   OR `transaction_date` = 'Error'
   OR `transaction_date` = 'UNKNOWN'
   OR `transaction_date` = 'unknown'
   OR `transaction_date` = ''
   OR `transaction_date` = ' '
   OR `transaction_date` IS NULL;

-- This should now work since 'ERROR' values are gone
UPDATE cafe_sales_staging
SET `transaction_date` = STR_TO_DATE(`transaction_date`, '%Y-%m-%d')
WHERE `transaction_date` IS NOT NULL;

SELECT transaction_date
FROM cafe_sales_staging;

-- now it has worked. another thing I noticed while checking data types was that total_spent is a text value and not double. 
-- total_spent data type needs to be changed.

ALTER TABLE cafe_sales_staging 
MODIFY COLUMN total_spent DOUBLE;

SELECT *
FROM cafe_sales_staging
ORDER BY price_per_unit;

-- The table is cleaned. The values which arent known as marked as UNKNOWN. Unknown transaction dates are kept NULL. 
-- The table is now ready for exploratory data analysis (EDA).

