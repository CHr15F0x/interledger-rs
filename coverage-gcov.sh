#! /usr/bin/env bash
#
# Based on: https://github.com/mozilla/grcov
#

# Convenience variables
REPORT=coverage-gcc-lcov
# Uncomment for debug
# DEBUG=1

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
rustup default nightly
export CARGO_INCREMENTAL=0
export RUSTFLAGS="-Zprofile -Ccodegen-units=1 -Copt-level=0 -Clink-dead-code -Coverflow-checks=off -Zpanic_abort_tests -Cpanic=abort"
export RUSTDOCFLAGS="-Cpanic=abort"

# Run the tests 
source run-all-tests.sh

[ ${DEBUG} ] && find . -name "*.gcno"
[ ${DEBUG} ] && find . -name "*.gcda"

# --ignore-errors gcov,source,graph
# version '408*', prefer 'A93*'
# geninfo: WARNING: GCOV failed for /home/k/projects/interledger-rs/target/debug/deps/hyper-bfaa07ba5bd2fe8b.gcda!
# Processing deps/openssl_sys-10dd1e75ebc1ffe8.gcda
# /home/k/projects/interledger-rs/target/debug/deps/openssl_sys-10dd1e75ebc1ffe8.gcno:version '408*', prefer 'A93*'lcov --directory ./target/debug --capture --output-file ${REPORT}-0.info
#
# sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 1 
# sudo update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-7 1 

lcov --directory ./target/debug --capture --output-file ${REPORT}-0.info

lcov --extract ${REPORT}-0.info "*interledger-rs*" -o ${REPORT}-1.info

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
rustup default stable
unset CARGO_INCREMENTAL
unset RUSTFLAGS
unset RUSTDOCFLAGS
