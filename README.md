# Compressor Station Operational Stability Analysis

## Project Overview
This project analyzes compressor station telemetry and operational events to identify potentially unstable operating modes.

The analysis combines SQL-based data modeling, multi-table aggregation, rule-based risk scoring, and event profiling.  
The goal is to detect station-mode combinations associated with higher operational load, increased variability, and a more intensive event profile.

## Project Goals
- analyze compressor station telemetry across multiple operating modes
- compare stations and modes by pressure, flow, temperature, and vibration
- calculate stability metrics such as ranges and standard deviations
- build a rule-based risk scoring model
- integrate operational events into the final analytical mart
- rank station-mode combinations by risk and vibration intensity

## Dataset Structure
The project uses three relational tables:

### 1. `stations`
Station reference table:
- `station_id`
- `station_name`
- `region`
- `station_type`
- `commissioning_year`
- `capacity_class`

### 2. `measurements`
Telemetry measurements:
- `measurement_id`
- `station_id`
- `measurement_time`
- `mode`
- `pressure`
- `flow`
- `temperature`
- `vibration`

### 3. `events`
Operational events:
- `event_id`
- `station_id`
- `event_time`
- `event_type`
- `severity`
- `duration_minutes`
- `comment`

## SQL Workflow
The SQL part of the project is organized into multiple stages:

- data quality checks
- station-level analysis
- mode-level analysis
- station-mode analysis
- stability metrics
- comparison against global averages
- rule-based risk scoring
- event analysis
- ranking with window functions
- final analytical mart

## Key SQL Techniques Used
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

## Main Analytical Logic
The project builds a final SQL mart that combines:

### Telemetry aggregates
- average pressure, flow, temperature, vibration
- min/max values
- measurement count

### Stability metrics
- pressure range
- flow range
- temperature range
- vibration range
- standard deviation for all major telemetry metrics

### Risk scoring
A rule-based risk model is used:
- if average pressure is above the global average → +1
- if average flow is above the global average → +1
- if average temperature is above the global average → +1
- if average vibration is above the global average → +1

Risk levels:
- `0–1` → low risk
- `2` → medium risk
- `3–4` → high risk

### Event profile
The final mart also includes:
- total event count
- number of alarms
- number of repairs
- average severity
- maximum severity
- total event duration
- alarm share
- repair share

### Ranking
The final output includes rankings by:
- risk score
- risk score within region
- vibration level
- event severity

## Final Output
The main result of the SQL part is the file:

- `sql/final_sql_mart.sql`

It produces a consolidated analytical mart for station-mode combinations.

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
  stage_8_window_functions.sql
  final_sql_mart.sql
