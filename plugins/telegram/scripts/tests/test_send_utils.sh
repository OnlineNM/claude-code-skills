#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

. "$SCRIPT_DIR/../telegram-utils.sh"

# validate_config
validate_config "123456:AbC-DeF_123" "12345"; assert_true "validate_config accepts numeric chat_id" $?
validate_config "123456:AbC-DeF_123" "@my_channel"; assert_true "validate_config accepts @channel chat_id" $?
validate_config "not-a-token" "12345"; assert_false "validate_config rejects bad token" $?
validate_config "123456:AbC-DeF_123" "not valid"; assert_false "validate_config rejects bad chat_id" $?

# sanitize_message
raw=$'line one\tstill line one\x01\x02\nline two'
clean="$(sanitize_message "$raw")"
case "$clean" in
  *$'\n'*) assert_true "sanitize_message preserves newlines" 0 ;;
  *) assert_true "sanitize_message preserves newlines" 1 ;;
esac
long=$(printf 'a%.0s' $(seq 1 5000))
truncated="$(sanitize_message "$long")"
assert_eq "4096" "${#truncated}" "sanitize_message truncates to MAX_MESSAGE_LENGTH"
assert_eq "..." "${truncated: -3}" "sanitize_message appends ellipsis on truncation"

# check_dependencies passes in a normal dev environment
check_dependencies; assert_true "check_dependencies passes when tools present" $?

# send_telegram_message: success on first attempt
setup_fake_curl
send_telegram_message "111:tok" "222" "hello"
assert_true "send_telegram_message succeeds on 200+ok:true" $?
assert_eq "1" "$(fake_curl_call_count)" "send_telegram_message makes exactly 1 call on success"
teardown_fake_curl

# send_telegram_message: exhausts MAX_RETRIES on persistent failure
setup_fake_curl
export FAKE_CURL_HTTP_CODE=401 FAKE_CURL_OK=false
send_telegram_message "111:tok" "222" "hello"
assert_false "send_telegram_message fails after exhausting retries" $?
assert_eq "$MAX_RETRIES" "$(fake_curl_call_count)" "send_telegram_message retries exactly MAX_RETRIES times"
unset FAKE_CURL_HTTP_CODE FAKE_CURL_OK
teardown_fake_curl

rm -rf "$TEST_HOME"
test_summary
exit $?
