with monthly_layer as (
    select
        date_trunc('month', measurement_date)::date as month_start,
        station_id,
        avg(pressure) as avg_pressure,
        avg(flow) as avg_flow,
        avg(temperature) as avg_temperature,
        avg(vibration) as avg_vibration,
        count(*) as obs_count
    from measurements
    group by 1, 2
),
window_features as (
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
            partition by station_id
            order by month_start
        ),
        r as (
            partition by station_id
            order by month_start
            rows between 2 preceding and current row
        ),
        b as (
            partition by station_id
            order by month_start
            rows between 3 preceding and 1 preceding
        )
),
change_features as (
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
    select
        date_trunc('month', event_date)::date as month_start,
        station_id,
        count(*) as event_count,
        sum(case when severity = 'critical' then 1 else 0 end) as critical_event_count
    from events
    group by 1, 2
),
monitoring_with_events as (
    select
        m.*,
        coalesce(e.event_count, 0) as event_count,
        coalesce(e.critical_event_count, 0) as critical_event_count,
        case when coalesce(e.event_count, 0) > 0 then 1 else 0 end as has_events,
        case when coalesce(e.critical_event_count, 0) > 0 then 1 else 0 end as has_critical_events
    from monitoring m
    left join event_monthly e
        on m.month_start = e.month_start
       and m.station_id = e.station_id
),
ml_ready as (
    select
        *,
        lead(has_events) over (
            partition by station_id
            order by month_start
        ) as has_events_next_month,
        lead(has_critical_events) over (
            partition by station_id
            order by month_start
        ) as has_critical_events_next_month
    from monitoring_with_events
)
select *
from ml_ready
order by station_id, month_start;
