#! /usr/bin/env bash

# --TESTS BEGIN--
#
# Tests to run, steps taken from .github/workflows/ci.yml
#
# build:
# - name: Test
cargo +nightly test --all --all-features
# - name: Test with subset of features (interledger-packet)
cargo +nightly test -p interledger-packet
cargo +nightly test -p interledger-packet --features strict
cargo +nightly test -p interledger-packet --features roundtrip-only
# - name: Test with subset of features (interledger-btp)
cargo +nightly test -p interledger-btp
cargo +nightly test -p interledger-btp --features strict
# - name: Test with subset of features (interledger-stream)
cargo +nightly test -p interledger-stream
cargo +nightly test -p interledger-stream --features strict
cargo +nightly test -p interledger-stream --features roundtrip-only

echo "!!! test-md internally requires sudo, please enter your password: !!!"
sudo -v

# test-md:
# - name: Test
# TODO fix the nightly hack
rustup default nightly
scripts/run-md-test.sh '^.*$' 1
rustup default stable
#
# --TESTS END--
