#! /usr/bin/env bash
#
# Based on: https://github.com/mozilla/grcov
#

# Convenience variables
REPORT=coverage-llvm-grcov

function partial_cleanup() {
  find . -name "*.profraw" | xargs rm -f
  rm -f ./${REPORT}.info
  rm -f ./${REPORT}-lcov.info
}

# Cleanup files from previous run
# Just in case there are leftovers
partial_cleanup
rm -rf ./${REPORT}

# What happens next is a delicate matter, so:
cargo clean

# LLVM cov works only with the following
export RUSTFLAGS="-Z instrument-coverage"
# Certain test runs could overwrite each others raw prof data
# See https://clang.llvm.org/docs/SourceBasedCodeCoverage.html#id4 for explanation of %p and %m 
export LLVM_PROFILE_FILE="cov-%p-%m.profraw"

# Run the tests
source run-all-tests.sh

# Use grcov's html generation capability
grcov . -s . --binary-path ./target/debug/ --llvm -t html --ignore-not-existing --ignore '*/rustc*' --ignore '*/.cargo/registry*' -o ./${REPORT}

# Use lcov's genhtml
grcov . -s . --binary-path ./target/debug/ --llvm -t lcov --ignore-not-existing --ignore '*/rustc*' --ignore '*/.cargo/registry*' -o ./${REPORT}-lcov.info

# Produce a report in HTML format
genhtml \
  --output-directory ${REPORT}-lcov \
  --sort \
  --title "Interledger-rs test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  --highlight \
  --ignore-errors source \
  ${REPORT}-lcov.info

# # Partial cleanup files from this run, at least the most prolific ones
partial_cleanup

# Cleanup state
unset RUSTFLAGS
unset LLVM_PROFILE_FILE
