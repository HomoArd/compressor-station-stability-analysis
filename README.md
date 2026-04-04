# Compressor Station Stability Analysis

## Project Overview

This project is an end-to-end analytical case study focused on the operational stability of compressor stations.

The goal is to analyze telemetry and event data, identify potentially unstable operating conditions, and build a final analytical mart that highlights higher-risk station and mode combinations.

The project combines:
- SQL-based analytical workflow in PostgreSQL
- rule-based risk scoring
- pandas validation and visualization in Python

---

## Business Goal

The main objective is to evaluate how stable different compressor stations are under different operating modes.

The project is designed to answer questions such as:
- Which stations operate under higher average pressure, flow, temperature, and vibration?
- Which operating modes look less stable than others?
- Where do we observe higher variability in telemetry?
- Which station-mode combinations should be prioritized for operational review?

---

## Dataset Description

The project uses three tables:

### stations
Reference information about compressor stations.

Main fields:
- station_id
- station_name
- region

### measurements
Telemetry data collected from compressor stations.

Main fields:
- station_id
- date
- mode
- pressure
- flow
- temperature
- vibration

### events
Operational event log.

Main fields:
- station_id
- event_type
- severity

---

## Project Structure

sql/
├── schema.sql
├── data.sql
├── stage_1_checks.sql
├── stage_2_station_analysis.sql
├── stage_3_mode_analysis.sql
├── stage_4_station_mode_analysis.sql
├── stage_5_stability_metrics.sql
├── stage_6_risk_scoring.sql
├── stage_7_events_analysis.sql
├── stage_8_risk_events_summary.sql
└── final_sql_mart.sql

final_pandas.ipynb
README.md

---

## Analytical Workflow

The project is organized as a sequence of analytical stages.

### 1. Data quality checks
Initial validation of source data:
- row counts
- distinct values
- missing values
- orphan station references

### 2. Station-level analysis
Aggregation of telemetry metrics by station:
- average pressure
- average flow
- average temperature
- average vibration

### 3. Mode-level analysis
Comparison of operational behavior across different modes.

### 4. Station-mode analysis
Detailed breakdown by both station and mode.

### 5. Stability metrics
Calculation of stability-related metrics:
- minimum and maximum values
- ranges
- standard deviation

### 6. Rule-based risk scoring
Creation of an interpretable baseline risk score based on telemetry metrics.

### 7. Events analysis
Analysis of operational events:
- total event count
- alarm count
- critical count
- warning count

### 8. Final mart
Combination of telemetry-based risk features and station-level event context into a final analytical dataset.

---

## Risk Scoring Logic

A simple rule-based risk score is used as an interpretable analytical baseline.

A station-mode combination receives points when selected metrics are above the global average, for example:
- average pressure
- average vibration
- pressure variability
- vibration variability

The total score is then mapped into a qualitative label:
- low
- medium
- high

This approach is intentionally simple and transparent. It is designed for analytical interpretation, not for predictive modeling.

---

## Final Analytical Mart

The final SQL mart contains aggregated metrics such as:
- average telemetry values
- minimum and maximum telemetry values
- variability measures
- event statistics
- risk score
- risk level
- rankings by score

This final dataset can be used for:
- operational monitoring
- prioritization of unstable station-mode combinations
- further validation in pandas
- visualization and reporting

---

## SQL Skills Demonstrated

This project includes practical use of:
- SELECT
- WHERE
- ORDER BY
- GROUP BY
- HAVING
- JOIN
- LEFT JOIN
- CTEs
- aggregate functions
- CASE WHEN
- COALESCE
- NULLIF
- STDDEV
- window functions:
  - RANK()
  - ROW_NUMBER()
  - DENSE_RANK()

---

## Python / pandas Part

The notebook final_pandas.ipynb is used for the final review of the SQL mart.

Main tasks:
- load exported final SQL results into pandas
- validate missing values
- inspect high-risk rows
- compare risk patterns by region and mode
- build visualizations for interpretation

Examples of analysis performed in Python:
- average risk score by region
- average risk score by mode
- scatter plots for variability vs risk
- scatter plots for event count vs risk

---

## Key Findings

Main analytical observations from the project:

- Some regions demonstrate higher average risk scores than others.
- Stress-like operating modes tend to appear less stable than normal modes.
- Higher variability in telemetry is an important signal for risk interpretation.
- Event intensity adds useful operational context, but does not fully explain the final risk level on its own.
- The final mart helps identify station-mode combinations that may require closer monitoring.

---

## Business Interpretation

This project shows how telemetry and event data can be transformed into a compact analytical mart for operational review.

The final result can support:
- monitoring of potentially unstable operating conditions
- faster identification of problematic station-mode combinations
- prioritization of engineering review
- preparation of data for further analytical or machine learning tasks

---

## Project Limitations

- The risk score is rule-based and serves as an interpretable baseline, not as a machine learning model.
- Event features are included as operational context.
- Telemetry risk is calculated at the station-mode level, while events are aggregated at the station level.
- Because of this, event metrics should be interpreted as station-level context rather than mode-specific signals.
- The dataset is educational and is intended for analytical practice.

---

## How to Run

### 1. Create a PostgreSQL database

Example:

CREATE DATABASE compressor_station_analysis;

### 2. Run schema and load data

Execute:
1. sql/schema.sql
2. sql/data.sql

### 3. Run analytical SQL files

Execute in order:
1. sql/stage_1_checks.sql
2. sql/stage_2_station_analysis.sql
3. sql/stage_3_mode_analysis.sql
4. sql/stage_4_station_mode_analysis.sql
5. sql/stage_5_stability_metrics.sql
6. sql/stage_6_risk_scoring.sql
7. sql/stage_7_events_analysis.sql
8. sql/stage_8_risk_events_summary.sql
9. sql/final_sql_mart.sql

### 4. Export final result

Export the result of final_sql_mart.sql to a CSV file.

### 5. Run pandas notebook

Open final_pandas.ipynb and load the exported CSV file for validation and visualization.

---

## Requirements

### SQL
- PostgreSQL

### Python
- Python 3.11+
- pandas
- matplotlib
- jupyter

Example installation:

pip install pandas matplotlib jupyter

---

## Future Improvements

Possible next steps for the project:
- convert the final mart into a SQL VIEW
- add screenshots of charts to the README
- expand the risk logic with weighted scoring
- compare rule-based scoring with a simple machine learning baseline
- add anomaly detection on telemetry time series

---

## Conclusion

This project demonstrates a full analytical workflow:
- data validation
- multi-stage SQL analysis
- stability metric calculation
- interpretable risk scoring
- final mart creation
- pandas-based validation and visualization

It reflects a practical learning project in analytics and data analysis using an industrial-style operational scenario.
