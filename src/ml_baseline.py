
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
from sklearn.metrics import confusion_matrix
df = pd.read_csv("C:/Users/1/Desktop/compressor-station-monitoring/data/processed/ml_ready.csv")

df["month_start"] = pd.to_datetime(df["month_start"])



target_col = "has_events_next_month"

feature_cols = [
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
    "rolling_avg_temperature_3",
    "rolling_avg_vibration_3",
    "baseline_avg_pressure_3_prev",
    "baseline_avg_flow_3_prev",
    "baseline_avg_temperature_3_prev",
    "baseline_avg_vibration_3_prev",
    "pressure_abs_change",
    "pressure_pct_change",
    "flow_abs_change",
    "flow_pct_change",
    "temperature_abs_change",
    "temperature_pct_change",
    "vibration_abs_change",
    "vibration_pct_change",
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
]

df = df.dropna(subset=[target_col] + feature_cols).copy()
df = df.sort_values(["month_start", "station_id"]).copy()
df[target_col] = df[target_col].astype(int)

unique_months = sorted(df["month_start"].unique())
split_idx = int(len(unique_months) * 0.8)
train_months = unique_months[:split_idx]
test_months = unique_months[split_idx:]

train_df = df[df["month_start"].isin(train_months)].copy()
test_df = df[df["month_start"].isin(test_months)].copy()

X_train = train_df[feature_cols]
y_train = train_df[target_col]

X_test = test_df[feature_cols]
y_test = test_df[target_col]

model = LogisticRegression(max_iter=1000, class_weight="balanced")
model.fit(X_train, y_train)

pred = model.predict(X_test)

print("train shape:", train_df.shape)
print("test shape:", test_df.shape)
print("train months:", train_df["month_start"].min(), "->", train_df["month_start"].max())
print("test months:", test_df["month_start"].min(), "->", test_df["month_start"].max())

print("accuracy:", accuracy_score(y_test, pred))
print("precision:", precision_score(y_test, pred, zero_division=0))
print("recall:", recall_score(y_test, pred, zero_division=0))
print("f1:", f1_score(y_test, pred, zero_division=0))
print(confusion_matrix(y_test, pred))