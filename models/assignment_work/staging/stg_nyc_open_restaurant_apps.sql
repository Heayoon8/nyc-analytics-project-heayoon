-- stg_nyc_open_restaurant_apps.sql
-- Clean and standardize NYC Open Restaurant Applications data
-- One row per application

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Keep all columns except ones we're transforming below
        * EXCEPT (
            objectid,
            seating_interest_sidewalk,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            business_address,
            street,
            borough,
            zip,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating,
            qualify_alcohol,
            latitude,
            longitude,
            time_of_submission
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS application_key,

        -- Request details
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
        CAST(business_address AS STRING) AS business_address,
        CAST(street AS STRING) AS street,

        -- Location - standardize borough
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Location - clean zip code (same common problems as 311 data)
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 5 THEN TRIM(CAST(zip AS STRING))
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 9 THEN TRIM(CAST(zip AS STRING))
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 10
                AND REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}-\d{4}')
                THEN TRIM(CAST(zip AS STRING))
            ELSE NULL
        END AS zip,

        -- Booleans - convert string to boolean
        CASE
            WHEN UPPER(TRIM(approved_for_sidewalk_seating)) = 'YES' THEN TRUE
            WHEN UPPER(TRIM(approved_for_sidewalk_seating)) = 'NO' THEN FALSE
            ELSE NULL
        END AS approved_for_sidewalk_seating,

        CASE
            WHEN UPPER(TRIM(approved_for_roadway_seating)) = 'YES' THEN TRUE
            WHEN UPPER(TRIM(approved_for_roadway_seating)) = 'NO' THEN FALSE
            ELSE NULL
        END AS approved_for_roadway_seating,

        CASE
            WHEN UPPER(TRIM(qualify_alcohol)) = 'YES' THEN TRUE
            WHEN UPPER(TRIM(qualify_alcohol)) = 'NO' THEN FALSE
            ELSE NULL
        END AS qualify_alcohol,

        -- Coordinates
        CAST(latitude AS DECIMAL) AS latitude,
        CAST(longitude AS DECIMAL) AS longitude,

        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE objectid IS NOT NULL

    -- Deduplicate on objectid
    QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned
