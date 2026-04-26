copy stations(station_id, station_name, region, station_type, launch_year)
from 'c:/users/1/desktop/compressor-station-monitoring/data/raw/stations.csv'
delimiter ','
csv header;

copy measurements(measurement_id, station_id, measurement_date, mode, pressure, flow, temperature, vibration)
from 'c:/users/1/desktop/compressor-station-monitoring/data/raw/measurements.csv'
delimiter ','
csv header;

copy events(event_id, station_id, event_date, event_type, severity, duration_hours)
from 'c:/users/1/desktop/compressor-station-monitoring/data/raw/events.csv'
delimiter ','
csv header;