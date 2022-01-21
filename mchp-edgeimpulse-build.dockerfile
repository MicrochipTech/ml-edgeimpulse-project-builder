ARG XC_NUMBER_BITS
ARG XC_VERSION

FROM mchp-xc${XC_NUMBER_BITS}:latest

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

#%% Build library
ARG MPLABX_VERSION
ARG XC_NUMBER_BITS
ARG XC_VERSION
ARG GIT_MCHP_PRJ_BUILDER="https://github.com/tjgarcia-mchp/ml-edgeimpulse-project-builder.git"
ARG PRJ_TARGET
ARG PRJ_NAME=libedgeimpulse.${PRJ_TARGET}.xc${XC_NUMBER_BITS}.${XC_VERSION}
ARG PRJ_BUILD_LIB=1
ARG PRJ_PROJECT_FILE=edgeimpulse.xc${XC_NUMBER_BITS}.project.ini
ARG PRJ_OPTIONS_FILE=edgeimpulse.xc${XC_NUMBER_BITS}.options.ini
ARG PRJ_SDK_ZIP=impulse.zip
COPY "${PRJ_SDK_ZIP}" /build/
COPY "${PRJ_PROJECT_FILE}" "${PRJ_OPTIONS_FILE}" /build/


RUN \
    cd /build/ \
    && unzip "${PRJ_SDK_ZIP}" \
    && git clone --depth 1 "${GIT_MCHP_PRJ_BUILDER}" /tmp/prjbuild \
    && mv /tmp/prjbuild/* . \
    && chmod a+x ./build.sh \
    && ./build.sh \
    && mkdir -p /dist/ \
    && mv *.a /dist/