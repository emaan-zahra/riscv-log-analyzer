#!/usr/bin/env bash
# setup_env.sh - check that the tools needed by the analyzer are installed
set -euo pipefail

# List of tools the project uses
TOOLS="bash grep awk sed sort git make"
MISSING=0

echo "Checking environment..."
for tool in $TOOLS; do
    # command -v finds a program; we hide its output and only use the result
    if command -v "$tool" > /dev/null 2>&1; then
        echo "  OK       $tool"
    else
        echo "  MISSING  $tool"
        MISSING=1
    fi
done

# Create the output folder if it does not exist yet
mkdir -p output

if [[ $MISSING -eq 1 ]]; then
    echo "Some tools are missing. Please install them."
    exit 1
fi
echo "Environment is ready."