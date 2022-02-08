#!/bin/sh
set -ex

: ${PRJ_TARGET:=ATSAMD21G18A}
: ${BUILD_ARGS_FILE:=./SAMD21.args}
: ${PRJ_BUILD_LIB:=1}

IMAGE_TAG=$(basename ${BUILD_ARGS_FILE%.*} | tr [:upper:] [:lower:])
docker build . \
    -f mchp-edgeimpulse-build.dockerfile \
    -t $IMAGE_TAG \
    $(cat ${BUILD_ARGS_FILE} | awk '{print "--build-arg " $0}' )

mkdir -p dist
rm -rf dist/*

# Git Bash screws up paths when running docker, disabled with MSYS_NO_PATHCONV=1
MSYS_NO_PATHCONV=1 docker run \
    --rm \
    -v "$(pwd)"/dist:/dist \
    -e PRJ_BUILD_LIB=$PRJ_BUILD_LIB \
    $IMAGE_TAG \
    $PRJ_TARGET edge-impulse-template /dist