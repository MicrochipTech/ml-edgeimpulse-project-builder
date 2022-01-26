#!/bin/sh
set -ex

#%% Environment
: ${XC_NUMBER_BITS:=32}
: ${XC_VERSION:=3.00}
: ${MPLABX_VERSION:=6.00}

#%% Build options
: ${PRJ_TARGET:=ATSAME54P20A}
: ${PRJ_CMSIS_NN:=1}
: ${PRJ_CMSIS_DSP:=1}
: ${PRJ_BUILD_LIB:=1}
: ${PRJ_PROJECT_FILE:=edgeimpulse.xc${XC_NUMBER_BITS}.project.ini}
: ${PRJ_OPTIONS_FILE:=edgeimpulse.xc${XC_NUMBER_BITS}.options.ini}
: ${PRJ_MODEL_FOLDER:=impulse}

: ${PRJ_NAME:=edgeimpulse.${PRJ_TARGET}.xc${XC_NUMBER_BITS}.${XC_VERSION}}
#%% Tool paths
if [ "${OS}" = "Windows_NT" ]; then
    : "${MPLABX_PATH:=$PROGRAMFILES/Microchip/MPLABX/v${MPLABX_VERSION}/mplab_platform/bin}"
    : "${XC_PATH:=$PROGRAMFILES/Microchip/xc${XC_NUMBER_BITS}/v${XC_VERSION}/bin}"
elif [ "$(uname)" = "Darwin" ]; then
    : "${MPLABX_PATH:=/Applications/microchip/mplabx/v${MPLABX_VERSION}/mplab_platform/bin}"
    : "${XC_PATH:=/Applications/microchip/xc${XC_NUMBER_BITS}/v${XC_VERSION}/bin}"
else
    : "${MPLABX_PATH:=/opt/microchip/mplabx/v${MPLABX_VERSION}/mplab_platform/bin}"
    : "${XC_PATH:=/opt/microchip/xc${XC_NUMBER_BITS}/v${XC_VERSION}/bin}"
fi

if [ "${OS}" = "Windows_NT" ]; then
    PRJMAKEFILESGENERATOR="${MPLABX_PATH}/prjMakefilesGenerator.bat"
    MAKE="${MPLABX_PATH}/../../gnuBins/GnuWin32/bin/make.exe"
    # Get around space in path issues with windows
    XC_PATH=$(cygpath -d "${XC_PATH}")
else
    PRJMAKEFILESGENERATOR="${MPLABX_PATH}/prjMakefilesGenerator.sh"
    MAKE="${MPLABX_PATH}/make"
fi

#%% Build up list of source files
SOURCE_LIST_FILE=."${PRJ_NAME}".sources.txt
rm -f "${SOURCE_LIST_FILE}"

set +x
if [ "${PRJ_BUILD_LIB}" -eq 0 ]; then
    # Add generic implementation files
    printf '%s\n' \
        src/main.cpp \
        src/ei_porting.cpp \
    >> "${SOURCE_LIST_FILE}"
fi

# This list is directly pulled from here:
# https://github.com/edgeimpulse/example-standalone-inferencing/blob/master/Makefile
printf '%s\n' \
    "${PRJ_MODEL_FOLDER}"/tflite-model/ \
    "${PRJ_MODEL_FOLDER}"/model-parameters/ \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/dsp/kissfft/*.cpp \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/dsp/dct/*.cpp \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/dsp/memory.cpp \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/kernels/*.cc \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/kernels/internal/*.cc \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/micro/kernels/*.cc \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/micro/*.cc \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/micro/memory_planner/*.cc \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/core/api/*.cc \
    "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/tensorflow/lite/c/common.c \
>> "${SOURCE_LIST_FILE}"

if [ "$PRJ_CMSIS_NN" -eq 1 ]; then
    printf '%s\n' \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/ActivationFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/BasicMathFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/ConcatenationFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/ConvolutionFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/FullyConnectedFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/NNSupportFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/PoolingFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/ReshapeFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/SoftmaxFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/NN/Source/SVDFunctions/*.c \
    >> "${SOURCE_LIST_FILE}"
fi
if [ "$PRJ_CMSIS_DSP" -eq 1 ]; then
    printf '%s\n' \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/MatrixFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/BasicMathFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/FastMathFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/StatisticsFunctions/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/*fft*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/CommonTables/*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/*bit*.c \
        "${PRJ_MODEL_FOLDER}"/edge-impulse-sdk/CMSIS/DSP/Source/SupportFunctions/*.c \
    >> "${SOURCE_LIST_FILE}"
fi
set -x

# (Make paths relative to project dir)
echo "$(cat ${SOURCE_LIST_FILE} | awk '{print "../" $0}')" > "${SOURCE_LIST_FILE}"

#%% Create project
rm -rf ${PRJ_NAME}.X
"${PRJMAKEFILESGENERATOR}" -create=@"${PRJ_PROJECT_FILE}" "${PRJ_NAME}".X@default \
    -compilers="${XC_PATH}" \
    -device="${PRJ_TARGET}"

# (Change project to library type (3) manually)
if [ "${PRJ_BUILD_LIB}" -ne 0 ]; then
    echo "$(cat ${PRJ_NAME}.X/nbproject/configurations.xml | sed 's|\(<conf name="default" type="\)[0-9]\+|\13|g')" > "${PRJ_NAME}".X/nbproject/configurations.xml
fi

#%% Set project configuration
"${PRJMAKEFILESGENERATOR}" -setoptions=@"${PRJ_OPTIONS_FILE}" "${PRJ_NAME}".X@default

#%% Add files
"${PRJMAKEFILESGENERATOR}" -setitems "${PRJ_NAME}".X@default \
    -pathmode=relative \
    -files=@"${SOURCE_LIST_FILE}"

#%% Finalize project
if [ "${PRJ_BUILD_LIB}" -ne 0 ]; then
    cd "${PRJ_NAME}".X
    "${MAKE}"
    cp $(find . -name "${PRJ_NAME}.X.a") ../"${PRJ_NAME}".a
fi
