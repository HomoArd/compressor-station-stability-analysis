select current_database();

select s.station_name,
	   s.region,
	   e.event_type,
	   count(*) as event_count,
	   avg(e.severity) as avg_severity,
	   sum(e.duration_minutes) as total_duration
from events e
join stations s
	on e.station_id =s.station_id
group by s.station_name,s.region,e.event_type;


select s.station_name,
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
group by s.station_name,s.region;