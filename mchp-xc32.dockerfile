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
ENV MPLABX_VERSION=6.00
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
ENV XC_VERSION=4.00
ENV XC_NUMBER_BITS=32
ARG X64_PRODUCT_STRING=-
RUN \
    wget -qO /tmp/xc"${XC_NUMBER_BITS}".run "http://ww1.microchip.com/downloads/en/DeviceDoc/xc${XC_NUMBER_BITS}-v${XC_VERSION}-full-install-linux${X64_PRODUCT_STRING}installer.run" \
    && chmod a+x /tmp/xc"${XC_NUMBER_BITS}".run \
    && /tmp/xc"${XC_NUMBER_BITS}".run --mode unattended --unattendedmodeui none \
        --netservername localhost --LicenseType FreeMode > /dev/null \
    && rm /tmp/xc"${XC_NUMBER_BITS}".run \
    && rm -rf /var/lib/apt/lists/*
