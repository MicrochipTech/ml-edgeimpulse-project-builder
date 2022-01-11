#!/bin/sh
set -ex

#%% Setup
: ${PRJ_NAME:=edgeimpulse}
: ${DEVICE:=ATSAME54P20A}

: ${BUILD_LIB:=0}
: ${CMSIS_NN:=0}
: ${CMSIS_DSP:=0}

if [ $OS = "Windows_NT" ]; then
    : "${MPLAB_PATH:=$PROGRAMFILES/Microchip/MPLABX/v6.00/mplab_platform/bin}"
    : "${XC32_PATH:=$PROGRAMFILES/Microchip/xc32/v3.00/bin}"
elif [ $(uname) = "Darwin" ]; then
    : "${MPLAB_PATH:=/Applications/microchip/mplabx/v6.00/mplab_platform/bin}"
    : "${XC32_PATH:=/Applications/microchip/xc32/v3.00/bin}"
else
    : "${MPLAB_PATH:=/opt/microchip/mplabx/v6.00/mplab_platform/bin}"
    : "${XC32_PATH:=/opt/microchip/xc32/v3.00/bin}"
fi

if [ $OS = "Windows_NT" ]; then
    PRJMAKEFILESGENERATOR="${MPLAB_PATH}/prjMakefilesGenerator.bat"
    MAKE="$MPLAB_PATH/../../gnuBins/GnuWin32/bin/make.exe"
    # Get around space in path issues with windows
    XC32_PATH=$(cygpath -d "$XC32_PATH")
else
    PRJMAKEFILESGENERATOR="${MPLAB_PATH}/prjMakefilesGenerator.sh"
    MAKE="$MPLAB_PATH/make"
fi

# Base configuration files
PROJECT_INI_FILE=project.ini
OPTIONS_INI_FILE=options.ini

#%% Build up list of source files
SOURCE_LIST_TMP=.sources.txt
rm -f $SOURCE_LIST_TMP

if [ $BUILD_LIB -eq 0 ]; then
    # Add generic implementation files
    printf '%s\n' \
        src/main.cpp \
        src/ei_porting.cpp \
    >> ${SOURCE_LIST_TMP}
fi

# This list is directly pulled from here:
# https://github.com/edgeimpulse/example-standalone-inferencing/blob/master/Makefile
# edge-impulse-sdk/dsp/kissfft/*.cpp \
printf '%s\n' \
    tflite-model/ \
    model-parameters/ \
    edge-impulse-sdk/dsp/dct/*.cpp \
    edge-impulse-sdk/dsp/memory.cpp \
    edge-impulse-sdk/tensorflow/lite/kernels/*.cc \
    edge-impulse-sdk/tensorflow/lite/kernels/internal/*.cc \
    edge-impulse-sdk/tensorflow/lite/micro/kernels/*.cc \
    edge-impulse-sdk/tensorflow/lite/micro/*.cc \
    edge-impulse-sdk/tensorflow/lite/micro/memory_planner/*.cc \
    edge-impulse-sdk/tensorflow/lite/core/api/*.cc \
    edge-impulse-sdk/tensorflow/lite/c/common.c \
>> ${SOURCE_LIST_TMP}

if [ $CMSIS_NN -eq 1 ]; then
    printf '%s\n' \
        edge-impulse-sdk/CMSIS/NN/Source/ActivationFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/BasicMathFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/ConcatenationFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/ConvolutionFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/FullyConnectedFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/NNSupportFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/PoolingFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/ReshapeFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/SoftmaxFunctions/*.c \
        edge-impulse-sdk/CMSIS/NN/Source/SVDFunctions/*.c \
    >> ${SOURCE_LIST_TMP}
fi
if [ $CMSIS_DSP -eq 1 ]; then
    printf '%s\n' \
        edge-impulse-sdk/CMSIS/DSP/Source/MatrixFunctions/*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/BasicMathFunctions/*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/FastMathFunctions/*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/StatisticsFunctions/*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/*fft*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/CommonTables/*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/*bit*.c \
        edge-impulse-sdk/CMSIS/DSP/Source/SupportFunctions/*.c \
    >> ${SOURCE_LIST_TMP}
fi

# Make paths relative to project dir
echo "$(cat ${SOURCE_LIST_TMP} | awk '{print "../" $0}')" > ${SOURCE_LIST_TMP}

#%% Create project
rm -rf ${PRJ_NAME}.X
"$PRJMAKEFILESGENERATOR" -create=@${PROJECT_INI_FILE} ${PRJ_NAME}.X@default \
    -compilers=${XC32_PATH} \
    -device=${DEVICE}

# Change project to library type (3) manually
if [ $BUILD_LIB -ne 0 ]; then
    echo "$(cat ${PRJ_NAME}.X/nbproject/configurations.xml | sed 's|\(<conf name="default" type="\)[0-9]\+|\13|g')" > ${PRJ_NAME}.X/nbproject/configurations.xml
fi

#%% Set project configuration
OPTIONS_INI_TMP=.options.ini
rm -f $OPTIONS_INI_TMP

cat >> ${OPTIONS_INI_TMP} << EOF
C32Global,common-include-directories="../;../edge-impulse-sdk/CMSIS/NN/Include/;../edge-impulse-sdk/CMSIS/DSP/PrivateInclude/"
EOF
cat ${OPTIONS_INI_FILE} >> ${OPTIONS_INI_TMP}

"$PRJMAKEFILESGENERATOR" -setoptions=@${OPTIONS_INI_TMP} ${PRJ_NAME}.X@default

#%% Add files
"$PRJMAKEFILESGENERATOR" -setitems ${PRJ_NAME}.X@default \
    -pathmode=relative \
    -files=@${SOURCE_LIST_TMP}

#%% Finalize project
if [ $BUILD_LIB -ne 0 ]; then
    cd ${PRJ_NAME}.X
    "$MAKE"
    cp $(find . -name "${PRJ_NAME}.X.a") ../${PRJ_NAME}.a
fi