#!/bin/sh
set -ex

# Command to generate args file for latest DFP versions by scraping
# packs.microchip.com
# python get_dfps.py | xargs -n2 sh -c 'echo -e "DFP_NAME=${0}_DFP\nDFP_VERSION=${1}" | tee args/${0}.args'
# for f in args/AVR* args/AT* args/PIC1* args/PIC-* args/XMEGA*; do echo XC_NUMBER_BITS=8 >> $f; done
# for f in args/SAM* args/PIC32*; do echo XC_NUMBER_BITS=32 >> $f; done
# for f in args/PIC24* args/dsPIC*; do echo XC_NUMBER_BITS=16 >> $f; done

# Input args
PRJ_TARGET=${1}
PRJ_ARGS_FILE="${2}"
: ${PRJ_BUILD_LIB:=1}

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <target-name> [<project-args-file>]"
    exit 1
fi

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
    --env-file "${PRJ_ARGS_FILE}" \
    -e PRJ_BUILD_LIB="${PRJ_BUILD_LIB}" \
    "${PRJ_NAME}" \
    "${PRJ_TARGET}" "${PRJ_NAME}" /dist