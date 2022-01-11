#!/usr/bin/env bash
set -ex
: ${BUILD_LIB:=0}
: ${PRJ_NAME:=edgeimpulse}
: ${DEVICE:=ATSAME54P20A}

if [ $OS == "Windows_NT" ]; then
    : ${MPLAB_PATH:="$PROGRAMFILES/Microchip/MPLABX/v6.00/mplab_platform/bin"}
    : ${XC32_PATH:="$PROGRAMFILES/Microchip/xc32/v3.00/bin"}
elif [ $(uname) == "Darwin" ]; then
    : ${MPLAB_PATH:=/Applications/microchip/mplabx/v6.00/mplab_platform/bin}
    : ${XC32_PATH:=/Applications/microchip/xc32/v3.00/bin}
else
    : ${MPLAB_PATH:=/opt/microchip/mplabx/v6.00/mplab_platform/bin}
    : ${XC32_PATH:=/opt/microchip/xc32/v3.00/bin}
fi

if [ $OS == "Windows_NT" ]; then
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

# Build up list of source files
SOURCE_LIST_TMP=.sources.txt

if [ $BUILD_LIB -eq 0 ]; then
    printf '%s\n' \
        src/main.cpp \
        src/ei_porting.cpp \
    > ${SOURCE_LIST_TMP}
fi

# This list is directly pulled from here:
# https://github.com/edgeimpulse/example-standalone-inferencing/blob/master/Makefile
printf '%s\n' \
    edge-impulse-sdk/tensorflow/lite/c/common.c \
    `find edge-impulse-sdk/CMSIS/DSP/Source/MatrixFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/BasicMathFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/FastMathFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/StatisticsFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/ -maxdepth 1 -type f -name '*fft*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/CommonTables/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/ -maxdepth 1 -type f -name '*bit*.c'` \
    `find tflite-model/ -maxdepth 1 -type f -name '*.cpp'` \
    `find edge-impulse-sdk/dsp/kissfft/ -maxdepth 1 -type f -name '*.cpp'` \
    `find edge-impulse-sdk/dsp/dct/ -maxdepth 1 -type f -name '*.cpp'` \
    edge-impulse-sdk/dsp/memory.cpp \
    `find edge-impulse-sdk/tensorflow/lite/kernels/ -maxdepth 1 -type f -name '*.cpp'` \
    `find edge-impulse-sdk/tensorflow/lite/kernels/internal/ -maxdepth 1 -type f -name '*.cc'` \
    `find edge-impulse-sdk/tensorflow/lite/micro/kernels/ -maxdepth 1 -type f -name '*.cc'` \
    `find edge-impulse-sdk/tensorflow/lite/micro/ -maxdepth 1 -type f -name '*.cc'` \
    `find edge-impulse-sdk/tensorflow/lite/micro/memory_planner/ -maxdepth 1 -type f -name '*.cc'` \
    `find edge-impulse-sdk/tensorflow/lite/core/api/ -maxdepth 1 -type f -name '*.cc'` \
> ${SOURCE_LIST_TMP}

# Make paths relative to project dir
echo "$(cat ${SOURCE_LIST_TMP} | awk '{print "../" $0}')" > ${SOURCE_LIST_TMP}

# Create project
rm -rf ${PRJ_NAME}.X
"$PRJMAKEFILESGENERATOR" -create=@${PROJECT_INI_FILE} ${PRJ_NAME}.X@default \
    -compilers=${XC32_PATH} \
    -device=${DEVICE}

# Change project to library type (3) manually
if [ $BUILD_LIB -ne 0 ]; then
    echo "$(cat ${PRJ_NAME}.X/nbproject/configurations.xml | sed 's|\(<conf name="default" type="\)[0-9]\+|\13|g')" > ${PRJ_NAME}.X/nbproject/configurations.xml
fi

# Set project configuration
OPTIONS_INI_TMP=.options.ini
cat > ${OPTIONS_INI_TMP} << EOF
C32Global,common-include-directories="../;../edge-impulse-sdk/CMSIS/NN/Include/;../edge-impulse-sdk/CMSIS/DSP/PrivateInclude/"
EOF
cat ${OPTIONS_INI_FILE} >> ${OPTIONS_INI_TMP}
"$PRJMAKEFILESGENERATOR" -setoptions=@${OPTIONS_INI_TMP} ${PRJ_NAME}.X@default

# Add files
"$PRJMAKEFILESGENERATOR" -setitems ${PRJ_NAME}.X@default \
    -pathmode=relative \
    -files=@${SOURCE_LIST_TMP}

# Finalize project
if [ $BUILD_LIB -ne 0 ]; then
    cd ${PRJ_NAME}.X
    "$MAKE"
    cp $(find . -name "${PRJ_NAME}.X.a") ../${PRJ_NAME}.a
fi