WITH source AS (
    SELECT * 
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        
        CAST(objectid AS STRING) AS restaurant_id,

        
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,

        
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip,

        
        CAST(borough AS STRING) AS borough,
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,

        
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE time_of_submission IS NOT NULL
)

SELECT * FROM cleaned