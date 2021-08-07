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

# # --TESTS BEGIN--
# #
# # Tests to run, steps taken from .github/workflows/ci.yml
# #
# # build:
# # - name: Test
# cargo test --all --all-features
# # - name: Test with subset of features (interledger-packet)
# cargo test -p interledger-packet
# cargo test -p interledger-packet --features strict
# cargo test -p interledger-packet --features roundtrip-only
# # - name: Test with subset of features (interledger-btp)
# cargo test -p interledger-btp
# cargo test -p interledger-btp --features strict
# # - name: Test with subset of features (interledger-stream)
# cargo test -p interledger-stream
# cargo test -p interledger-stream --features strict
# cargo test -p interledger-stream --features roundtrip-only

echo "!!! test-md internally requires sudo, please enter your password: !!!"
sudo -v

# test-md:
# - name: Test
scripts/run-md-test.sh '^.*$' 1
#
# --TESTS END--

[ ${DEBUG} ] && find . -name "*.gcno"
[ ${DEBUG} ] && find . -name "*.gcda"

# # Building lcov-info-file using gcov data generated after running tests
# ADD_CUSTOM_COMMAND(OUTPUT ${AM_COVERAGE_INFO_FILE}
#     COMMAND lcov --directory ${PROJECT_BINARY_DIR} --capture --output-file ${AM_COVERAGE_INFO_FILE}
#     DEPENDS coverage_test
#     COMMENT "Building coverage info file")

lcov --directory ./target/debug --capture --output-file ${REPORT_ALL}.info

lcov --extract ${REPORT_ALL}.info "*interledger*" -o ${REPORT}.info

# # Filtering out useless and third party data from the lcov info file
# ADD_CUSTOM_COMMAND(OUTPUT ${AM_COVERAGE_INFO_FILE_OUR_CODE}
#     COMMAND lcov --remove ${AM_COVERAGE_INFO_FILE}
#         '/opt/*'
#         '/usr/*'
#         '*build*'
#         '*third_party*'
#         -o ${AM_COVERAGE_INFO_FILE_OUR_CODE}
#     DEPENDS ${AM_COVERAGE_INFO_FILE}
#     COMMENT "Filtering coverage info file (removing third party)")

# # Generating HTML report using lcov info file (our code, excluding third_party)
# ADD_CUSTOM_COMMAND(OUTPUT ${AM_COVERAGE_GENHTML_INDEX_OUR_CODE}
#     COMMAND genhtml --output-directory "coverage/our_code" --demangle-cpp --num-spaces 2
#         --sort --title "ProtoGw Coverage - AM code only" --function-coverage --no-prefix
#         --legend ${AM_COVERAGE_INFO_FILE_OUR_CODE}
#     DEPENDS ${AM_COVERAGE_INFO_FILE_OUR_CODE}
#     COMMENT "Generating HTML report (excluding third_party)")

# # Filtering everything but the third party data from the lcov file
# ADD_CUSTOM_COMMAND(OUTPUT ${AM_COVERAGE_INFO_FILE_THIRD_PARTY}
#     COMMAND lcov --extract ${AM_COVERAGE_INFO_FILE}
#         '*third_party*'
#         -o ${AM_COVERAGE_INFO_FILE_THIRD_PARTY}
#     DEPENDS ${AM_COVERAGE_INFO_FILE}
#     COMMENT "Filtering coverage info file (leaving third party only)")

# # Generating HTML report using lcov info file (third_party only)
# ADD_CUSTOM_COMMAND(OUTPUT ${AM_COVERAGE_GENHTML_INDEX_THIRD_PARTY}
#     COMMAND genhtml --output-directory "coverage/third_party" --demangle-cpp --num-spaces 2
#         --sort --title "ProtoGW Coverage - third party code only" --function-coverage --no-prefix
#         --legend ${AM_COVERAGE_INFO_FILE_THIRD_PARTY}
#     DEPENDS ${AM_COVERAGE_INFO_FILE_THIRD_PARTY}
#     COMMENT "Generating HTML report (excluding third_party)")

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
