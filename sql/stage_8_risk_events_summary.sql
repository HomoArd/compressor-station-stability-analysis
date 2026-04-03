
select current_database();
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
cross join second_df s),
risk_df as(
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
from flag_df),
event_df as (select s.station_name,
	   s.region,
	   count(*) as event_count,
	   avg(e.severity) as avg_severity,
	   sum(e.duration_minutes) as total_duration,
	   sum(case
	   	when e.event_type='alarm' then +1
	   	else 0
	   end) as alarm_count,
	   sum(case
	   	when e.event_type='repair' then +1
	   	else 0
	   end) as repair_count
from events e
join stations s
	on e.station_id =s.station_id
group by s.station_name,s.region)
select r.station_name,
	   r.region,
	   r.mode,
	   r.risk_score,
	   r.risk_level,
	   e.event_count,
	   e.alarm_count,
	   e.avg_severity,
	   e.total_duration,
	   COALESCE(e.event_count, 0),
	   COALESCE(e.alarm_count, 0),
	   COALESCE(e.repair_count, 0),
       COALESCE(e.total_duration, 0)
from risk_df r
left join event_df e
	on r.station_name=e.station_name
	and r.region=e.region
order by r.risk_score desc, e.event_count desc;
