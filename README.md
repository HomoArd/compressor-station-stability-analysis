# Compressor Station Operational Stability Analysis

## Project Overview

This project analyzes compressor station telemetry and operational events to identify high-risk station-mode combinations and assess operational stability.

The analysis combines SQL-based data modeling, multi-stage aggregation, rule-based risk scoring, event profiling, and a final pandas-based validation with basic visual analysis.

The main goal of the project is to detect operating conditions associated with higher load, increased telemetry variability, and more intensive event activity.

---

## Business Goal

Compressor stations operate under different modes and load conditions. Some station-mode combinations may be less stable and may require additional monitoring.

This project aims to:
- compare stations and operating modes using telemetry metrics
- measure variability and instability across key parameters
- identify high-risk station-mode combinations
- include event activity in the final analytical view
- rank the most problematic operating scenarios

---

## How to Run

### 1. Create database
Create a PostgreSQL database, for example:

``sql
CREATE DATABASE compressor_station_analysis;

### 2. Run schema and load data

Execute the files in this order:

``sql/schema.sql
``sql/data.sql
### 3. Run analytical SQL stages

Then execute:

``sql/stage_1_checks.sql
``sql/stage_2_station_analysis.sql
``sql/stage_3_mode_analysis.sql
``sql/stage_4_station_mode_analysis.sql
``sql/stage_5_stability_metrics.sql
``sql/stage_6_risk_scoring.sql
``sql/stage_7_events_analysis.sql
``sql/stage_8_risk_events_summary.sql
``sql/final_sql_mart.sql
### 4. Export final result

Export the result of final_sql_mart.sql to CSV.

### 5. Run pandas notebook

Open final_pandas.ipynb and load the exported CSV for validation and visualization.
## Dataset Structure

The project uses three relational tables.

### 1. `stations`
Reference information about compressor stations:
- `station_id`
- `station_name`
- `region`
- `station_type`
- `commissioning_year`
- `capacity_class`

### 2. `measurements`
Telemetry measurements collected from stations:
- `measurement_id`
- `station_id`
- `measurement_time`
- `mode`
- `pressure`
- `flow`
- `temperature`
- `vibration`

### 3. `events`
Operational events associated with stations:
- `event_id`
- `station_id`
- `event_time`
- `event_type`
- `severity`
- `duration_minutes`
- `comment`

---

## Project Workflow

The project is divided into several analytical stages:

1. schema creation and data loading  
2. data quality checks  
3. station-level analysis  
4. mode-level analysis  
5. station-mode analysis  
6. stability metrics calculation  
7. rule-based risk scoring  
8. event analysis  
9. final risk-event summary  
10. final SQL mart creation  
11. pandas-based review and visualization  

---

## SQL Analysis

The SQL part of the project is the core analytical layer.

### Main SQL techniques used
- `JOIN`
- `GROUP BY`
- `AVG`, `MIN`, `MAX`, `COUNT`, `SUM`
- `STDDEV`
- Common Table Expressions (`CTE`)
- `CASE WHEN`
- `COALESCE`
- `NULLIF`
- window functions:
  - `RANK()`
  - `ROW_NUMBER()`
  - `DENSE_RANK()`

### Main analytical logic
The final SQL mart combines:

#### Telemetry aggregates
- average pressure, flow, temperature, and vibration
- minimum and maximum values
- measurement count

#### Stability metrics
- pressure range
- flow range
- temperature range
- vibration range
- standard deviation of major telemetry metrics

#### Risk scoring
A rule-based risk model is used:
- if average pressure is above the global average → `+1`
- if average flow is above the global average → `+1`
- if average temperature is above the global average → `+1`
- if average vibration is above the global average → `+1`

Risk levels:
- `0–1` → low risk
- `2` → medium risk
- `3–4` → high risk

#### Event profile
The final output also includes:
- total event count
- number of alarms
- number of repairs
- average severity
- maximum severity
- total event duration
- alarm share
- repair share

#### Ranking
The final analytical output includes rankings by:
- overall risk score
- risk score within region
- vibration level
- event severity

---

## Python Analysis

After building the final SQL mart, the result was exported to CSV and analyzed in pandas.

The Python part of the project includes:
- CSV loading and validation
- missing value checks
- top risk record review
- average risk score analysis by region
- average risk score analysis by mode
- basic visualization of risk patterns

### Visualizations created
- average risk score by region
- average risk score by mode
- pressure variability vs risk score
- event count vs risk score

---

## Key Findings

- The South region shows the highest average risk score in the dataset.
- Stress mode has the highest average risk score and appears to be the least stable operating mode.
- Pressure variability shows a weak visible relationship with risk score.
- Event count does not show a clear strong relationship with risk score in this dataset.
- The final mart helps identify station-mode combinations that may require closer operational monitoring.

---

## Repository Structure

```text
sql/
  schema.sql
  data.sql
  stage_1_checks.sql
  stage_2_station_analysis.sql
  stage_3_mode_analysis.sql
  stage_4_station_mode_analysis.sql
  stage_5_stability_metrics.sql
  stage_6_risk_scoring.sql
  stage_7_events_analysis.sql
  stage_8_risk_events_summary.sql
  final_sql_mart.sql

final_pandas.ipynb
README.md
