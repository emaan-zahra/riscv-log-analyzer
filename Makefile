# Makefile for riscv-log-analyzer

SCRIPT = scripts/analyze.sh
LOGS = test_data/sample_sim.log test_data/sample_pass.log test_data/sample_fail.log

.PHONY: help setup all clean test report
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

	# Run the analyzer on every test log (a failing log is expected, so we
# put a "-" before the command to tell make not to stop on exit code 1)
all:
	@for log in $(LOGS); do \
		echo ">>> Analyzing $$log"; \
		./$(SCRIPT) $$log || true; \
		echo ""; \
	done

# Remove everything generated in output/ (but keep .gitkeep)
clean:
	@find output -type f ! -name '.gitkeep' -delete
	@echo "Cleaned output/"