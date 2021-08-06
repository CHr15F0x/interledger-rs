#! /usr/bin/env bash
#
# Based on: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
#

# Cleanup previous run
find . -name "*.profraw" | xargs rm
rm ./all.profdata

cargo clean

# LLVM cov works only with the following
export RUSTFLAGS="-Z instrument-coverage"
rustup default nightly

# Interledger 'build' step tests
cargo test --all --all-features
# Interledger 'test-md' step tests
scripts/run-md-test.sh '^.*$' 1

llvm-profdata merge --sparse `find . -name "*.profraw" -printf "%p "` -o all.profdata

llvm-cov report \
    $( \
      for file in \
        $( \
          RUSTFLAGS="-Z instrument-coverage" \
            cargo test --tests --no-run --message-format=json \
              | jq -r "select(.profile.test == true) | .filenames[]" \
              | grep -v dSYM - \
        ); \
      do \
        printf "%s %s " -object $file; \
      done \
    ) \
    --instr-profile all.profdata --summary-only

rustup default stable
unset RUSTFLAGS

find . -name "*.profraw"
