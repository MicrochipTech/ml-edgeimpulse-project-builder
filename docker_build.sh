#!/bin/sh
set -ex

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <target-name> <project-args-file>"
    exit 1
fi

# Input args
PRJ_TARGET=${1}
PRJ_ARGS_FILE=${2}
: ${PRJ_BUILD_LIB:=1}
PRJ_NAME=$(basename "${PRJ_ARGS_FILE%.*}" | tr [:upper:] [:lower:])

# Source build args
. "${PRJ_ARGS_FILE}"

# Check required build args
test -n "${XC_NUMBER_BITS}"
test -n "${DFP_NAME}"
test -n "${DFP_VERSION}"

docker build . \
    -f Dockerfile \
    -t "${PRJ_NAME}" \
    $(cat "${PRJ_ARGS_FILE}" | awk '{print "--build-arg " $0}' )

mkdir -p dist
rm -rf dist/*

# Git Bash screws up paths when running docker, disabled with MSYS_NO_PATHCONV=1
MSYS_NO_PATHCONV=1 docker run \
    --rm \
    -v "$(pwd)"/dist:/dist \
    -e PRJ_BUILD_LIB="${PRJ_BUILD_LIB}" \
    --env-file "${PRJ_ARGS_FILE}" \
    "${PRJ_NAME}" \
    "${PRJ_TARGET}" "${PRJ_NAME}" /dist