#!/usr/bin/env bash
# generate_report.sh - run the analyzer on every log in test_data/
# and save a text report and an HTML report per log into output/
set -euo pipefail

mkdir -p output

# Function 1: build an HTML page with a table of results for one log file
make_html() {
    local log="$1"    # path to the log file
    local out="$2"    # path of the HTML file to write

    {
        echo "<!DOCTYPE html>"
        echo "<html><head><meta charset=\"utf-8\"><title>Report: $(basename "$log")</title>"
        echo "<style>"
        echo "  body { font-family: sans-serif; margin: 2em; }"
        echo "  table { border-collapse: collapse; }"
        echo "  th, td { border: 1px solid #999; padding: 6px 12px; text-align: left; }"
        echo "  th { background: #eee; }"
        echo "  .PASS { color: green; font-weight: bold; }"
        echo "  .FAIL { color: red; font-weight: bold; }"
        echo "  .SKIP { color: #b8860b; font-weight: bold; }"
        echo "</style></head><body>"
        echo "<h1>RISC-V Simulation Report</h1>"
        echo "<p>Log file: $log</p>"
        echo "<table>"
        echo "<tr><th>Test</th><th>Result</th><th>Time</th></tr>"
        # Each result line looks like: [date time] TEST PASS: name (0.82s)
        # $4 is "PASS:" / "FAIL:" / "SKIP:", $5 is the name, $6 is the time
        grep -E "TEST (PASS|FAIL|SKIP):" "$log" | awk '
        {
            result = $4
            sub(/:/, "", result)               # remove the colon from PASS:
            time = $6
            if (result == "SKIP") time = "-"   # skipped tests have no time
            printf "<tr><td>%s</td><td class=\"%s\">%s</td><td>%s</td></tr>\n", $5, result, result, time
        }'
        echo "</table>"
        echo "</body></html>"
    } > "$out"
}

# Loop over every .log file in test_data
for log in test_data/*.log; do
    name=$(basename "$log" .log)
    # "|| true" because analyze.sh exits 1 when a test failed,
    # and set -e would otherwise stop this script
    ./scripts/analyze.sh "$log" --output "output/$name.txt" || true
    make_html "$log" "output/$name.html"
    echo "Created output/$name.txt and output/$name.html"
done

echo "All reports generated in output/"