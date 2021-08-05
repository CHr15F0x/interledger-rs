#! /usr/bin/env bash

# sudo apt-get update
# sudo apt-get install -y redis-server redis-tools libssl-dev
# sudo npm install -g ganache-cli ilp-settlement-xrp conventional-changelog-cli

# rustup toolchain install nightly
# NO rustup component add llvm-tools-preview
# cargo install rustfilt
# cargo install cargo-binutils
# sudo apt install llvm-12

find . -name "*.profraw" | xargs rm
rm ./all.profdata

cargo clean

export RUSTFLAGS="-Z instrument-coverage"
rustup default nightly

cargo test --all --all-features

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
