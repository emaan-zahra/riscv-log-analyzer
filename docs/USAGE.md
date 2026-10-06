# Usage Guide

## Command

```
./scripts/analyze.sh <log_file> [--format text|csv] [--output <path>] [--verbose] [--help]
```

## Arguments

- `<log_file>`: required. Path to a simulation log.
- `--format`: `text` (default) or `csv`.
- `--output <path>`: save the report to a file instead of printing it.
- `--verbose`: print progress messages to stderr.
- `--help`: print usage and exit.
- `--compare <file>`: second log; lists tests that passed in `<log_file>` but fail in `<file>`. Exits 1 if any regression is found.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | All tests passed |
| 1 | At least one test failed |
| 2 | Bad usage (missing file, unknown option, invalid format) |

## Log format

```
[2026-05-01 10:23:46] TEST PASS: rv32i-add (0.82s)
[2026-05-01 10:23:48] TEST FAIL: rv32i-sll (1.02s)
[2026-05-01 10:23:48] TEST SKIP: rv32i-srl (not supported)
```

Skipped tests have no time, so they are left out of the timing statistics.

## CSV output

One `metric,value` row each for: log_file, total, passed, failed, skipped,
pass_rate, failed_tests (separated by `;`), min_time, min_test, max_time,
max_test, avg_time.

## Make targets

Run `make help` for the list. `make report` writes `.txt` and `.csv` reports
for every test log into `output/`, which Git ignores.

## Troubleshooting

- `File not found`: check the path, and run from the project root.
- `missing separator` when running make: Makefile recipe lines need a Tab.