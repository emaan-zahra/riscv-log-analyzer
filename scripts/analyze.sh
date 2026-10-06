#!/usr/bin/env bash
set -euo pipefail

# Function 1: show how to use the script
usage() {
    echo "Usage: analyze.sh <log_file>"
    echo "Options:"
    echo "  --help    Show this message"
}

# Function 2: print an error message and stop
error_exit() {
    echo "Error: $1" >&2
    exit 2
}

# If no argument was given, stop with an error
if [[ $# -eq 0 ]]; then
    error_exit "Please give the path to a log file"
fi

# If the first argument is --help, show usage and stop
if [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

LOG_FILE="$1"

# If the file does not exist, stop with an error
if [[ ! -f "$LOG_FILE" ]]; then
    error_exit "File not found: $LOG_FILE"
fi

# Count each result by searching for the words in the log.
# grep -c counts matching lines. "|| true" stops the script from
# quitting when grep finds zero matches (set -e would treat that as an error).
PASS_COUNT=$(grep -c "TEST PASS:" "$LOG_FILE" || true)
FAIL_COUNT=$(grep -c "TEST FAIL:" "$LOG_FILE" || true)
SKIP_COUNT=$(grep -c "TEST SKIP:" "$LOG_FILE" || true)

# Total is the three numbers added together
TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))

# Pass rate as a percentage. awk is used because bash can't do decimals.
# If TOTAL is 0 we print 0.0 to avoid dividing by zero.
PASS_RATE=$(awk -v p="$PASS_COUNT" -v t="$TOTAL" 'BEGIN { if (t == 0) print "0.0"; else printf "%.1f", p * 100 / t }')

# Temporary lines so we can check the numbers (we will replace these later)
echo "Total:  $TOTAL"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Skipped: $SKIP_COUNT"
echo "Pass rate: $PASS_RATE%"