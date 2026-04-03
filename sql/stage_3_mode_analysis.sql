select current_database();

select mode,
	   AVG(pressure) as avg_pressure,
	   AVG(flow) as avg_flow,
	   AVG(temperature) as avg_temperature,
	   AVG(vibration) as avg_vibration,
	   COUNT(*) as measurement_count
from measurements
group by mode
order by avg_pressure desc;

select mode,
	   AVG(pressure) as avg_pressure,
	   AVG(flow) as avg_flow,
	   AVG(temperature) as avg_temperature,
	   AVG(vibration) as avg_vibration,
	   COUNT(*) as measurement_count,
	   MAX(pressure) as max_pressure,
	   MAX(flow) as max_flow,
	   MAX(temperature) as max_temperature,
	   MAX(vibration) as max_vibration
from measurements
group by mode
order by avg_pressure desc;

with press_avg as
(select mode, AVG(pressure) as avg_pressure
from measurements
group by mode)
select mode,avg_pressure
from press_avg
where avg_pressure=
	(select MAX(avg_pressure)
	from press_avg);

with vibro_avg as
(select mode, AVG(vibration) as avg_vibration
from measurements
group by mode)
select mode,avg_vibration
from vibro_avg
where avg_vibration=
	(select MAX(avg_vibration)
	from vibro_avg);
