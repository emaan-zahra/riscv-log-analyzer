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

echo "Analyzing $LOG_FILE ..."