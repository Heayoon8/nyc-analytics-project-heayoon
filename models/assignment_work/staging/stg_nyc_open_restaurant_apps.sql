SELECT
   LENGTH(CAST(incident_zip AS STRING)) AS zip_length,
   incident_zip,
   COUNT(*) AS count
 FROM `MY-PROJECT-ID.nyc_311_raw_data.source_dot_service_requests_history`
 WHERE incident_zip IS NOT NULL
   AND LENGTH(CAST(incident_zip AS STRING)) != 5
 GROUP BY zip_length, incident_zip
 ORDER BY count DESC