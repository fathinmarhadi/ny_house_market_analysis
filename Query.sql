-- DATA PREPARTION
   
	-- Check for null values in the dataset
SELECT *
FROM ny_house nh 
WHERE BROKERTITLE IS NULL 
	OR TYPE IS NULL 
	OR PRICE IS NULL 
	OR BEDS IS NULL 
	OR BATH IS NULL 
	OR PROPERTYSQFT IS NULL 
	OR ADDRESS IS NULL 
	OR STATE IS NULL 
	OR LATITUDE IS NULL 
	OR LONGITUDE IS NULL;

-- Check for Duplicate Data
SELECT *, COUNT(*)
FROM ny_house nh 
GROUP BY BROKERTITLE, 
		TYPE, 
		PRICE, 
		BEDS, 
		BATH, 
		PROPERTYSQFT, 
		ADDRESS, 
		STATE, 
		MAIN_ADDRESS, 
		ADMINISTRATIVE_AREA_LEVEL_2, 
		LOCALITY, SUBLOCALITY, 
		STREET_NAME, 
		LONG_NAME, 
		FORMATTED_ADDRESS, 
		LATITUDE, 
		LONGITUDE
HAVING COUNT(*) > 1;

-- Delete Duplicate Data
DELETE FROM ny_house
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM ny_house
    GROUP BY BROKERTITLE, 
    TYPE, PRICE, BEDS, BATH, 
    PROPERTYSQFT, ADDRESS, STATE, 
    MAIN_ADDRESS, ADMINISTRATIVE_AREA_LEVEL_2, 
    LOCALITY, SUBLOCALITY, STREET_NAME, 
    LONG_NAME, FORMATTED_ADDRESS, LATITUDE, LONGITUDE
);

-- Remove "Brokered by" from brokertitle values
UPDATE ny_house
SET BROKERTITLE = REPLACE(BROKERTITLE, 'Brokered by ', '');

-- Drop Unnecessary Columns
ALTER TABLE ny_house
DROP COLUMN main_address,
DROP COLUMN locality,
DROP COLUMN sublocality,
DROP COLUMN street_name,
DROP COLUMN long_name,
DROP COLUMN formatted_address;
	
-- Remove postcode from State Column
UPDATE ny_house
SET STATE = LEFT(STATE, LENGTH(STATE) - 5)

-- Check if the postcode successfully remove
SELECT state
FROM ny_house
WHERE POSITION('NY' IN STATE) + 2 < LENGTH(STATE);


-- EXPLORATORY DATA ANALYSIS (EDA)

-- Price Analysis
-- What is the min, max, average, and median price of houses in each state?
SELECT 
    type,
    brokertitle,
    state,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    round(AVG(price)::NUMERIC, 2) AS avg_price,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM 
    ny_house nh 
GROUP BY TYPE, brokertitle, state;

-- Property Size Analysis:
--  calculate the average price of houses based on property size (square footage).
SELECT 
    propertysqft,
    AVG(price) AS avg_price
FROM 
    ny_house nh 
WHERE 
    type = 'House for sale'
GROUP BY 
    propertysqft;
-- calculate the average property size for each property type (e.g., houses, condos, co-ops).
SELECT 
    type,
    CEIL (AVG(propertysqft)::NUMERIC ) AS avg_size
FROM 
    ny_house nh 
GROUP BY 
    type;
   
-- calculate the average price per square foot for each property size.
SELECT 
    propertysqft,
    round(AVG(price / propertysqft)::NUMERIC, 2) AS avg_price_per_sqft
FROM 
    ny_house nh 
GROUP BY 
    propertysqft;
   
-- Bedroom and Bathroom Trends:
-- calculate the average price of houses based on the number of bedrooms and bathrooms.
SELECT 
    beds,
    bath,
    round(AVG(price)::NUMERIC, 2) AS avg_price
FROM 
    ny_house nh 
GROUP BY 
    beds,
    bath;
-- calculate the average property size for each combination of bedrooms and bathrooms.
SELECT 
	TYPE,
    beds,
    bath,
    CEIL(AVG(propertysqft)::NUMERIC) AS avg_size
FROM 
    ny_house nh 
GROUP BY 
	TYPE, 
    beds,
    bath;
   
--  Broker Performance Analysis
-- count the number of properties listed by each broker.
SELECT 
    brokertitle,
    COUNT(*) AS num_properties_listed
FROM 
    ny_house nh 
GROUP BY 
    brokertitle
ORDER BY 
    num_properties_listed DESC;
-- calculate the average price of properties listed by each broker
SELECT 
    brokertitle,
    round(AVG(price)::NUMERIC, 2) AS avg_price
FROM 
    ny_house nh
GROUP BY 
    brokertitle;
-- count the number of properties listed by each broker within specific property types or neighborhoods.
SELECT 
    brokertitle,
    TYPE,
    state,
    COUNT(*) AS num_properties_listed,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    round(AVG(price)::NUMERIC, 2) AS avg_price
FROM 
    ny_house nh
WHERE TYPE = 'House for sale' AND state LIKE '%Brooklyn%'
GROUP BY 
    brokertitle,
    TYPE,
    state
ORDER BY num_properties_listed DESC;

-- Market Segmentation Analysis
-- segment the housing market based on price range, and family size on property

WITH price_family_cte AS (
    SELECT
        CASE
            WHEN price < 500000 THEN 'Affordable'
            WHEN price >= 500000 AND price < 1000000 THEN 'Mid-Range'
            ELSE 'Luxury'
        END AS price_segment,
        CASE
            WHEN beds <= 2 THEN 'Small Family'
            WHEN beds >= 3 AND beds <= 5 THEN 'Medium Family'
            ELSE 'Large Family'
        END AS family_size_segment,
        price
    FROM
        ny_house
)
SELECT
    family_size_segment,
    price_segment,
    ROUND(AVG(price)::NUMERIC, 2) AS avg_price,
    COUNT(*) AS num_properties
FROM
    price_family_cte
GROUP BY
    family_size_segment,
    price_segment;



select * from ny_house