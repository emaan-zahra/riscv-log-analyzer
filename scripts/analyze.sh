#!/usr/bin/env bash
set -euo pipefail

# Default settings
FORMAT="text"
OUTPUT=""
VERBOSE=0
LOG_FILE=""
COMPARE_FILE=""   

# Function 1: show how to use the script
usage() {
    echo "Usage: analyze.sh <log_file> [options]"
    echo ""
    echo "Options:"
    echo "  --format [text|csv]   Output format (default: text)"
    echo "  --output <path>       Save output to a file (default: screen)"
    echo "  --verbose             Show extra progress messages"
    echo "  --help                Show this message"
    echo "  --compare <file>      Compare with a newer log and show regressions"
}

# Function 2: print an error message and stop
error_exit() {
    echo "Error: $1" >&2
    exit 2
}

# Function 3: print a message only when --verbose is used
log_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo "[verbose] $1" >&2
    fi
}

# Read the arguments one by one.
# "shift" throws away the argument we just handled, so $1 becomes the next one.
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --compare)
            if [[ $# -lt 2 ]]; then
                error_exit "--compare needs a file path"
            fi
            COMPARE_FILE="$2"
            shift 2
            ;;
        --format)
            # --format needs a value after it, so check there is one
            if [[ $# -lt 2 ]]; then
                error_exit "--format needs a value (text or csv)"
            fi
            FORMAT="$2"
            shift 2
            ;;
        --output)
            if [[ $# -lt 2 ]]; then
                error_exit "--output needs a file path"
            fi
            OUTPUT="$2"
            shift 2
            ;;
        -*)
            error_exit "Unknown option: $1"
            ;;
        *)
            # Anything else is the log file
            LOG_FILE="$1"
            shift
            ;;
    esac
done

# Check the inputs
if [[ -z "$LOG_FILE" ]]; then
    error_exit "Please give the path to a log file"
fi

if [[ ! -f "$LOG_FILE" ]]; then
    error_exit "File not found: $LOG_FILE"
fi

if [[ -n "$COMPARE_FILE" && ! -f "$COMPARE_FILE" ]]; then
    error_exit "File not found: $COMPARE_FILE"
fi

if [[ "$FORMAT" != "text" && "$FORMAT" != "csv" ]]; then
    error_exit "Format must be text or csv, not: $FORMAT"
fi

log_verbose "Log file: $LOG_FILE"
log_verbose "Format: $FORMAT"

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

# Percentages for the report. A small helper so we don't repeat ourselves.
# Function 4: turn a count into a percentage with one decimal place
percent() {
    awk -v c="$1" -v t="$TOTAL" 'BEGIN { if (t == 0) printf "0.0"; else printf "%.1f", c * 100 / t }'
}

# Names of failing tests, one per line (empty if none)
FAILED_TESTS=$(grep "TEST FAIL:" "$LOG_FILE" | awk '{print $5}' || true)

# Timing: only PASS and FAIL lines have a time like (0.82s).
# SKIP lines say "(not supported)", so we leave them out.
TIMING=$(grep -E "TEST (PASS|FAIL):" "$LOG_FILE" | awk '
{
    name = $5
    t = $6
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

MIN_T="" MIN_N="" MAX_T="" MAX_N="" AVG_T=""
if [[ -n "$TIMING" ]]; then
    read -r MIN_T MIN_N MAX_T MAX_N AVG_T <<< "$TIMING"
fi

# Function 5: build the text report
make_text_report() {
    echo "=== RISC-V Simulation Log Analysis ==="
    echo "Log file: $LOG_FILE"
    echo "Analysis date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "--- Results Summary ---"
    echo "Total tests: $TOTAL"
    printf "${GREEN}Passed:  %4d (%5s%%)${RESET}\n" "$PASS_COUNT" "$PASS_RATE"
    printf "${RED}Failed:  %4d (%5s%%)${RESET}\n" "$FAIL_COUNT" "$(percent "$FAIL_COUNT")"
    printf "Skipped: %4d (%5s%%)\n" "$SKIP_COUNT" "$(percent "$SKIP_COUNT")"
    echo ""
    echo "--- Per-Test Times ---"
    # Print each test name and its time; SKIP lines have no time, so they are left out
        # $4 is "PASS:" or "FAIL:", so we pick the color from it
    grep -E "TEST (PASS|FAIL):" "$LOG_FILE" | awk -v g="$GREEN" -v r="$RED" -v z="$RESET" \
        '{ c = ($4 == "PASS:") ? g : r; printf "  %s%-14s %s%s\n", c, $5, $6, z }'
    echo ""




    echo "--- Failed Tests ---"
    if [[ -z "$FAILED_TESTS" ]]; then
        echo "  (none)"
    else
        echo "$FAILED_TESTS" | nl -w3 -s'. '
    fi
    echo ""
    echo "--- Timing Statistics ---"
    if [[ -z "$TIMING" ]]; then
        echo "No timing data found"
    else
        echo "Min time:  ${MIN_T}s ($MIN_N)"
        echo "Max time:  ${MAX_T}s ($MAX_N)"
        echo "Avg time:  ${AVG_T}s"
    fi
    echo ""
    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo "${RED}--- Verdict: FAIL ---${RESET}"
        echo "Exit code: 1"
    else
        echo "${GREEN}--- Verdict: PASS ---${RESET}"
        echo "Exit code: 0"
    fi
}

# Function 6: build the CSV report (header line, then one line per metric)
make_csv_report() {
    echo "metric,value"
    echo "log_file,$LOG_FILE"
    echo "total,$TOTAL"
    echo "passed,$PASS_COUNT"
    echo "failed,$FAIL_COUNT"
    echo "skipped,$SKIP_COUNT"
    echo "pass_rate,$PASS_RATE"
    # Join the failing names with semicolons so they fit in one CSV cell
    echo "failed_tests,$(echo "$FAILED_TESTS" | paste -sd';' -)"
    echo "min_time,${MIN_T:-}"
    echo "min_test,${MIN_N:-}"
    echo "max_time,${MAX_T:-}"
    echo "max_test,${MAX_N:-}"
    echo "avg_time,${AVG_T:-}"
}

# Colors (ANSI escape codes). We only use them when printing to a terminal.
# [[ -t 1 ]] is true when stdout is a screen, and false when piped or saved to a file,
# so reports saved with --output or checked by "make test" stay free of escape codes.
if [[ -t 1 && -z "$OUTPUT" ]]; then
    GREEN=$'\033[32m'
    RED=$'\033[31m'
    RESET=$'\033[0m'
else
    GREEN=""
    RED=""
    RESET=""
fi

# Pick the report type, then print it to the screen or save it to a file
# Function: list tests that passed in the first log but fail in the second
compare_logs() {
    local before="$1"
    local after="$2"
    local found=0

    echo "=== Regression Check ==="
    echo "Before: $before"
    echo "After:  $after"
    echo ""
    echo "--- Regressions (passed before, fail now) ---"

    # Names of tests that passed in the "before" log
    local passed_before
    passed_before=$(grep "TEST PASS:" "$before" | awk '{print $5}' || true)

    # Names of tests that failed in the "after" log
    local failed_after
    failed_after=$(grep "TEST FAIL:" "$after" | awk '{print $5}' || true)

    # A regression is a name that appears in both lists
    local name
    for name in $failed_after; do
        if echo "$passed_before" | grep -qx "$name"; then
            echo "  REGRESSION: $name"
            found=$((found + 1))
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo "  (none)"
    fi
    echo ""
    echo "Regressions found: $found"

    # Return 1 when there are regressions, 0 otherwise
    if [[ $found -gt 0 ]]; then
        return 1
    fi
    return 0
}

log_verbose "Building $FORMAT report"
if [[ "$FORMAT" == "csv" ]]; then
    REPORT=$(make_csv_report)
else
    REPORT=$(make_text_report)
fi

if [[ -n "$OUTPUT" ]]; then
    echo "$REPORT" > "$OUTPUT"
    log_verbose "Report saved to $OUTPUT"
else
    echo "$REPORT"
fi

# If --compare was used, show the regression check after the report
if [[ -n "$COMPARE_FILE" ]]; then
    echo ""
    if ! compare_logs "$LOG_FILE" "$COMPARE_FILE"; then
        exit 1
    fi
fi

# Exit code: 1 if any test failed, otherwise 0
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0