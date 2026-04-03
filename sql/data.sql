select current_database();
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
INSERT INTO stations (station_name, region, station_type, commissioning_year, capacity_class)
VALUES
('North Station', 'North', 'Compressor', 2012, 'High'),
('Central Station', 'Central', 'Compressor', 2015, 'Medium'),
('South Station', 'South', 'Compressor', 2010, 'High'),
('West Station', 'West', 'Compressor', 2018, 'Medium');
INSERT INTO measurements (station_id, measurement_time, mode, pressure, flow, temperature, vibration)
VALUES
(1, '2025-01-01 08:00:00', 'normal', 54.2, 120.5, 68.1, 2.1),
(1, '2025-01-01 12:00:00', 'stress', 58.4, 127.0, 72.3, 2.9),
(1, '2025-01-02 08:00:00', 'normal', 55.1, 121.4, 69.0, 2.2),
(2, '2025-01-01 08:00:00', 'normal', 52.8, 118.0, 67.0, 1.8),
(2, '2025-01-01 12:00:00', 'repair', 50.5, 110.2, 65.4, 1.6),
(2, '2025-01-02 08:00:00', 'normal', 53.4, 119.5, 67.8, 1.9),
(3, '2025-01-01 08:00:00', 'stress', 60.2, 130.1, 74.5, 3.2),
(3, '2025-01-01 12:00:00', 'stress', 61.0, 131.8, 75.0, 3.4),
(3, '2025-01-02 08:00:00', 'normal', 57.3, 125.0, 71.6, 2.7),
(4, '2025-01-01 08:00:00', 'normal', 51.6, 116.8, 66.2, 1.7),
(4, '2025-01-01 12:00:00', 'normal', 52.0, 117.5, 66.8, 1.8),
(4, '2025-01-02 08:00:00', 'repair', 49.8, 109.0, 64.9, 1.5);
INSERT INTO events (station_id, event_time, event_type, severity, duration_minutes, comment)
VALUES
(1, '2025-01-02 09:30:00', 'alarm', 3, 15, 'Pressure exceeded expected range'),
(2, '2025-01-03 14:00:00', 'maintenance', 1, 60, 'Scheduled inspection'),
(3, '2025-01-02 18:20:00', 'repair', 4, 120, 'Vibration issue detected'),
(3, '2025-01-03 07:10:00', 'alarm', 4, 20, 'High temperature and vibration'),
(4, '2025-01-03 11:00:00', 'inspection', 1, 30, 'Routine inspection');
