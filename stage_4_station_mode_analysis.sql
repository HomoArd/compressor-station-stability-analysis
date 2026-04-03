select current_database();

select s.station_name,
	   s.region,
	   m.mode,
	   AVG(m.pressure) as avg_pressure,
	   AVG(m.flow) as avg_flow,
	   AVG(m.temperature) as avg_temperature,
	   AVG(m.vibration) as avg_vibration,
	   COUNT(*) as measurement_count
from measurements m
join stations s
	on m.station_id=s.station_id
group by s.station_name,s.region,m.mode
order by avg_pressure desc ;

select s.station_name,
	   s.region,
	   m.mode,
	   AVG(m.pressure) as avg_pressure,
	   AVG(m.flow) as avg_flow,
	   AVG(m.temperature) as avg_temperature,
	   AVG(m.vibration) as avg_vibration,
	   COUNT(*) as measurement_count,
	   MAX(m.vibration) as max_vibration,
	   MAX(m.pressure) as max_pressure,
	   MAX(m.temperature) as max_temperataure,
	   MAX(m.flow) as max_flow
from measurements m
join stations s
	on m.station_id=s.station_id
group by s.station_name,s.region,m.mode
order by avg_pressure ;

with press_avg as 
	(select s.station_name,m.mode,AVG(m.pressure) as avg_pressure
	from measurements m
	join stations s
		on m.station_id=s.station_id
	group by s.station_name, m.mode)
select station_name,mode,avg_pressure
from press_avg
where avg_pressure=(select max(avg_pressure)
			from press_avg);

with vibro_avg as 
	(select s.station_name,m.mode,AVG(m.vibration) as avg_vibration
	from measurements m
	join stations s
		on m.station_id=s.station_id
	group by s.station_name, m.mode)
select station_name,mode,avg_vibration
from vibro_avg
where avg_vibration=(select max(avg_vibration)
			from vibro_avg);

