NAME=libedgeimpulse
DEVICE=ATSAME54P20A
MPLAB_PATH=/opt/microchip/mplabx/v6.00/mplab_platform/bin/
XC32_PATH=/opt/microchip/xc32/v3.01/bin/

# Build up list of source files
printf '%s\n' \
    edge-impulse-sdk/tensorflow/lite/c/common.c \
    edge-impulse-sdk/dsp/memory.cpp \
    `find edge-impulse-sdk/CMSIS/DSP/Source/BasicMathFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/FastMathFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/StatisticsFunctions/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/ -maxdepth 1 -type f -name '*fft*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/CommonTables/ -maxdepth 1 -type f -name '*.c'` \
    `find edge-impulse-sdk/CMSIS/DSP/Source/TransformFunctions/ -maxdepth 1 -type f -name '*bit*.c'` \
    `find tflite-model/ -maxdepth 1 -type f -name '*.cpp'` \
    `find edge-impulse-sdk/dsp/kissfft/ -maxdepth 1 -type f -name '*.cpp'` \
    `find edge-impulse-sdk/dsp/dct/ -maxdepth 1 -type f -name '*.cpp'` \
> .sources.txt

# Make paths relative to project dir
awk -i inplace '{print "../" $0}' .sources.txt

# Create project
rm -rf ${NAME}.X
${MPLAB_PATH}/prjMakefilesGenerator.sh -create=@project.ini ${NAME}.X@default \
    -compilers="${XC32_PATH}" \
    -device=${DEVICE}

# Change project to library type (3)
sed -i 's|\(<conf name="default" type="\)[0-9]\+|\13|g' ${NAME}.X/nbproject/configurations.xml

# Set project configuration
cp options.ini .options.ini
cat >> .options.ini << EOF
C32Global,common-include-directories="../;../edge-impulse-sdk/CMSIS/NN/Include/;../edge-impulse-sdk/CMSIS/DSP/PrivateInclude/"
EOF
${MPLAB_PATH}/prjMakefilesGenerator.sh -setoptions=@.options.ini ${NAME}.X@default

# Add files
${MPLAB_PATH}/prjMakefilesGenerator.sh -setitems ${NAME}.X@default \
    -pathmode=relative \
    -files=@.sources.txt

# Finalize project
cd ${NAME}.X
${MPLAB_PATH}/make
cp $(find . -name "${NAME}.X.a") ../${NAME}.a