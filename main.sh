#!/usr/bin/env bash

ROOT_PATH="${PWD}"
# Download scenarios
echo "Downloading scenarios..."
aws s3 sync s3://${S3_SCENARIO_PATH} "${ROOT_PATH}/scenarios/"

if [ -z "${TARGET_URL}" ]; then
  echo "ERROR: TARGET_URL not configured" >&2
  exit 1
fi

LOCUSTFILE_PATH="${ROOT_PATH}/scenarios/locustfile.py"

LOCUST_MODE="${LOCUST_MODE:=standalone}"
LOCUST_OPTS="-f ${LOCUSTFILE_PATH} -H ${TARGET_URL}"
LOCUST_HATCH_RATE="$((LOCUST_USER_COUNT/10))"

if [ "${LOCUST_MODE}" = "master" ] && [ "${LOCUST_NO_WEB}" = "true" ]; then
    LOCUST_OUTPUT_PREFIX=`date +"%Y%m%d%H%M%S"`
    RESULT_PATH="${ROOT_PATH}/results/${LOCUST_OUTPUT_PREFIX}"
    S3_RESULT_PATH="${S3_RESULT_PATH}/${LOCUST_OUTPUT_PREFIX}"
fi

LIB_FILE="${ROOT_PATH}/scenarios/requirements.txt"
if test -f "$LIB_FILE"; then
    pip install -r $LIB_FILE
fi

# Run Locust distributed
if [ "${LOCUST_MODE}" = "master" ]; then
    LOCUST_OPTS="${LOCUST_OPTS} --master"
    if [ "${LOCUST_NO_WEB}" = "true" ]; then
        echo "$ mkdir -p ${RESULT_PATH}"
        mkdir -p "${RESULT_PATH}"
        LOCUST_OPTS="${LOCUST_OPTS} --no-web -c ${LOCUST_USER_COUNT} -r ${LOCUST_HATCH_RATE} --run-time ${LOCUST_RUN_TIME} --csv=${RESULT_PATH}/result"
    fi
elif [ "${LOCUST_MODE}" = "slave" ]; then
    if [ -z "${LOCUST_MASTER_HOST}" ]; then
        echo "ERROR: MASTER_HOST is empty. Slave mode requires a master" >&2
        exit 1
    fi

    LOCUST_OPTS="${LOCUST_OPTS} --slave --master-host=${LOCUST_MASTER_HOST} --master-port=${LOCUST_MASTER_PORT:-5557}"
fi

echo "Starting Locust..."
echo "$ locust ${LOCUST_OPTS}"

locust ${LOCUST_OPTS}

if [ "${LOCUST_MODE}" = "master" ] && [ "${LOCUST_NO_WEB}" = "true" ] && [ -n ${LOCUST_OUTPUT_PREFIX} ]; then
    echo "Output result CSV to ${RESULT_PATH}:"
    cat "${RESULT_PATH}/result_requests.csv"
    cat "${RESULT_PATH}/result_distribution.csv"
    echo "Uploading results to S3 ${S3_RESULT_PATH}..."
    echo aws s3 sync "${RESULT_PATH}" "s3://${S3_RESULT_PATH}"
    aws s3 sync "${RESULT_PATH}" "s3://${S3_RESULT_PATH}"
fi
