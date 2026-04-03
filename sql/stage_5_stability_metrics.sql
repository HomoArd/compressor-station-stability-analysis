select current_database();



with bas_df as(select s.station_name,
	   s.region,
	   m.mode,
	   avg(m.pressure) as avg_pressure,
	   avg(m.vibration) as avg_vibration,
	   min(m.pressure) as min_pressure,
	   max(m.pressure) as max_pressure,
	   min(m.vibration) as min_vibration,
	   max(m.vibration) as max_vibration
from measurements m
join stations s
	on m.station_id=s.station_id
group by s.station_name,s.region,m.mode)
select station_name,
	   region,
	   mode,
	   avg_pressure,
	   min_pressure,
	   max_pressure,
	   (max_pressure-min_pressure) as pressure_range,
	   avg_vibration,
	   min_vibration,
	   max_vibration,
	   (max_vibration-min_vibration) as vibration_range
from bas_df;

with bas_df as(select s.station_name,
	   s.region,
	   m.mode,
	   avg(m.pressure) as avg_pressure,
	   avg(m.vibration) as avg_vibration,
	   min(m.pressure) as min_pressure,
	   max(m.pressure) as max_pressure,
	   min(m.vibration) as min_vibration,
	   max(m.vibration) as max_vibration,
	   min(m.temperature) as min_temperature,
	   max(m.temperature) as max_temperature,
	   min(m.flow) as min_flow,
	   max(m.flow) as max_flow,
	   avg(m.temperature) as avg_temperature,
	   avg(m.flow) as avg_flow,	
	   STDDEV(m.pressure) as pressure_std,
	   STDDEV(m.vibration) as vibration_std,
	   STDDEV(m.flow) as flow_std,
	   STDDEV(m.temperature) as temperature_std
from measurements m
join stations s
	on m.station_id=s.station_id
group by s.station_name,s.region,m.mode)
select station_name,
	   region,
	   mode,
	   avg_pressure,
	   min_pressure,
	   max_pressure,
	   (max_pressure-min_pressure) as pressure_range,
	   pressure_std,
	   avg_vibration,
	   min_vibration,
	   max_vibration,
	   (max_vibration-min_vibration) as vibration_range,
	   vibration_std,
	   avg_temperature,
	   min_temperature,
	   max_temperature,
	   (max_temperature-min_temperature) as temperature_range,
	   temperature_std, 
	   avg_flow,
	    min_flow,
	   max_flow,
	   (max_flow-min_flow) as flow_range,
	   flow_std
from bas_df;


with first_df as 
(select s.station_name,
	   m.mode,
	   s.region,
	   min(m.pressure) as min_pressure,
	   max(m.pressure) as max_pressure
from measurements m
join stations s
	on m.station_id=s.station_id
group by s.station_name,m.mode, s.region)
select station_name,mode,region,min_pressure,max_pressure
from first_df
where (max_pressure-min_pressure)=
		(select max(max_pressure-min_pressure)
		from first_df);

with first_df as 
(select s.station_name,
	   m.mode,
	   s.region,
	   min(m.vibration) as min_vibration,
	   max(m.vibration) as max_vibration
from measurements m
join stations s
	on m.station_id=s.station_id
group by s.station_name,m.mode, s.region)
select station_name,mode,region,min_vibration,max_vibration
from first_df
where (max_vibration-min_vibration)=
		(select max(max_vibration-min_vibration)
		from first_df);
