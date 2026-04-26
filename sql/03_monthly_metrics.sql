with monthly_layer as (
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
)
select *
from monthly_layer
order by station_id, mode, month_start;