# Makefile for riscv-log-analyzer

SCRIPT = scripts/analyze.sh
LOGS = test_data/sample_sim.log test_data/sample_pass.log test_data/sample_fail.log

.PHONY: help setup

# Show all available targets
help:
	@echo "Available targets:"
	@echo "  all     - Run the analyzer on all test logs"
	@echo "  test    - Check the analyzer gives the expected results"
	@echo "  report  - Generate a summary report in output/"
	@echo "  clean   - Remove generated files from output/"
	@echo "  setup   - Check that required tools are installed"
	@echo "  help    - Show this message"

# Check that the tools we need are installed
setup:
	@echo "Checking required tools..."
	@for tool in bash grep awk sed sort git make; do \
		if command -v $$tool > /dev/null 2>&1; then \
			echo "  OK       $$tool"; \
		else \
			echo "  MISSING  $$tool"; exit 1; \
		fi; \
	done
	@echo "All tools found."