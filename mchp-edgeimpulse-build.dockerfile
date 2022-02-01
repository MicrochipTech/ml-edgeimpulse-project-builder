ARG XC_NUMBER_BITS
ARG XC_VERSION

FROM xc${XC_NUMBER_BITS}:latest

#%% Download DFP
ARG DFP_NAME
ARG DFP_VERSION
RUN \
    wget -qO /tmp/tmp-pack.atpack \
    https://packs.download.microchip.com/Microchip.${DFP_NAME}.${DFP_VERSION}.atpack \
    && mkdir -p /opt/microchip/mplabx/v${MPLABX_VERSION}/packs/Microchip/${DFP_NAME}/${DFP_VERSION} \
    && unzip -o /tmp/tmp-pack.atpack -d /opt/microchip/mplabx/v${MPLABX_VERSION}/packs/Microchip/${DFP_NAME}/${DFP_VERSION} \
    && rm /tmp/tmp-pack.atpack \
    && rm -rf /var/lib/apt/lists/*

ARG GIT_MCHP_PRJ_BUILDER="https://github.com/tjgarcia-mchp/ml-edgeimpulse-project-builder.git"
RUN \
    git clone --depth 1 "${GIT_MCHP_PRJ_BUILDER}" /build/ \
    && chmod a+x /build/build.sh

#%% Build library
ARG MPLABX_VERSION
ARG XC_NUMBER_BITS
ARG XC_VERSION

ARG PRJ_TARGET
ARG PRJ_NAME=libedgeimpulse.${PRJ_TARGET}.xc${XC_NUMBER_BITS}.${XC_VERSION}
ARG PRJ_BUILD_LIB=1
ARG PRJ_BUILD_AS_CPP=1
ARG PRJ_PROJECT_FILE=edgeimpulse.xc${XC_NUMBER_BITS}.project.ini
ARG PRJ_OPTIONS_FILE=edgeimpulse.xc${XC_NUMBER_BITS}.options.ini
ARG PRJ_MODEL_FOLDER=.

COPY edgeimpulse.xc${XC_NUMBER_BITS}.project.ini edgeimpulse.xc${XC_NUMBER_BITS}.options.ini /build/
COPY edge-impulse-sdk /build/edge-impulse-sdk
COPY tflite-model /build/tflite-model
COPY model-parameters /build/model-parameters

RUN \
    cd /build/ \
    && ./build.sh \
    && mkdir -p /dist/ \
    && mv \
        edge-impulse-sdk \
        tflite-model \
        model-parameters \
        *.a \
        *.X \
        /dist/ \