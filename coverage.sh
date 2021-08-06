#! /usr/bin/env bash
#
# Based on: https://doc.rust-lang.org/beta/unstable-book/compiler-flags/instrument-coverage.html
#

# Cleanup previous run
find . -name "*.profraw" | xargs rm
rm ./all.profdata
rm cov-report-*.info
rm -r llvm-cov-report

cargo clean

# LLVM cov works only with the following
export RUSTFLAGS="-Z instrument-coverage"
rustup default nightly

# Find where the binaries are
# 
# TODO or
# cargo test --tests
# cargo build --all-features --all-targets
#
# TARGETS1=$( \
#       for file in \
#         $( \
#           RUSTFLAGS="-Z instrument-coverage" \
#             cargo test --all --all-features --no-run --message-format=json \
#               | jq -r "select(.profile.test == true) | .filenames[]" \
#               | grep -v dSYM - \
#         ); \
#       do \
#         printf "%s %s " -object $file; \
#       done \
#     )

# # debug..
# echo "TEST ALL TARGETS\n" ${TARGETS1}

# TARGETS2=$( \
#       for file in \
#         $( \
#           RUSTFLAGS="-Z instrument-coverage" \
#             cargo build --all-targets --all-features --message-format=json \
#               | jq -r "select(.profile.test == true) | .filenames[]" \
#               | grep -v dSYM - \
#         ); \
#       do \
#         printf "%s %s " -object $file; \
#       done \
#     )

# # debug..
# echo "BUILD ALL TARGETS\n" ${TARGETS2}

# # Test steps from .github/workflows/ci.yml
# # build:
# # - name: Test
# cargo test --all --all-features
# # - name: Test with subset of features (interledger-packet)
# cargo test -p interledger-packet
# cargo test -p interledger-packet --features strict
# cargo test -p interledger-packet --features roundtrip-only
# # - name: Test with subset of features (interledger-btp)
cargo test -p interledger-btp
# cargo test -p interledger-btp --features strict
# # - name: Test with subset of features (interledger-stream)
cargo test -p interledger-stream
# cargo test -p interledger-stream --features strict
# cargo test -p interledger-stream --features roundtrip-only
# test-md:
# - name: Test
# scripts/run-md-test.sh '^.*$' 1

# Merge all the raw data gathered
llvm-profdata merge --sparse `find . -name "*.profraw" -printf "%p "` -o all.profdata

# llvm-cov report \
#     $( \
#       for file in \
#         $( \
#           RUSTFLAGS="-Z instrument-coverage" \
#             cargo test --tests --no-run --message-format=json \
#               | jq -r "select(.profile.test == true) | .filenames[]" \
#               | grep -v dSYM - \
#         ); \
#       do \
#         printf "%s %s " -object $file; \
#       done \
#     ) \
#     --instr-profile all.profdata --summary-only

# llvm-cov show --format=lcov -Xdemangler=rustfilt ${TARGETS} \
#     -instr-profile=all.profdata \
#     -show-line-counts-or-regions \
#     -show-instantiations > cov-report.lcov

TARGETS=$( \
      for file in \
        $(find ./target/debug/ -executable -type "f" -path "*target/debug*" -not -name "*.*" -not -name "build*script*"); \
      do \
        printf "%s %s " -object $file; \
      done \
    )

echo "TARGETS" ${TARGETS}

llvm-cov report \
  ${TARGETS} \
  --instr-profile all.profdata --summary-only

# Export it to a more universal format
llvm-cov export --format=lcov -Xdemangler=rustfilt ${TARGETS} \
    --instr-profile=all.profdata \
    --show-branch-summary \
    --show-region-summary > cov-report-all.info

# Ignore coverage data for external dependencies
lcov --extract cov-report-all.info '*interledger*' -o cov-report-interledger.info

# ADD_CUSTOM_COMMAND(OUTPUT ${AM_COVERAGE_GENHTML_INDEX_THIRD_PARTY}
#     COMMAND genhtml --output-directory "coverage/third_party" --demangle-cpp --num-spaces 2
#         --sort --title "ProtoGW Coverage - third party code only" --function-coverage --no-prefix
#         --legend ${AM_COVERAGE_INFO_FILE_THIRD_PARTY}

# Produce a report in HTML format
genhtml \
  --output-directory llvm-cov-report \
  --sort \
  --title "Interledger-rs test coverage report" \
  --function-coverage \
  --prefix $(readlink -f "${PWD}/..") \
  --show-details \
  --legend \
  cov-report-interledger.info  

rustup default stable
unset RUSTFLAGS

find . -name "*.profraw"
