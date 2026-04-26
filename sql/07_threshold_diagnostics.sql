select current_database();

with monthly_layer as (
    -- Monthly aggregation from raw measurements
    select
        date_trunc('month', measurement_date)::date as month_start,
        station_id,
        mode,
        avg(pressure) as avg_pressure,
        avg(flow) as avg_flow,
        avg(temperature) as avg_temperature,
        avg(vibration) as avg_vibration,
        count(*) as obs_count
    from measurements
    group by 1, 2, 3
),
window_features as (
    -- Previous values, rolling averages, previous-only baseline
    select
        *,
        lag(avg_pressure) over w as prev_avg_pressure,
        lag(avg_flow) over w as prev_avg_flow,
        lag(avg_vibration) over w as prev_avg_vibration,
        lag(avg_temperature) over w as prev_avg_temperature,
        avg(avg_pressure) over r as rolling_avg_pressure_3,
        avg(avg_flow) over r as rolling_avg_flow_3,
        avg(avg_vibration) over r as rolling_avg_vibration_3,
        avg(avg_temperature) over r as rolling_avg_temperature_3,
        avg(avg_pressure) over b as baseline_avg_pressure_3_prev,
        avg(avg_flow) over b as baseline_avg_flow_3_prev,
        avg(avg_vibration) over b as baseline_avg_vibration_3_prev,
        avg(avg_temperature) over b as baseline_avg_temperature_3_prev
    from monthly_layer
    window
        w as (
            partition by station_id, mode
            order by month_start
        ),
        r as (
            partition by station_id, mode
            order by month_start
            rows between 2 preceding and current row
        ),
        b as (
            partition by station_id, mode
            order by month_start
            rows between 3 preceding and 1 preceding
        )
),
change_features as (
    -- Absolute / percentage changes and deviations from rolling / baseline
    select
        *,
        avg_pressure - prev_avg_pressure as pressure_abs_change,
        (avg_pressure - prev_avg_pressure) / nullif(prev_avg_pressure, 0) as pressure_pct_change,
        avg_flow - prev_avg_flow as flow_abs_change,
        (avg_flow - prev_avg_flow) / nullif(prev_avg_flow, 0) as flow_pct_change,
        avg_temperature - prev_avg_temperature as temperature_abs_change,
        (avg_temperature - prev_avg_temperature) / nullif(prev_avg_temperature, 0) as temperature_pct_change,
        avg_vibration - prev_avg_vibration as vibration_abs_change,
        (avg_vibration - prev_avg_vibration) / nullif(prev_avg_vibration, 0) as vibration_pct_change,
        avg_pressure - rolling_avg_pressure_3 as pressure_vs_rolling_diff,
        avg_flow - rolling_avg_flow_3 as flow_vs_rolling_diff,
        (avg_pressure - rolling_avg_pressure_3) / nullif(rolling_avg_pressure_3, 0) as pressure_vs_rolling_pct,
        (avg_flow - rolling_avg_flow_3) / nullif(rolling_avg_flow_3, 0) as flow_vs_rolling_pct,
        avg_pressure - baseline_avg_pressure_3_prev as pressure_vs_baseline_diff,
        avg_flow - baseline_avg_flow_3_prev as flow_vs_baseline_diff,
        (avg_pressure - baseline_avg_pressure_3_prev) / nullif(baseline_avg_pressure_3_prev, 0) as pressure_vs_baseline_pct,
        (avg_flow - baseline_avg_flow_3_prev) / nullif(baseline_avg_flow_3_prev, 0) as flow_vs_baseline_pct
    from window_features
),
flags as (
    -- Monitoring flags based on threshold logic
    select
        *,
        case
            when abs(pressure_pct_change) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_prev,
        case
            when abs(flow_pct_change) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_prev,
        case
            when abs(pressure_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_rolling,
        case
            when abs(flow_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_rolling,
        case
            when abs(pressure_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_pressure_anomaly_3_prev,
        case
            when abs(flow_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_flow_anomaly_3_prev
    from change_features
),
signal_layer as (
    -- Total number of triggered signals
    select
        *,
        is_large_pressure_shift_prev
        + is_large_flow_shift_prev
        + is_large_pressure_shift_rolling
        + is_large_flow_shift_rolling
        + is_pressure_anomaly_3_prev
        + is_flow_anomaly_3_prev as signal_count
    from flags
),
monitoring as (
    -- Final monitoring status
    select
        *,
        case
            when signal_count = 0 then 'stable'
            when signal_count = 1 then 'warning'
            when signal_count in (2, 3) then 'anomaly'
            else 'critical'
        end as monitoring_status
    from signal_layer
),
event_monthly as (
	-- Monthly event aggregation at station-month level
    select
        date_trunc('month', event_date)::date as month_start,
        station_id,
        count(*) as event_count,
        sum(case when severity = 'critical' then 1 else 0 end) as critical_event_count,
        avg(duration_hours) as avg_event_duration
    from events
    group by 1,2
),
monitoring_with_events as(
	-- Monitoring mart enriched with event metrics
	select
        m.*,
        coalesce(e.event_count, 0) as event_count,
        coalesce(e.critical_event_count, 0) as critical_event_count,
        e.avg_event_duration
    from monitoring m
    left join event_monthly e
        on m.month_start = e.month_start
       and m.station_id = e.station_id),
event_flags as(
	-- Final event-aware monitoring flags
	select *,
			case
				when event_count > 0 then 1
				else 0
			end as has_events,
			case 
				when critical_event_count > 0 then 1
				else 0
			end as has_critical_events,
			case
				when signal_count > 0 and event_count > 0 then 1
				else 0
		    end as problematic_with_events,
		    case
		    	when monitoring_status in ('anomaly', 'critical') and  event_count > 0 then 1
		    	else 0
		    end as anomaly_or_critical_with_events	    
	 from monitoring_with_events)
select
    monitoring_status,
    count(*) as row_count
from event_flags
group by monitoring_status
order by row_count desc;

with monthly_layer as (
    -- Monthly aggregation from raw measurements
    select
        date_trunc('month', measurement_date)::date as month_start,
        station_id,
        mode,
        avg(pressure) as avg_pressure,
        avg(flow) as avg_flow,
        avg(temperature) as avg_temperature,
        avg(vibration) as avg_vibration,
        count(*) as obs_count
    from measurements
    group by 1, 2, 3
),
window_features as (
    -- Previous values, rolling averages, previous-only baseline
    select
        *,
        lag(avg_pressure) over w as prev_avg_pressure,
        lag(avg_flow) over w as prev_avg_flow,
        lag(avg_vibration) over w as prev_avg_vibration,
        lag(avg_temperature) over w as prev_avg_temperature,
        avg(avg_pressure) over r as rolling_avg_pressure_3,
        avg(avg_flow) over r as rolling_avg_flow_3,
        avg(avg_vibration) over r as rolling_avg_vibration_3,
        avg(avg_temperature) over r as rolling_avg_temperature_3,
        avg(avg_pressure) over b as baseline_avg_pressure_3_prev,
        avg(avg_flow) over b as baseline_avg_flow_3_prev,
        avg(avg_vibration) over b as baseline_avg_vibration_3_prev,
        avg(avg_temperature) over b as baseline_avg_temperature_3_prev
    from monthly_layer
    window
        w as (
            partition by station_id, mode
            order by month_start
        ),
        r as (
            partition by station_id, mode
            order by month_start
            rows between 2 preceding and current row
        ),
        b as (
            partition by station_id, mode
            order by month_start
            rows between 3 preceding and 1 preceding
        )
),
change_features as (
    -- Absolute / percentage changes and deviations from rolling / baseline
    select
        *,
        avg_pressure - prev_avg_pressure as pressure_abs_change,
        (avg_pressure - prev_avg_pressure) / nullif(prev_avg_pressure, 0) as pressure_pct_change,
        avg_flow - prev_avg_flow as flow_abs_change,
        (avg_flow - prev_avg_flow) / nullif(prev_avg_flow, 0) as flow_pct_change,
        avg_temperature - prev_avg_temperature as temperature_abs_change,
        (avg_temperature - prev_avg_temperature) / nullif(prev_avg_temperature, 0) as temperature_pct_change,
        avg_vibration - prev_avg_vibration as vibration_abs_change,
        (avg_vibration - prev_avg_vibration) / nullif(prev_avg_vibration, 0) as vibration_pct_change,
        avg_pressure - rolling_avg_pressure_3 as pressure_vs_rolling_diff,
        avg_flow - rolling_avg_flow_3 as flow_vs_rolling_diff,
        (avg_pressure - rolling_avg_pressure_3) / nullif(rolling_avg_pressure_3, 0) as pressure_vs_rolling_pct,
        (avg_flow - rolling_avg_flow_3) / nullif(rolling_avg_flow_3, 0) as flow_vs_rolling_pct,
        avg_pressure - baseline_avg_pressure_3_prev as pressure_vs_baseline_diff,
        avg_flow - baseline_avg_flow_3_prev as flow_vs_baseline_diff,
        (avg_pressure - baseline_avg_pressure_3_prev) / nullif(baseline_avg_pressure_3_prev, 0) as pressure_vs_baseline_pct,
        (avg_flow - baseline_avg_flow_3_prev) / nullif(baseline_avg_flow_3_prev, 0) as flow_vs_baseline_pct
    from window_features
),
flags as (
    -- Monitoring flags based on threshold logic
    select
        *,
        case
            when abs(pressure_pct_change) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_prev,
        case
            when abs(flow_pct_change) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_prev,
        case
            when abs(pressure_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_rolling,
        case
            when abs(flow_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_rolling,
        case
            when abs(pressure_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_pressure_anomaly_3_prev,
        case
            when abs(flow_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_flow_anomaly_3_prev
    from change_features
),
signal_layer as (
    -- Total number of triggered signals
    select
        *,
        is_large_pressure_shift_prev
        + is_large_flow_shift_prev
        + is_large_pressure_shift_rolling
        + is_large_flow_shift_rolling
        + is_pressure_anomaly_3_prev
        + is_flow_anomaly_3_prev as signal_count
    from flags
),
monitoring as (
    -- Final monitoring status
    select
        *,
        case
            when signal_count = 0 then 'stable'
            when signal_count = 1 then 'warning'
            when signal_count in (2, 3) then 'anomaly'
            else 'critical'
        end as monitoring_status
    from signal_layer
),
event_monthly as (
	-- Monthly event aggregation at station-month level
    select
        date_trunc('month', event_date)::date as month_start,
        station_id,
        count(*) as event_count,
        sum(case when severity = 'critical' then 1 else 0 end) as critical_event_count,
        avg(duration_hours) as avg_event_duration
    from events
    group by 1,2
),
monitoring_with_events as(
	-- Monitoring mart enriched with event metrics
	select
        m.*,
        coalesce(e.event_count, 0) as event_count,
        coalesce(e.critical_event_count, 0) as critical_event_count,
        e.avg_event_duration
    from monitoring m
    left join event_monthly e
        on m.month_start = e.month_start
       and m.station_id = e.station_id),
event_flags as(
	-- Final event-aware monitoring flags
	select *,
			case
				when event_count > 0 then 1
				else 0
			end as has_events,
			case 
				when critical_event_count > 0 then 1
				else 0
			end as has_critical_events,
			case
				when signal_count > 0 and event_count > 0 then 1
				else 0
		    end as problematic_with_events,
		    case
		    	when monitoring_status in ('anomaly', 'critical') and  event_count > 0 then 1
		    	else 0
		    end as anomaly_or_critical_with_events	    
	 from monitoring_with_events)
select
    sum(is_large_pressure_shift_prev) as large_pressure_prev,
    sum(is_large_flow_shift_prev) as large_flow_prev,
    sum(is_large_pressure_shift_rolling) as large_pressure_rolling,
    sum(is_large_flow_shift_rolling) as large_flow_rolling,
    sum(is_pressure_anomaly_3_prev) as pressure_anomaly_prev,
    sum(is_flow_anomaly_3_prev) as flow_anomaly_prev
from event_flags;
with monthly_layer as (
    -- Monthly aggregation from raw measurements
    select
        date_trunc('month', measurement_date)::date as month_start,
        station_id,
        mode,
        avg(pressure) as avg_pressure,
        avg(flow) as avg_flow,
        avg(temperature) as avg_temperature,
        avg(vibration) as avg_vibration,
        count(*) as obs_count
    from measurements
    group by 1, 2, 3
),
window_features as (
    -- Previous values, rolling averages, previous-only baseline
    select
        *,
        lag(avg_pressure) over w as prev_avg_pressure,
        lag(avg_flow) over w as prev_avg_flow,
        lag(avg_vibration) over w as prev_avg_vibration,
        lag(avg_temperature) over w as prev_avg_temperature,
        avg(avg_pressure) over r as rolling_avg_pressure_3,
        avg(avg_flow) over r as rolling_avg_flow_3,
        avg(avg_vibration) over r as rolling_avg_vibration_3,
        avg(avg_temperature) over r as rolling_avg_temperature_3,
        avg(avg_pressure) over b as baseline_avg_pressure_3_prev,
        avg(avg_flow) over b as baseline_avg_flow_3_prev,
        avg(avg_vibration) over b as baseline_avg_vibration_3_prev,
        avg(avg_temperature) over b as baseline_avg_temperature_3_prev
    from monthly_layer
    window
        w as (
            partition by station_id, mode
            order by month_start
        ),
        r as (
            partition by station_id, mode
            order by month_start
            rows between 2 preceding and current row
        ),
        b as (
            partition by station_id, mode
            order by month_start
            rows between 3 preceding and 1 preceding
        )
),
change_features as (
    -- Absolute / percentage changes and deviations from rolling / baseline
    select
        *,
        avg_pressure - prev_avg_pressure as pressure_abs_change,
        (avg_pressure - prev_avg_pressure) / nullif(prev_avg_pressure, 0) as pressure_pct_change,
        avg_flow - prev_avg_flow as flow_abs_change,
        (avg_flow - prev_avg_flow) / nullif(prev_avg_flow, 0) as flow_pct_change,
        avg_temperature - prev_avg_temperature as temperature_abs_change,
        (avg_temperature - prev_avg_temperature) / nullif(prev_avg_temperature, 0) as temperature_pct_change,
        avg_vibration - prev_avg_vibration as vibration_abs_change,
        (avg_vibration - prev_avg_vibration) / nullif(prev_avg_vibration, 0) as vibration_pct_change,
        avg_pressure - rolling_avg_pressure_3 as pressure_vs_rolling_diff,
        avg_flow - rolling_avg_flow_3 as flow_vs_rolling_diff,
        (avg_pressure - rolling_avg_pressure_3) / nullif(rolling_avg_pressure_3, 0) as pressure_vs_rolling_pct,
        (avg_flow - rolling_avg_flow_3) / nullif(rolling_avg_flow_3, 0) as flow_vs_rolling_pct,
        avg_pressure - baseline_avg_pressure_3_prev as pressure_vs_baseline_diff,
        avg_flow - baseline_avg_flow_3_prev as flow_vs_baseline_diff,
        (avg_pressure - baseline_avg_pressure_3_prev) / nullif(baseline_avg_pressure_3_prev, 0) as pressure_vs_baseline_pct,
        (avg_flow - baseline_avg_flow_3_prev) / nullif(baseline_avg_flow_3_prev, 0) as flow_vs_baseline_pct
    from window_features
),
flags as (
    -- Monitoring flags based on threshold logic
    select
        *,
        case
            when abs(pressure_pct_change) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_prev,
        case
            when abs(flow_pct_change) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_prev,
        case
            when abs(pressure_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_rolling,
        case
            when abs(flow_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_rolling,
        case
            when abs(pressure_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_pressure_anomaly_3_prev,
        case
            when abs(flow_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_flow_anomaly_3_prev
    from change_features
),
signal_layer as (
    -- Total number of triggered signals
    select
        *,
        is_large_pressure_shift_prev
        + is_large_flow_shift_prev
        + is_large_pressure_shift_rolling
        + is_large_flow_shift_rolling
        + is_pressure_anomaly_3_prev
        + is_flow_anomaly_3_prev as signal_count
    from flags
),
monitoring as (
    -- Final monitoring status
    select
        *,
        case
            when signal_count = 0 then 'stable'
            when signal_count = 1 then 'warning'
            when signal_count in (2, 3) then 'anomaly'
            else 'critical'
        end as monitoring_status
    from signal_layer
),
event_monthly as (
	-- Monthly event aggregation at station-month level
    select
        date_trunc('month', event_date)::date as month_start,
        station_id,
        count(*) as event_count,
        sum(case when severity = 'critical' then 1 else 0 end) as critical_event_count,
        avg(duration_hours) as avg_event_duration
    from events
    group by 1,2
),
monitoring_with_events as(
	-- Monitoring mart enriched with event metrics
	select
        m.*,
        coalesce(e.event_count, 0) as event_count,
        coalesce(e.critical_event_count, 0) as critical_event_count,
        e.avg_event_duration
    from monitoring m
    left join event_monthly e
        on m.month_start = e.month_start
       and m.station_id = e.station_id),
event_flags as(
	-- Final event-aware monitoring flags
	select *,
			case
				when event_count > 0 then 1
				else 0
			end as has_events,
			case 
				when critical_event_count > 0 then 1
				else 0
			end as has_critical_events,
			case
				when signal_count > 0 and event_count > 0 then 1
				else 0
		    end as problematic_with_events,
		    case
		    	when monitoring_status in ('anomaly', 'critical') and  event_count > 0 then 1
		    	else 0
		    end as anomaly_or_critical_with_events	    
	 from monitoring_with_events)
select
    count(*) filter (where event_count > 0) as rows_with_events,
    count(*) filter (where signal_count > 0) as rows_with_signals,
    count(*) filter (where signal_count > 0 and event_count > 0) as rows_with_signals_and_events,
    count(*) filter (where monitoring_status in ('anomaly', 'critical')) as rows_with_bad_status,
    count(*) filter (where monitoring_status in ('anomaly', 'critical') and event_count > 0) as rows_with_bad_status_and_events
from event_flags;

with monthly_layer as (
    -- Monthly aggregation from raw measurements
    select
        date_trunc('month', measurement_date)::date as month_start,
        station_id,
        mode,
        avg(pressure) as avg_pressure,
        avg(flow) as avg_flow,
        avg(temperature) as avg_temperature,
        avg(vibration) as avg_vibration,
        count(*) as obs_count
    from measurements
    group by 1, 2, 3
),
window_features as (
    -- Previous values, rolling averages, previous-only baseline
    select
        *,
        lag(avg_pressure) over w as prev_avg_pressure,
        lag(avg_flow) over w as prev_avg_flow,
        lag(avg_vibration) over w as prev_avg_vibration,
        lag(avg_temperature) over w as prev_avg_temperature,
        avg(avg_pressure) over r as rolling_avg_pressure_3,
        avg(avg_flow) over r as rolling_avg_flow_3,
        avg(avg_vibration) over r as rolling_avg_vibration_3,
        avg(avg_temperature) over r as rolling_avg_temperature_3,
        avg(avg_pressure) over b as baseline_avg_pressure_3_prev,
        avg(avg_flow) over b as baseline_avg_flow_3_prev,
        avg(avg_vibration) over b as baseline_avg_vibration_3_prev,
        avg(avg_temperature) over b as baseline_avg_temperature_3_prev
    from monthly_layer
    window
        w as (
            partition by station_id, mode
            order by month_start
        ),
        r as (
            partition by station_id, mode
            order by month_start
            rows between 2 preceding and current row
        ),
        b as (
            partition by station_id, mode
            order by month_start
            rows between 3 preceding and 1 preceding
        )
),
change_features as (
    -- Absolute / percentage changes and deviations from rolling / baseline
    select
        *,
        avg_pressure - prev_avg_pressure as pressure_abs_change,
        (avg_pressure - prev_avg_pressure) / nullif(prev_avg_pressure, 0) as pressure_pct_change,
        avg_flow - prev_avg_flow as flow_abs_change,
        (avg_flow - prev_avg_flow) / nullif(prev_avg_flow, 0) as flow_pct_change,
        avg_temperature - prev_avg_temperature as temperature_abs_change,
        (avg_temperature - prev_avg_temperature) / nullif(prev_avg_temperature, 0) as temperature_pct_change,
        avg_vibration - prev_avg_vibration as vibration_abs_change,
        (avg_vibration - prev_avg_vibration) / nullif(prev_avg_vibration, 0) as vibration_pct_change,
        avg_pressure - rolling_avg_pressure_3 as pressure_vs_rolling_diff,
        avg_flow - rolling_avg_flow_3 as flow_vs_rolling_diff,
        (avg_pressure - rolling_avg_pressure_3) / nullif(rolling_avg_pressure_3, 0) as pressure_vs_rolling_pct,
        (avg_flow - rolling_avg_flow_3) / nullif(rolling_avg_flow_3, 0) as flow_vs_rolling_pct,
        avg_pressure - baseline_avg_pressure_3_prev as pressure_vs_baseline_diff,
        avg_flow - baseline_avg_flow_3_prev as flow_vs_baseline_diff,
        (avg_pressure - baseline_avg_pressure_3_prev) / nullif(baseline_avg_pressure_3_prev, 0) as pressure_vs_baseline_pct,
        (avg_flow - baseline_avg_flow_3_prev) / nullif(baseline_avg_flow_3_prev, 0) as flow_vs_baseline_pct
    from window_features
),
flags as (
    -- Monitoring flags based on threshold logic
    select
        *,
        case
            when abs(pressure_pct_change) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_prev,
        case
            when abs(flow_pct_change) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_prev,
        case
            when abs(pressure_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_rolling,
        case
            when abs(flow_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_rolling,
        case
            when abs(pressure_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_pressure_anomaly_3_prev,
        case
            when abs(flow_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_flow_anomaly_3_prev
    from change_features
),
signal_layer as (
    -- Total number of triggered signals
    select
        *,
        is_large_pressure_shift_prev
        + is_large_flow_shift_prev
        + is_large_pressure_shift_rolling
        + is_large_flow_shift_rolling
        + is_pressure_anomaly_3_prev
        + is_flow_anomaly_3_prev as signal_count
    from flags
),
monitoring as (
    -- Final monitoring status
    select
        *,
        case
            when signal_count = 0 then 'stable'
            when signal_count = 1 then 'warning'
            when signal_count in (2, 3) then 'anomaly'
            else 'critical'
        end as monitoring_status
    from signal_layer
),
event_monthly as (
	-- Monthly event aggregation at station-month level
    select
        date_trunc('month', event_date)::date as month_start,
        station_id,
        count(*) as event_count,
        sum(case when severity = 'critical' then 1 else 0 end) as critical_event_count,
        avg(duration_hours) as avg_event_duration
    from events
    group by 1,2
),
monitoring_with_events as(
	-- Monitoring mart enriched with event metrics
	select
        m.*,
        coalesce(e.event_count, 0) as event_count,
        coalesce(e.critical_event_count, 0) as critical_event_count,
        e.avg_event_duration
    from monitoring m
    left join event_monthly e
        on m.month_start = e.month_start
       and m.station_id = e.station_id),
event_flags as(
	-- Final event-aware monitoring flags
	select *,
			case
				when event_count > 0 then 1
				else 0
			end as has_events,
			case 
				when critical_event_count > 0 then 1
				else 0
			end as has_critical_events,
			case
				when signal_count > 0 and event_count > 0 then 1
				else 0
		    end as problematic_with_events,
		    case
		    	when monitoring_status in ('anomaly', 'critical') and  event_count > 0 then 1
		    	else 0
		    end as anomaly_or_critical_with_events	    
	 from monitoring_with_events)
select
    sum(is_large_pressure_shift_prev) as large_pressure_prev,
    sum(is_large_flow_shift_prev) as large_flow_prev,
    sum(is_large_pressure_shift_rolling) as large_pressure_rolling,
    sum(is_large_flow_shift_rolling) as large_flow_rolling,
    sum(is_pressure_anomaly_3_prev) as pressure_anomaly_prev,
    sum(is_flow_anomaly_3_prev) as flow_anomaly_prev
from event_flags;
with monthly_layer as (
    -- Monthly aggregation from raw measurements
    select
        date_trunc('month', measurement_date)::date as month_start,
        station_id,
        mode,
        avg(pressure) as avg_pressure,
        avg(flow) as avg_flow,
        avg(temperature) as avg_temperature,
        avg(vibration) as avg_vibration,
        count(*) as obs_count
    from measurements
    group by 1, 2, 3
),
window_features as (
    -- Previous values, rolling averages, previous-only baseline
    select
        *,
        lag(avg_pressure) over w as prev_avg_pressure,
        lag(avg_flow) over w as prev_avg_flow,
        lag(avg_vibration) over w as prev_avg_vibration,
        lag(avg_temperature) over w as prev_avg_temperature,
        avg(avg_pressure) over r as rolling_avg_pressure_3,
        avg(avg_flow) over r as rolling_avg_flow_3,
        avg(avg_vibration) over r as rolling_avg_vibration_3,
        avg(avg_temperature) over r as rolling_avg_temperature_3,
        avg(avg_pressure) over b as baseline_avg_pressure_3_prev,
        avg(avg_flow) over b as baseline_avg_flow_3_prev,
        avg(avg_vibration) over b as baseline_avg_vibration_3_prev,
        avg(avg_temperature) over b as baseline_avg_temperature_3_prev
    from monthly_layer
    window
        w as (
            partition by station_id, mode
            order by month_start
        ),
        r as (
            partition by station_id, mode
            order by month_start
            rows between 2 preceding and current row
        ),
        b as (
            partition by station_id, mode
            order by month_start
            rows between 3 preceding and 1 preceding
        )
),
change_features as (
    -- Absolute / percentage changes and deviations from rolling / baseline
    select
        *,
        avg_pressure - prev_avg_pressure as pressure_abs_change,
        (avg_pressure - prev_avg_pressure) / nullif(prev_avg_pressure, 0) as pressure_pct_change,
        avg_flow - prev_avg_flow as flow_abs_change,
        (avg_flow - prev_avg_flow) / nullif(prev_avg_flow, 0) as flow_pct_change,
        avg_temperature - prev_avg_temperature as temperature_abs_change,
        (avg_temperature - prev_avg_temperature) / nullif(prev_avg_temperature, 0) as temperature_pct_change,
        avg_vibration - prev_avg_vibration as vibration_abs_change,
        (avg_vibration - prev_avg_vibration) / nullif(prev_avg_vibration, 0) as vibration_pct_change,
        avg_pressure - rolling_avg_pressure_3 as pressure_vs_rolling_diff,
        avg_flow - rolling_avg_flow_3 as flow_vs_rolling_diff,
        (avg_pressure - rolling_avg_pressure_3) / nullif(rolling_avg_pressure_3, 0) as pressure_vs_rolling_pct,
        (avg_flow - rolling_avg_flow_3) / nullif(rolling_avg_flow_3, 0) as flow_vs_rolling_pct,
        avg_pressure - baseline_avg_pressure_3_prev as pressure_vs_baseline_diff,
        avg_flow - baseline_avg_flow_3_prev as flow_vs_baseline_diff,
        (avg_pressure - baseline_avg_pressure_3_prev) / nullif(baseline_avg_pressure_3_prev, 0) as pressure_vs_baseline_pct,
        (avg_flow - baseline_avg_flow_3_prev) / nullif(baseline_avg_flow_3_prev, 0) as flow_vs_baseline_pct
    from window_features
),
flags as (
    -- Monitoring flags based on threshold logic
    select
        *,
        case
            when abs(pressure_pct_change) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_prev,
        case
            when abs(flow_pct_change) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_prev,
        case
            when abs(pressure_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_pressure_shift_rolling,
        case
            when abs(flow_vs_rolling_pct) >= 0.10 then 1
            else 0
        end as is_large_flow_shift_rolling,
        case
            when abs(pressure_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_pressure_anomaly_3_prev,
        case
            when abs(flow_vs_baseline_pct) >= 0.15 then 1
            else 0
        end as is_flow_anomaly_3_prev
    from change_features
),
signal_layer as (
    -- Total number of triggered signals
    select
        *,
        is_large_pressure_shift_prev
        + is_large_flow_shift_prev
        + is_large_pressure_shift_rolling
        + is_large_flow_shift_rolling
        + is_pressure_anomaly_3_prev
        + is_flow_anomaly_3_prev as signal_count
    from flags
),
monitoring as (
    -- Final monitoring status
    select
        *,
        case
            when signal_count = 0 then 'stable'
            when signal_count = 1 then 'warning'
            when signal_count in (2, 3) then 'anomaly'
            else 'critical'
        end as monitoring_status
    from signal_layer
),
event_monthly as (
	-- Monthly event aggregation at station-month level
    select
        date_trunc('month', event_date)::date as month_start,
        station_id,
        count(*) as event_count,
        sum(case when severity = 'critical' then 1 else 0 end) as critical_event_count,
        avg(duration_hours) as avg_event_duration
    from events
    group by 1,2
),
monitoring_with_events as(
	-- Monitoring mart enriched with event metrics
	select
        m.*,
        coalesce(e.event_count, 0) as event_count,
        coalesce(e.critical_event_count, 0) as critical_event_count,
        e.avg_event_duration
    from monitoring m
    left join event_monthly e
        on m.month_start = e.month_start
       and m.station_id = e.station_id),
event_flags as(
	-- Final event-aware monitoring flags
	select *,
			case
				when event_count > 0 then 1
				else 0
			end as has_events,
			case 
				when critical_event_count > 0 then 1
				else 0
			end as has_critical_events,
			case
				when signal_count > 0 and event_count > 0 then 1
				else 0
		    end as problematic_with_events,
		    case
		    	when monitoring_status in ('anomaly', 'critical') and  event_count > 0 then 1
		    	else 0
		    end as anomaly_or_critical_with_events	    
	 from monitoring_with_events)
select
    month_start,
    station_id,
    mode,
    signal_count,
    monitoring_status,
    event_count,
    critical_event_count,
    pressure_pct_change,
    flow_pct_change,
    pressure_vs_baseline_pct,
    flow_vs_baseline_pct
from event_flags
where station_id = 110
order by month_start, mode;