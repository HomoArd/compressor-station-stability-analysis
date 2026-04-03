select current_database();

with bas_df as
(select s.station_name,
		s.region,
		m.mode,
		AVG(m.pressure)  as avg_pressure,
		AVG(m.vibration) as avg_vibration
from measurements m
join stations s
	on m.station_id=s.station_id 
group by s.station_name,s.region,m.mode),
second_df as
(select 		avg(avg_pressure) as global_avg_pressure,
		avg(avg_vibration) as global_avg_vibration
from bas_df)
select b.station_name, b.region,b.mode,b.avg_pressure, s.global_avg_pressure
from bas_df b
cross join second_df s
where b.avg_pressure>s.global_avg_pressure 
order by b.avg_pressure desc;

with bas_df as
(select s.station_name,
		s.region,
		m.mode,
		AVG(m.vibration) as avg_vibration
from measurements m
join stations s
	on m.station_id=s.station_id 
group by s.station_name,s.region,m.mode),
second_df as
(select 		
		avg(avg_vibration) as global_avg_vibration
from bas_df)
select b.station_name, b.region,b.mode,b.avg_vibration, s.global_avg_vibration
from bas_df b
cross join second_df s
where b.avg_vibration>s.global_avg_vibration 
order by b.avg_vibration desc;


with bas_df as
(select s.station_name,
		s.region,
		m.mode,
		AVG(m.pressure)  as avg_pressure,
		AVG(m.vibration) as avg_vibration,
		AVG(m.temperature) as avg_temperature,
		AVG(m.flow) as avg_flow
from measurements m
join stations s
	on m.station_id=s.station_id 
group by s.station_name,s.region,m.mode),
second_df as
(select 		AVG(avg_pressure) as global_avg_pressure,
		AVG(avg_vibration) as global_avg_vibration,
		AVG(avg_temperature) AS global_avg_temperature,
		AVG(avg_flow) AS global_avg_flow
from bas_df),
flag_df as(
select b.station_name,
	   b.region,
	   b.mode,
	   b.avg_pressure, 
	   s.global_avg_pressure,
	   case 
	   	when b.avg_pressure>s.global_avg_pressure then 'high'
	   	else 'normal' 
	   end as pressure_flag,
	   b.avg_vibration, 
	   s.global_avg_vibration,
	   case 
	   	when b.avg_vibration>s.global_avg_vibration then 'high'
	   	else 'normal' 
	   end as vibration_flag,
	   s.global_avg_temperature,
	   b.avg_temperature,
	    case 
	   	when b.avg_temperature>s.global_avg_temperature then 'high'
	   	else 'normal' 
	   end as temperature_flag,
	   s.global_avg_flow,
	   b.avg_flow,
	    case 
	   	when b.avg_flow>s.global_avg_flow then 'high'
	   	else 'normal' 
	   end as flow_flag,
	   case 
	   	when b.avg_vibration>s.global_avg_vibration then 1
	   	else 0
	   end as vibration_score,
	    case 
	   	when b.avg_temperature>s.global_avg_temperature then 1
	   	else 0
	   end as temperature_score,
	    case 
	   	when b.avg_flow>s.global_avg_flow then 1
	   	else 0
	   end as flow_score,
	   case 
	   	when b.avg_pressure>s.global_avg_pressure then 1
	   	else 0
	   end as pressure_score
from bas_df b
cross join second_df s)
select station_name,
	   region,
	   mode,
	   avg_pressure, 
	   global_avg_pressure,
 	   global_avg_temperature,
	   avg_temperature,
	   avg_vibration, 
	   global_avg_vibration,
	   avg_flow, 
	   global_avg_flow,
	   pressure_flag,
	   vibration_flag,
	   temperature_flag,
	   flow_flag,
	   pressure_score + vibration_score + temperature_score + flow_score as risk_score,
	   case
  		  when pressure_score + vibration_score + temperature_score + flow_score  >= 3 then 'high risk'
   		  when pressure_score + vibration_score + temperature_score + flow_score  = 2 then 'medium risk'
  		  else 'low risk'
	   end as risk_level
from flag_df
order by risk_score desc;
	   