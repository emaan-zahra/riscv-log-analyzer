# riscv-log-analyzer

A command-line tool written in bash that reads RISC-V simulation logs and
generates summary reports.

## Installation

```bash
git clone <your-repo-url>
cd riscv-log-analyzer
make setup
```

`make setup` checks that bash, grep, awk, sed, sort, git and make are installed.

## Usage

```bash
./scripts/analyze.sh <log_file> [options]
```

| Option | Description |
|---|---|
| `--format [text\|csv]` | Output format (default: text) |
| `--output <path>` | Write the report to a file (default: screen) |
| `--verbose` | Show extra progress messages |
| `--help` | Show usage information |

Exit code is 0 if all tests pass and 1 if any test fails. Bad input exits with 2.

## Examples

```bash
./scripts/analyze.sh test_data/sample_fail.log
./scripts/analyze.sh test_data/sample_fail.log --format csv
./scripts/analyze.sh test_data/sample_fail.log --output output/report.txt
```

## Makefile targets

| Target | What it does |
|---|---|
| `make all` | Analyze all test logs |
| `make test` | Check exit codes and key results |
| `make report` | Write text and CSV reports to `output/` |
| `make clean` | Remove generated files |
| `make setup` | Check required tools |
| `make help` | List targets |

## Sample output

```
=== RISC-V Simulation Log Analysis ===
Log file: test_data/sample_fail.log

--- Results Summary ---
Total tests: 25
Passed:    22 ( 88.0%)
Failed:     2 (  8.0%)
Skipped:    1 (  4.0%)
--- Per-Test Times ---
  rv32i-add      (0.82s)
  rv32i-sub      (0.65s)

--- Failed Tests ---
  1. rv32i-sll
  2. rv32i-beq

--- Timing Statistics ---
Min time:  0.42s (rv32i-nop)
Max time:  2.31s (rv32i-mul)
Avg time:  0.87s

--- Verdict: FAIL ---
Exit code: 1
```