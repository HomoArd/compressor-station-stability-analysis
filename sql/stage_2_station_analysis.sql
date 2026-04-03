select current_database();
SELECT s.station_name,          
       s.region,                             
       AVG(m.pressure) AS avg_pressure,      
       AVG(m.flow) AS avg_flow,              
       AVG(m.temperature) AS avg_temperature,
       AVG(m.vibration) AS avg_vibration,    
       MAX(m.pressure) AS max_pressure,      
       MAX(m.flow) AS max_flow,              
       MAX(m.temperature) AS max_temperature,
       MAX(m.vibration) AS max_vibration,    
       COUNT(*) AS measurement_count         
FROM stations s                              
JOIN measurements m                          
    ON s.station_id = m.station_id           
GROUP BY s.station_name, s.region            
ORDER BY avg_pressure DESC;  

with station_avg_pressure as
(SELECT s.station_name,          
       s.region,                             
       AVG(m.pressure) AS avg_pressure
 from stations s                              
 join measurements m                          
    on s.station_id = m.station_id           
GROUP BY s.station_name, s.region)
select station_name, region, avg_pressure
from station_avg_pressure
where avg_pressure=
	(select max(avg_pressure)
	from station_avg_pressure);

with station_avg_vibration as
(SELECT s.station_name,          
       s.region,                             
       AVG(m.vibration) AS avg_vibration
 from stations s                              
 join measurements m                          
    on s.station_id = m.station_id           
GROUP BY s.station_name, s.region)
select station_name, region, avg_vibration
from station_avg_vibration
where avg_vibration=
	(select max(avg_vibration)
	from station_avg_vibration);
