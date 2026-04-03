CREATE TABLE stations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    station_type VARCHAR(50),
    commissioning_year INT,
    capacity_class VARCHAR(50)
);
SELECT * FROM stations;
CREATE TABLE measurements (
    measurement_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL,
    measurement_time TIMESTAMP NOT NULL,
    mode VARCHAR(30) NOT NULL,
    pressure NUMERIC(8,2),
    flow NUMERIC(8,2),
    temperature NUMERIC(8,2),
    vibration NUMERIC(8,2),
    FOREIGN KEY (station_id) REFERENCES stations(station_id)
);
SELECT * FROM measurements;
CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    station_id INT NOT NULL,
    event_time TIMESTAMP NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    severity INT,
    duration_minutes INT,
    comment TEXT,
    FOREIGN KEY (station_id) REFERENCES stations(station_id)
);
SELECT * FROM events;
