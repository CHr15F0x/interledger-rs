#! /usr/bin/env bash
#
# Based on: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
#

# Convenience variables
PROJ=interledger
REPORT=${PROJ}-lcov-report
# For debugging only
DEBUG=1

# Cleanup files from previous run
find . -name "*.profraw" | xargs rm -f
rm -f ./${PROJ}.profdata
rm -f ./${REPORT}.info
rm -rf ./${REPORT}

# What happens next is a delicate matter, so:
cargo clean

# LLVM cov works only with the following
rustup default nightly
export RUSTFLAGS="-Z instrument-coverage"
# Certain test runs could overwrite each others raw prof data
# See https://clang.llvm.org/docs/SourceBasedCodeCoverage.html#id4 for expanation of %m
export LLVM_PROFILE_FILE="${PROJ}-%m.profraw"

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

[ ${DEBUG} ] && find . -name "*.profraw"

# Merge raw prof data into one
llvm-profdata merge --sparse `find . -name "*.profraw" -printf "%p "` -o ${PROJ}.profdata

# Figure out paths of all binaries ran while testing - naive way, but works
# Compare with: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html#tips-for-listing-the-binaries-automatically
# which required building the binaries first, and that forced a different build order than the original order enforced by the tests
BINS_RAW=$(find ./target/debug/ -executable -type "f" -path "*target/debug*" -not -name "*.*" -not -name "build*script*")

[ ${DEBUG} ] && echo "BINS_RAW ${BINS_RAW}"

BINS=$(for file in ${BINS_RAW}; do printf "%s %s " -object $file; done)

[ ${DEBUG} ] && echo "BINS" ${BINS}

# Do a simple summary/report, only for debugging
[ ${DEBUG} ] && llvm-cov report --use-color \
  --ignore-filename-regex='/rustc' --ignore-filename-regex='/.cargo/registry' \
  --instr-profile=${PROJ}.profdata ${BINS}

# Export prof data to a more universal format (lcov)
llvm-cov export --format=lcov -Xdemangler=rustfilt ${BINS} \
  --instr-profile=${PROJ}.profdata \
  --ignore-filename-regex='/rustc' --ignore-filename-regex='/.cargo/registry' \
  > ${REPORT}.info

# Produce a report in HTML format
genhtml \
  --output-directory ${REPORT} \
  --sort \
  --title "Interledger-rs test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  ${REPORT}.info  

# Cleanup state
rustup default stable
unset RUSTFLAGS
unset LLVM_PROFILE_FILE
