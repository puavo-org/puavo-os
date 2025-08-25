#!/bin/sh
set -eu

# Zypper might be locked when the container starts, so we must wait a bit
export ZYPP_LOCK_TIMEOUT=120
zypper -n ref

# Ensure KVM device is accessible
chgrp kvm /dev/kvm || true

while ! openqa-cli api machines >/dev/null 2>&1; do
  echo 'Waiting for OpenQA to start...'
  sleep 5
done

echo 'Configuring OpenQA...'

CONFIG_DIRECTORY="/var/lib/openqa/tests/puavo/config"
PRODUCT_JSON="${CONFIG_DIRECTORY}/product.json"
MACHINE_JSON="${CONFIG_DIRECTORY}/machine.json"
TEST_SUITES_JSON="${CONFIG_DIRECTORY}/test-suites.json"
JOB_GROUP_NAME="puavo"
JOB_GROUP_CONFIG_FILE="${CONFIG_DIRECTORY}/job-group.yaml"

machines_count=$(openqa-cli api machines | jq -r '.Machines | length' || echo 0)
if [ "$machines_count" = "0" ]; then
  echo "Creating machine from $MACHINE_JSON"
  openqa-cli api --data-file "$MACHINE_JSON" --json -X POST machines
fi

products_count=$(openqa-cli api products | jq -r '.Products | length' || echo 0)
if [ "$products_count" = "0" ]; then
  PRODUCT_NAME=$(jq -r '.name' "$PRODUCT_JSON")
  echo "Creating product $PRODUCT_NAME"
  openqa-cli api --data-file "$PRODUCT_JSON" --json -X POST products
fi

test_suite_count=$(openqa-cli api test_suites \
                    | jq -r '.TestSuites | length' || echo 0)
if [ "$test_suite_count" = "0" ]; then
  echo "Creating test suites from $TEST_SUITES_JSON"
  jq -c '.[]' "$TEST_SUITES_JSON" | while read -r test_suite; do
    temporary_test_suite=$(mktemp)
    printf '%s' "$test_suite" > "$temporary_test_suite"
    openqa-cli api \
      --data-file "$temporary_test_suite" \
      --json -X POST test_suites
    rm -f "$temporary_test_suite"
  done
fi

job_groups_count=$(openqa-cli api job_groups | jq length || echo 0)
if [ "$job_groups_count" = "0" ]; then
  echo "Creating job group ${JOB_GROUP_NAME}"
  job_group_id=$(openqa-cli api -X POST job_groups name="$JOB_GROUP_NAME" \
                  | jq -r '.id')

  echo "Applying config to job group $JOB_GROUP_NAME"
  openqa-cli api \
    -X POST job_templates_scheduling/${job_group_id} \
    schema=JobTemplates-01.yaml \
    template="$(cat "$JOB_GROUP_CONFIG_FILE")"
fi

# Install required packages
zypper -n install -y ffmpeg jq swtpm

