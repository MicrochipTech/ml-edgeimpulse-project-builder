FROM debian:stable-slim

# LABEL version="${XC_VERSION}.xc32.mchp"
RUN \
    apt-get update \
    && apt-get install --no-install-recommends -y \
        wget \
        procps \
        unzip \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*

#%% Download and install MPLAB X IDE
ARG MPLABX_VERSION=6.00
ENV MPLABX_VERSION=${MPLABX_VERSION}
RUN \
    wget -qO /tmp/mplabx-installer.tar "http://ww1.microchip.com/downloads/en/DeviceDoc/MPLABX-v${MPLABX_VERSION}-linux-installer.tar" \
    && tar -xvf /tmp/mplabx-installer.tar && rm /tmp/mplabx-installer.tar \
    && USER=root ./MPLABX-v${MPLABX_VERSION}-linux-installer.sh --nox11 \
    -- --unattendedmodeui none --mode unattended > /dev/null \
    && rm ./MPLABX-v${MPLABX_VERSION}-linux-installer.sh \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /opt/microchip/mplabx/v${MPLABX_VERSION}/packs/Microchip/*_DFP \
    && rm -rf /opt/microchip/mplabx/v${MPLABX_VERSION}/mplab_platform/browser-lib

#%% Download and install xc* compiler
ARG XC_VERSION=4.00
ARG XC_NUMBER_BITS=32
ARG X64_PRODUCT_STRING=-
ENV XC_NUMBER_BITS=${XC_NUMBER_BITS} XC_VERSION=${XC_VERSION}
RUN \
    wget -qO /tmp/xc"${XC_NUMBER_BITS}".run "http://ww1.microchip.com/downloads/en/DeviceDoc/xc${XC_NUMBER_BITS}-v${XC_VERSION}-full-install-linux${X64_PRODUCT_STRING}installer.run" \
    && chmod a+x /tmp/xc"${XC_NUMBER_BITS}".run \
    && /tmp/xc"${XC_NUMBER_BITS}".run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode > /dev/null \
    && rm /tmp/xc"${XC_NUMBER_BITS}".run \
    && rm -rf /var/lib/apt/lists/*

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

# ARG GIT_MCHP_PRJ_BUILDER="https://github.com/tjgarcia-mchp/ml-edgeimpulse-project-builder.git"
# RUN \
#     git clone --depth 1 "${GIT_MCHP_PRJ_BUILDER}" /build/ \
#     && chmod a+x /build/build.sh

#%% Set up image as a build executable
ENV PRJ_PROJECT_FILE=edgeimpulse.xc${XC_NUMBER_BITS}.project.ini
ENV PRJ_OPTIONS_FILE=edgeimpulse.xc${XC_NUMBER_BITS}.options.ini

COPY build.sh /build/
COPY ${PRJ_PROJECT_FILE} ${PRJ_OPTIONS_FILE} /build/
COPY src /build/src
COPY edge-impulse-sdk /build/edge-impulse-sdk
COPY tflite-model /build/tflite-model
COPY model-parameters /build/model-parameters

WORKDIR /build/
ENTRYPOINT ["./build.sh"]
CMD [""]
