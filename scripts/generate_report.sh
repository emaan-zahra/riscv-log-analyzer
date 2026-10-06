#!/usr/bin/env bash
# generate_report.sh - run the analyzer on every log in test_data/
# and save one text report per log into output/
set -euo pipefail

mkdir -p output

# Loop over every .log file in test_data
for log in test_data/*.log; do
    # basename removes the folder and ".log", e.g. sample_fail
    name=$(basename "$log" .log)
    # "|| true" because analyze.sh exits 1 when a test failed,
    # and set -e would otherwise stop this script
    ./scripts/analyze.sh "$log" --output "output/$name.txt" || true
    echo "Created output/$name.txt"
done

echo "All reports generated in output/"