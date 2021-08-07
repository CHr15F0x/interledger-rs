#! /usr/bin/env bash
#
# Based on: https://github.com/mozilla/grcov
#

# Convenience variables
PROJ=interledger
REPORT=${PROJ}-gcov-lcov-report
REPORT_ALL=${REPORT}-all
# Uncomment for debug
DEBUG=1

# Cleanup files from previous run
find . -name "*.gcno" | xargs rm -f
find . -name "*.gcda" | xargs rm -f
rm -f ./${REPORT}.info
rm -rf ./${REPORT}

# What happens next is a delicate matter, so:
cargo clean

rustup default nightly
export CARGO_INCREMENTAL=0
export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort"
export RUSTDOCFLAGS="-Cpanic=abort"

# --TESTS BEGIN--
#
# Tests to run, steps taken from .github/workflows/ci.yml
#
# build:
# - name: Test
cargo test --all --all-features
# - name: Test with subset of features (interledger-packet)
cargo test -p interledger-packet
cargo test -p interledger-packet --features strict
cargo test -p interledger-packet --features roundtrip-only
# - name: Test with subset of features (interledger-btp)
cargo test -p interledger-btp
cargo test -p interledger-btp --features strict
# - name: Test with subset of features (interledger-stream)
cargo test -p interledger-stream
cargo test -p interledger-stream --features strict
cargo test -p interledger-stream --features roundtrip-only

echo "!!! test-md internally requires sudo, please enter your password: !!!"
sudo -v

# test-md:
# - name: Test
scripts/run-md-test.sh '^.*$' 1
#
# --TESTS END--

[ ${DEBUG} ] && find . -name "*.gcno"
[ ${DEBUG} ] && find . -name "*.gcda"

lcov --directory ./target/debug --capture --output-file ${REPORT_ALL}.info

lcov --extract ${REPORT_ALL}.info "*interledger*" -o ${REPORT}.info

# Produce a report in HTML format
genhtml \
  --output-directory ${REPORT} \
  --sort \
  --title "GCOV Interledger-rs test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  ${REPORT}.info  

# Cleanup state
unset CARGO_INCREMENTAL
unset RUSTFLAGS
unset RUSTDOCFLAGS
