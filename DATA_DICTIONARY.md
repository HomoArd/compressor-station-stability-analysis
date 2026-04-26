# Data dictionary

## stations
- station_id: unique station identifier
- station_name: station name
- region: north / south / east
- station_type: mainline / booster / distribution
- launch_year: year of station launch

## measurements
- measurement_id: unique measurement identifier
- station_id: station foreign key
- measurement_date: observation date
- mode: normal / peak / stress / repair
- pressure: operating pressure
- flow: operating flow
- temperature: operating temperature
- vibration: vibration indicator

## events
- event_id: unique event identifier
- station_id: station foreign key
- event_date: event date
- event_type: maintenance / pressure_spike / vibration_alert / sensor_fault / shutdown
- severity: low / medium / high / critical
- duration_hours: event duration in hours