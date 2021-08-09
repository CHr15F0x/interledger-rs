#! /usr/bin/env bash

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
