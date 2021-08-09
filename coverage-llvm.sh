#! /usr/bin/env bash
#
# Based on: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
#

# Convenience variables
REPORT=coverage-llvm-lcov
PROJ=interledger
# Uncomment for debug
# DEBUG=1

function partial_cleanup() {
  find . -name "*.profraw" | xargs rm -f
  rm -f ./${PROJ}.profdata
  rm -f ./${REPORT}.info
}

# Cleanup files from previous run
# Just in case there are leftovers
partial_cleanup
rm -rf ./${REPORT}

# What happens next is a delicate matter, so:
cargo clean

# LLVM cov works only with the following
rustup default nightly
export RUSTFLAGS="-Z instrument-coverage"
# Certain test runs could overwrite each others raw prof data
# See https://clang.llvm.org/docs/SourceBasedCodeCoverage.html#id4 for explanation of %p and %m 
export LLVM_PROFILE_FILE="${PROJ}-%p-%m.profraw"

# Run the tests
source run-all-tests.sh

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
  --highlight \
  --ignore-errors source \
  ${REPORT}.info  

# Partial cleanup files from this run, at least the most prolific ones
partial_cleanup

# Cleanup state
rustup default stable
unset RUSTFLAGS
unset LLVM_PROFILE_FILE
