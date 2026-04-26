# Dataset notes

Synthetic raw data for the project "Monitoring and stability analysis of compressor stations".

## Files
- stations.csv
- measurements.csv
- events.csv

## Design choices
- 12 stations across north / south / east
- 18 months of daily measurements (2024-01-01 to 2025-06-30)
- 4 modes: normal, peak, stress, repair
- 2 intentionally unstable stations: 104, 110
- 3 relatively stable stations: 102, 107, 111
- events are more likely during problematic periods

## Intended use
You can use these files directly for:
- SQL schema loading
- monthly marts
- prev / rolling / baseline logic
- anomaly and monitoring flag analysis
- event-related metrics and risk scoring
