-- Update the file paths if your local project folder is different.
-- Example for psql:
-- \copy stations FROM 'data/raw/stations.csv' CSV HEADER;
-- \copy measurements FROM 'data/raw/measurements.csv' CSV HEADER;
-- \copy events FROM 'data/raw/events.csv' CSV HEADER;

-- Example SQL checks after loading:
SELECT COUNT(*) AS stations_cnt FROM stations;
SELECT COUNT(*) AS measurements_cnt FROM measurements;
SELECT COUNT(*) AS events_cnt FROM events;