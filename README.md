# Edge Impulse library builder
This repository contains a shell script for creating a library object from an edge
impulse C++ source code deployment. This script should work for any xc32 supported
platform.

Notes:
- This script has only been tested under linux.
- options.ini can be modified to set additional project options; to see
  available project options call `prjMakefilesGenerator.sh -setoptions=@ -help`
- project.ini is just a placeholder - the **languageToolchain*** and **device**
  variables are replaced when building the project

## Software Used
* MPLAB® X IDE *>=6.00* (https://microchip.com/mplab/mplab-x-ide)

## Instructions
1. Download edge impulse c++ source archive and extract into this folder
2. Open build.sh
3. Modify the following variables as desired: **DEVICE** **MPLAB_PATH** **XC32_PATH**
4. Run build.sh
5. Link libedgeimpulse.a into your MPLAB X project.

