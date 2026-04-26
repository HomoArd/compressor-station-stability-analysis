
# base

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# =========================================================
# PROJECT 1 — pandas validation
# File: monitoring_validation_and_plots.py
# Goal: reproduce core monitoring logic from SQL in pandas
# =========================================================


# Load raw CSV files:
measurements = pd.read_csv("C:/Users/1/Desktop/compressor-station-monitoring/data/raw/measurements.csv")
events = pd.read_csv("C:/Users/1/Desktop/compressor-station-monitoring/data/raw/events.csv")


# Convert date columns to datetime:
measurements["measurement_date"] = pd.to_datetime(measurements["measurement_date"])
measurements["month_start"] = measurements["measurement_date"].dt.to_period("M").dt.to_timestamp()

events["event_date"] = pd.to_datetime(events["event_date"])
events["month_start"] =events["event_date"].dt.to_period("M").dt.to_timestamp()
# After that create month_start in both tables.
# month_start should represent the beginning of the month.
print("measurements shape:", measurements.shape)
print("events shape:", events.shape)


print(measurements.head(3))
print(events.head(3))


print(measurements[["measurement_date", "month_start"]].dtypes)
print(events[["event_date", "month_start"]].dtypes)


print("measurements min date:", measurements["measurement_date"].min())
print("measurements max date:", measurements["measurement_date"].max())
print("events min date:", events["event_date"].min())
print("events max date:", events["event_date"].max())

# Build monthly_pd from measurements.

monthly_pd = measurements.groupby(["station_id","mode","month_start"],as_index=False).agg(
    avg_pressure = ("pressure", "mean"),
    avg_flow = ("flow", "mean"),
    avg_temperature = ("temperature", "mean"),
    avg_vibration = ("vibration", "mean"),
    obs_count = ("pressure", "size")
).sort_values(["station_id","mode","month_start"]).copy()

print(monthly_pd.shape)
print(monthly_pd.head(3))



# Check that monthly_pd has no duplicates on:

duplicate_mask = monthly_pd.duplicated(subset=["month_start","station_id","mode"],keep=False)
duplicate_df= monthly_pd.loc[duplicate_mask].sort_values(["station_id","mode","month_start"])

print("duplicate rows:", duplicate_mask.sum())

if duplicate_mask.sum() == 0:
    print("No duplicates found on grain: month_start + station_id + mode")
else:
    print(duplicate_df.head())



# TASK 5
# Build previous-period features inside each station_id + mode group.
group_keys = ["station_id", "mode"]
avg_cols = ["avg_pressure", "avg_flow","avg_temperature","avg_vibration"]

g= monthly_pd.groupby(group_keys)

for col in  avg_cols:
    monthly_pd[f"prev_{col}"] = g[col].shift(1)


# TASK 6
# Build rolling and baseline features.
# Important:
# rolling and baseline should not mean the same thing.
#
# Then inspect the first rows of one group and verify the logic manually.

for col in  avg_cols:
    monthly_pd[f"rolling_{col}_3"] = g[col].transform(
        lambda s: s.rolling(3,min_periods=1).mean()
    )
    monthly_pd[f"baseline_{col}_3_prev"]=g[col].transform(
        lambda s: s.shift(1).rolling(3,min_periods=1).mean()
    )


# TASK 7
# Build change features for pressure and flow.

cols = ["pressure" , "flow"]
for col in cols:
    monthly_pd[f"{col}_abs_change"] = monthly_pd[f"avg_{col}"] - monthly_pd[f"prev_avg_{col}"]
    monthly_pd[f"{col}_pct_change"] = monthly_pd[f"{col}_abs_change"] / monthly_pd[f"prev_avg_{col}"].replace(0,pd.NA)

compare_cols={
    "rolling" : "rolling_avg_{col}_3",
    "baseline" : "baseline_avg_{col}_3_prev"
}

for col in cols:
    for ref_name, ref_pattern in compare_cols.items():
        ref_col=ref_pattern.format(col=col)
        monthly_pd[f"{col}_vs_{ref_name}_diff"] = monthly_pd[f"avg_{col}"] - monthly_pd[ref_col]
        monthly_pd[f"{col}_vs_{ref_name}_pct"] = monthly_pd[f"{col}_vs_{ref_name}_diff"] / monthly_pd[ref_col].replace(0,pd.NA)
# Make sure division by zero does not break the pipeline.


# TASK 8
# Build monitoring flags using the current working thresholds (v2).

a1=0.1
a2=0.15
for col in cols:
    monthly_pd[f"is_large_{col}_shift_prev"] = (monthly_pd[f"{col}_pct_change"].abs() >= a1).fillna(False).astype(int)
    monthly_pd[f"is_large_{col}_shift_rolling"] = (monthly_pd[f"{col}_vs_rolling_pct"].abs()>= a1).fillna(False).astype(int)
    monthly_pd[f"is_{col}_anomaly_3_prev"]=( monthly_pd[f"{col}_vs_baseline_pct"].abs() >=a2).fillna(False).astype(int)
# All flags should be binary: 0/1.


# TASK 9
# Build:
# - signal_count
# - monitoring_status

flag_cols = [
    "is_large_pressure_shift_prev",
    "is_large_flow_shift_prev",
    "is_large_pressure_shift_rolling",
    "is_large_flow_shift_rolling",
    "is_pressure_anomaly_3_prev",
    "is_flow_anomaly_3_prev"
]
monthly_pd["signal_count"] = monthly_pd[flag_cols].sum(axis=1)

for col in cols:
    monthly_pd[f"{col}_monitoring_status"] = np.select(
             [monthly_pd[f"is_{col}_anomaly_3_prev"] == 1,
              monthly_pd[f"is_large_{col}_shift_rolling"] ==1,
              monthly_pd[f"is_large_{col}_shift_prev"] == 1, ],
             ["anomaly_vs_baseline",
              "large_shift_vs_rolling",
              "large_shift_vs_prev",
              ],
             default="normal")
monthly_pd["monitoring_status"] = np.select(
    [
        monthly_pd["signal_count"] == 0,
        monthly_pd["signal_count"] == 1,
        monthly_pd["signal_count"].isin([2, 3]),
        monthly_pd["signal_count"] >= 4,
    ],
    [
        "stable",
        "warning",
        "anomaly",
        "critical",
    ],
    default="stable"
)

# TASK 10
# Build event_monthly from events.
#
# Grain:
# one row = one month_start + station_id
# TASK 10
# Build event_monthly from events

events["is_critical_event"] = (events["severity"] == "critical").astype(int)

event_monthly = events.groupby(["month_start", "station_id"], as_index=False).agg(
    event_count=("severity", "size"),
    critical_event_count=("is_critical_event", "sum"),
    avg_event_duration=("duration_hours", "mean")
)

monitoring_pd = monthly_pd.merge(
    event_monthly,
    on=["month_start", "station_id"],
    how="left",
    indicator=True
)

monitoring_pd["event_count"] = monitoring_pd["event_count"].fillna(0).astype(int)
monitoring_pd["critical_event_count"] = monitoring_pd["critical_event_count"].fillna(0).astype(int)

monitoring_pd["has_events"] = (monitoring_pd["event_count"] > 0).astype(int)
monitoring_pd["has_critical_events"] = (monitoring_pd["critical_event_count"] > 0).astype(int)

monitoring_pd["problematic_with_events"] = (
    (monitoring_pd["signal_count"] > 0) & (monitoring_pd["event_count"] > 0)
).astype(int)

monitoring_pd["anomaly_or_critical_with_events"] = (
    monitoring_pd["monitoring_status"].isin(["anomaly", "critical"]) &
    (monitoring_pd["event_count"] > 0)
).astype(int)

# load sql desicion in monitoring_sql
monitoring_sql = pd.read_csv("C:/Users/1/Desktop/compressor-station-monitoring/data/processed/monitoring_sql.csv")
monitoring_sql["month_start"] = pd.to_datetime(monitoring_sql["month_start"])

#check  values
validation_check = monitoring_pd.merge(
    monitoring_sql,
    on=["month_start", "station_id", "mode"],
    how="inner",
    suffixes=("_pd", "_sql"),
    indicator="merge_flag"
)

validation_check.shape
validation_check["merge_flag"].value_counts()

#check columns

validation_merge = monitoring_pd.merge(
    monitoring_sql,
    on=["month_start", "station_id", "mode"],
    how="outer",
    suffixes=("_pd", "_sql"),
    indicator="merge_flag"
)

compare_cols = [
    "avg_pressure",
    "avg_flow",
    "avg_temperature",
    "avg_vibration",
    "obs_count",
    "prev_avg_pressure",
    "prev_avg_flow",
    "prev_avg_temperature",
    "prev_avg_vibration",
    "rolling_avg_pressure_3",
    "rolling_avg_flow_3",
    "baseline_avg_pressure_3_prev",
    "baseline_avg_flow_3_prev",
    "pressure_abs_change",
    "pressure_pct_change",
    "flow_abs_change",
    "flow_pct_change",
    "pressure_vs_rolling_diff",
    "pressure_vs_rolling_pct",
    "flow_vs_rolling_diff",
    "flow_vs_rolling_pct",
    "pressure_vs_baseline_diff",
    "pressure_vs_baseline_pct",
    "flow_vs_baseline_diff",
    "flow_vs_baseline_pct",
    "is_large_pressure_shift_prev",
    "is_large_flow_shift_prev",
    "is_large_pressure_shift_rolling",
    "is_large_flow_shift_rolling",
    "is_pressure_anomaly_3_prev",
    "is_flow_anomaly_3_prev",
    "signal_count",
    "monitoring_status",
    "event_count",
    "critical_event_count",
    "has_events",
    "has_critical_events",
    "problematic_with_events",
    "anomaly_or_critical_with_events"
]
validation_both = validation_merge.loc[
    validation_merge["merge_flag"] == "both"
].copy()

for col in compare_cols:   
    if validation_both[f"{col}_pd"].dtype.kind in 'if':
        validation_both[f"{col}_check"] = np.isclose(
            validation_both[f"{col}_pd"],
            validation_both[f"{col}_sql"],
            equal_nan=True
        )
    else:
        validation_both[f"{col}_check"] = (
            validation_both[f"{col}_pd"] == validation_both[f"{col}_sql"])
    
check_cols = [col for col in validation_both.columns if col.endswith("_check")]

validation_both["is_match"] = validation_both[check_cols].all(axis=1)

mismatch_df = validation_both.loc[~validation_both["is_match"]]

print(mismatch_df.shape)
print(mismatch_df.head())
print(mismatch_df["merge_flag"].value_counts())


print((~validation_both[check_cols]).sum().sort_values(ascending=False))

plot_df =  monitoring_pd.query("station_id == 110 and mode == 'repair'").sort_values("month_start").copy()


plt.figure(figsize=(10, 5))

plt.plot(
    plot_df["month_start"],
    plot_df["avg_pressure"],
    marker = "o",
    label="avg_pressure"
)

plt.plot(
    plot_df["month_start"],
    plot_df["rolling_avg_pressure_3"],
    marker = "o",
    label="rolling_avg_pressure_3"
)

plt.plot(
    plot_df["month_start"],
    plot_df["baseline_avg_pressure_3_prev"],
    marker = "o",
    label="baseline_avg_pressure_3_prev"
)



plt.title("Pressure monitoring: station_id =110, mode = repair")
plt.xlabel("month_start")
plt.ylabel("pressure")
plt.xticks(rotation=45)
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()

plt.figure(figsize=(10, 5))

anomaly_df = plot_df[plot_df["signal_count"] > 0]

plt.plot(
    plot_df["month_start"],
    plot_df["avg_pressure"],
    marker = "o",
    label="avg_pressure"
)

plt.plot(
    plot_df["month_start"],
    plot_df["rolling_avg_pressure_3"],
    marker = "o",
    label="rolling_avg_pressure_3"
)

plt.scatter(
    anomaly_df["month_start"],
    anomaly_df["avg_pressure"],
    s=240,
    label="signal_points",
)



plt.title("Pressure anomalies: station_id =110, mode = repair")
plt.xlabel("month_start")
plt.ylabel("pressure")
plt.xticks(rotation=45)
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()



event_anomaly_df = plot_df[plot_df["event_count"] > 0]
critical_event_df= plot_df[plot_df["critical_event_count"] > 0]

plt.figure(figsize=(10, 5))

plt.plot(
    plot_df["month_start"],
    plot_df["avg_pressure"],
    marker = "o",
    label="avg_pressure"
)

plt.plot(
    plot_df["month_start"],
    plot_df["rolling_avg_pressure_3"],
    marker = "o",
    label="rolling_avg_pressure_3"
)

plt.scatter(
    event_anomaly_df["month_start"],
    event_anomaly_df["avg_pressure"],
    s=240,
    label="event_points",
)

plt.scatter(
    critical_event_df["month_start"],
    critical_event_df["avg_pressure"],
    s=240,
    label="critical_event_points",
)


plt.title("Pressure with event markers: station_id =110, mode = repair")
plt.xlabel("month_start")
plt.ylabel("pressure")
plt.xticks(rotation=45)
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()

plot_stable =  monitoring_pd.query("station_id == 102 and mode == 'normal'").sort_values("month_start").copy()
event_stable_df = plot_stable[plot_stable["event_count"] > 0]
anomaly_stable_df = plot_stable[plot_stable["signal_count"] > 0]
plt.figure(figsize=(10, 5))

plt.plot(
    plot_stable["month_start"],
    plot_stable["avg_pressure"],
    marker = "o",
    label="avg_pressure"
)

plt.plot(
    plot_stable["month_start"],
    plot_stable["rolling_avg_pressure_3"],
    marker = "o",
    label="rolling_avg_pressure_3"
)

plt.plot(
    plot_stable["month_start"],
    plot_stable["baseline_avg_pressure_3_prev"],
    marker = "o",
    label="baseline_avg_pressure_3_prev"
)

plt.scatter(
    event_stable_df["month_start"],
    event_stable_df["avg_pressure"],
    s=240,
    label="event_points",
)

plt.scatter(
    anomaly_stable_df["month_start"],
    anomaly_stable_df["avg_pressure"],
    s=240,
    label="anomaly_points",
)

plt.title("Pressure monitoring: station_id =102, mode = normal")
plt.xlabel("month_start")
plt.ylabel("pressure")
plt.xticks(rotation=45)
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()

plot_flow_stable = monitoring_pd.query(
    "station_id == 102 and mode == 'normal'"
).sort_values("month_start").copy()

event_flow_df = plot_flow_stable[plot_flow_stable["event_count"] > 0]
signal_flow_df = plot_flow_stable[plot_flow_stable["signal_count"] > 0]

plt.figure(figsize=(10, 5))

plt.plot(
    plot_flow_stable["month_start"],
    plot_flow_stable["avg_flow"],
    marker="o",
    label="avg_flow"
)

plt.plot(
    plot_flow_stable["month_start"],
    plot_flow_stable["rolling_avg_flow_3"],
    marker="o",
    label="rolling_avg_flow_3"
)

plt.plot(
    plot_flow_stable["month_start"],
    plot_flow_stable["baseline_avg_flow_3_prev"],
    marker="o",
    label="baseline_avg_flow_3_prev"
)

plt.scatter(
    event_flow_df["month_start"],
    event_flow_df["avg_flow"],
    s=240,
    label="event_points"
)

plt.scatter(
    signal_flow_df["month_start"],
    signal_flow_df["avg_flow"],
    s=240,
    label="signal_points"
)

plt.title("Flow monitoring: station_id = 102, mode = normal")
plt.xlabel("month_start")
plt.ylabel("flow")
plt.xticks(rotation=45)
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()