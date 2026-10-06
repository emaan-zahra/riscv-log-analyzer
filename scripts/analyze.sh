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

# Get the names of failing tests.
# Each FAIL line looks like: [time] TEST FAIL: rv32i-sll (1.02s)
# After "TEST FAIL: " the name is the next word, so awk prints field $5.
FAILED_TESTS=$(grep "TEST FAIL:" "$LOG_FILE" | awk '{print $5}' || true)

echo ""
echo "--- Failed Tests ---"
if [[ -z "$FAILED_TESTS" ]]; then
    echo "  (none)"
else
    # nl numbers each line: 1, 2, 3 ...
    echo "$FAILED_TESTS" | nl -w2 -s'. '
fi

# Timing: only PASS and FAIL lines have a time like (0.82s).
# SKIP lines say "(not supported)", so we leave them out.
# awk remembers the min, max and sum while it reads each line.
TIMING=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" | awk '
{
    name = $5                    # test name, e.g. rv32i-add
    t = $6                       # time, e.g. (0.82s)
    gsub(/[()s]/, "", t)         # remove ( ) and s, leaving 0.82
    t = t + 0                    # turn the text into a number
    if (n == 0 || t < min) { min = t; minname = name }
    if (n == 0 || t > max) { max = t; maxname = name }
    sum += t
    n++
}
END {
    if (n > 0)
        printf "%.2f %s %.2f %s %.2f", min, minname, max, maxname, sum / n
}')

echo ""
echo "--- Timing Statistics ---"
if [[ -z "$TIMING" ]]; then
    echo "No timing data found"
else
    # Split the awk result into five variables
    read -r MIN_T MIN_N MAX_T MAX_N AVG_T <<< "$TIMING"
    echo "Min time:  ${MIN_T}s ($MIN_N)"
    echo "Max time:  ${MAX_T}s ($MAX_N)"
    echo "Avg time:  ${AVG_T}s"
fi