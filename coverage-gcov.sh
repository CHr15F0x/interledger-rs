#! /usr/bin/env bash
#
# Based on: https://github.com/mozilla/grcov
#

# Convenience variables
REPORT=coverage-gcov-lcov

function partial_cleanup() {
  find . -name "*.gcno" | xargs rm -f
  find . -name "*.gcda" | xargs rm -f
  rm -f ./${REPORT}*.info
}

# Cleanup files from previous run
# Just in case there are leftovers
partial_cleanup
rm -rf ./${REPORT}

# What happens next is a delicate matter, so:
cargo clean

# Required to use the gcov format (*.gcno, *.gcda)
export CARGO_INCREMENTAL=0
export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort"
export RUSTDOCFLAGS="-Cpanic=abort"

# Run the tests 
source run-all-tests.sh

lcov --directory ./target/debug --capture --output-file ${REPORT}-0.info

lcov --extract ${REPORT}-0.info "*$(basename ${PWD})*" -o ${REPORT}-1.info

# Produce a report in HTML format
genhtml \
  --output-directory ${REPORT} \
  --sort \
  --title "Interledger-rs test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  --highlight \
  --ignore-errors source \
  ${REPORT}-1.info

# Partial cleanup files from this run, at least the most prolific ones
partial_cleanup

# Cleanup state
unset CARGO_INCREMENTAL
unset RUSTFLAGS
unset RUSTDOCFLAGS
