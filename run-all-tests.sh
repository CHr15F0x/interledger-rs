#! /usr/bin/env bash

cargo clean

# LLVM cov works only with the following
export RUSTFLAGS="-Z instrument-coverage"
rustup default nightly

# Find where the binaries are
TARGETS=$( \
      for file in \
        $( \
          RUSTFLAGS="-Z instrument-coverage" \
            cargo test --all --all-features --no-run --message-format=json \
              | jq -r "select(.profile.test == true) | .filenames[]" \
              | grep -v dSYM - \
        ); \
      do \
        printf "%s %s " -object $file; \
      done \
    )

# debug..
# echo ${TARGETS}

# Test steps from .github/workflows/ci.yml
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
# test-md:
# - name: Test
scripts/run-md-test.sh '^.*$' 1

rustup default stable
unset RUSTFLAGS
