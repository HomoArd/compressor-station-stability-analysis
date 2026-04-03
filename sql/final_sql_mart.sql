

with base_metrics as( select
		s.station_name,
        s.region,
        m.mode,
        AVG(m.pressure) as avg_pressure,
        AVG(m.flow) as avg_flow,
        AVG(m.temperature) as avg_temperature,
        AVG(m.vibration) as avg_vibration,
        MIN(m.pressure) as min_pressure,
        MAX(m.pressure) as max_pressure,
        MIN(m.flow) as min_flow,
        MAX(m.flow) as max_flow,
        MIN(m.temperature) as min_temperature,
        MAX(m.temperature) as max_temperature,
        MIN(m.vibration) as  min_vibration,
        MAX(m.vibration) as max_vibration,
        STDDEV(m.pressure) as pressure_std,
        STDDEV(m.flow) as flow_std,
        STDDEV(m.temperature) as temperature_std,
        STDDEV(m.vibration) as vibration_std,
        COUNT(*) as measurement_count
    from measurements m
    join stations s
        on m.station_id = s.station_id
    group by s.station_name, s.region, m.mode
),
global_metrics as (
    select
        AVG(avg_pressure) as global_avg_pressure,
        AVG(avg_flow) as global_avg_flow,
        AVG(avg_temperature) as global_avg_temperature,
        AVG(avg_vibration) as global_avg_vibration
    from base_metrics
),
risk_flags as (
    select
        b.*,
        g.global_avg_pressure,
        g.global_avg_flow,
        g.global_avg_temperature,
        g.global_avg_vibration,
        case when b.avg_pressure > g.global_avg_pressure then 'high' else 'normal' end as pressure_flag,
        case when b.avg_flow > g.global_avg_flow then 'high' else 'normal' end as flow_flag,
        case when b.avg_temperature > g.global_avg_temperature then 'high' else 'normal' end as temperature_flag,
        case when b.avg_vibration > g.global_avg_vibration then 'high' else 'normal' end as vibration_flag,
        case when b.avg_pressure > g.global_avg_pressure then 1 else 0 end as pressure_score,
        case when b.avg_flow > g.global_avg_flow then 1 else 0 end as flow_score,
        case when b.avg_temperature > g.global_avg_temperature then 1 else 0 end as temperature_score,
        case when b.avg_vibration > g.global_avg_vibration then 1 else 0 end as vibration_score
    from base_metrics b
    cross join global_metrics g
),
risk_scored as (
    select
        *,
        (max_pressure - min_pressure)as pressure_range,
        (max_flow - min_flow) as flow_range,
        (max_temperature - min_temperature) as temperature_range,
        (max_vibration - min_vibration) as vibration_range,
        pressure_score + flow_score + temperature_score + vibration_score as risk_score,
        case
            when pressure_score + flow_score + temperature_score + vibration_score >= 3 then 'high risk'
            when pressure_score + flow_score + temperature_score + vibration_score = 2 then 'medium risk'
            else'low risk'
        end as risk_level
    from risk_flags
),
event_summary as (
    select
        s.station_name,
        s.region,
        COUNT(*) as event_count,
        AVG(e.severity) as avg_severity,
        MAX(e.severity) as max_severity,
        SUM(e.duration_minutes) as total_duration,
        SUM(case when e.event_type = 'alarm' then 1 else 0 end) as alarm_count,
        SUM(case when e.event_type = 'repair' then 1 else 0 end) as repair_count,
        SUM(case when e.event_type = 'inspection' then 1 else 0 end) as inspection_count,
        SUM(case when e.event_type = 'maintenance' then 1 else 0 end) as maintenance_count
    from events e
    join stations s
        on e.station_id = s.station_id
    group by s.station_name, s.region
),
final_mart as (
    select
        r.station_name,
        r.region,
        r.mode,
        r.measurement_count,
        r.avg_pressure,
        r.avg_flow,
        r.avg_temperature,
        r.avg_vibration,
        r.min_pressure,
        r.max_pressure,
        r.pressure_range,
        r.pressure_std,
        r.min_flow,
        r.max_flow,
        r.flow_range,
        r.flow_std,
        r.min_temperature,
        r.max_temperature,
        r.temperature_range,
        r.temperature_std,
        r.min_vibration,
        r.max_vibration,
        r.vibration_range,
        r.vibration_std,
        r.global_avg_pressure,
        r.global_avg_flow,
        r.global_avg_temperature,
        r.global_avg_vibration,
        r.pressure_flag,
        r.flow_flag,
        r.temperature_flag,
        r.vibration_flag,
        r.risk_score,
        r.risk_level,
        COALESCE(e.event_count, 0) as event_count,
        COALESCE(e.alarm_count, 0) as alarm_count,
        COALESCE(e.repair_count, 0) as repair_count,
        COALESCE(e.inspection_count, 0) as inspection_count,
        COALESCE(e.maintenance_count, 0) as maintenance_count,
        COALESCE(e.total_duration, 0) as total_duration,
        COALESCE(e.avg_severity, 0) as avg_severity,
        COALESCE(e.max_severity, 0) as max_severity,
        COALESCE(
            COALESCE(e.alarm_count, 0)::numeric
            / NULLIF(COALESCE(e.event_count, 0), 0),
            0
        ) as alarm_share,
        COALESCE(
            COALESCE(e.repair_count, 0)::numeric
            / NULLIF(COALESCE(e.event_count, 0), 0),
            0
        ) as repair_share
    from risk_scored r
    left join event_summary e
        on r.station_name = e.station_name
       and r.region = e.region
)
select
    *,
    RANK() over (order by risk_score desc) as risk_rank,
    ROW_NUMBER() over (
        partition by region
        order by risk_score desc, event_count desc
    ) as risk_rank_in_region,
    DENSE_RANK() over (order by avg_vibration desc) as vibration_rank,
    RANK() over (order by avg_severity desc) as severity_rank
from final_mart
order by risk_score desc, event_count desc, avg_vibration desc;
