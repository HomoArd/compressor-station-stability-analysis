select current_database();
select count(*) as count_of_station
from stations;
select count(*) as count_of_measurements
from measurements;
select count(*) as count_of_events
from events;
select * from stations;
select * from measurements;
select * from events;
select distinct mode from measurements;
select distinct event_type from events;
select distinct region from stations; 
select count(*)
from stations
where station_id is null;
select count(*) 
from events
where event_time is null;
select count(*)
from measurements
where (pressure is null) or
      (flow is null) or
      (temperature is null) or
      (vibration is null);
select * 
from measurements m
left join stations s
	on m.station_id=s.station_id
where s.station_id is null;
select *
from events e
left join stations s
	on e.station_id=s.station_id
where s.station_id is null;

select s.station_name,count(*) 
from stations s
join measurements m
	on s.station_id=m.station_id
group by s.station_name;




