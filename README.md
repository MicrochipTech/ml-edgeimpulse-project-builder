# Edge Impulse Project Builder
This repository contains a shell script for creating either a library object or
a template mplab X project from an edge impulse C++ source code deployment. This
script should work for any xc32 supported platform.

Notes:
- This script has only been tested under linux, [Git Bash](https://gitforwindows.org/), and macOS.
- `*.options.ini` can be modified to set additional project options; for help
  call `prjMakefilesGenerator -setoptions=@ -help`
  + NB: all relative paths are considered relative to the project root folder
- `*.project.ini` is just a placeholder - the **languageToolchain** and **device**
  variables are replaced when building the project

## Software Used
* MPLAB® X IDE *>=6.00* (https://microchip.com/mplab/mplab-x-ide)

## Instructions
1. Download edge impulse c++ source archive and extract into this folder
2. Modify the following variables in build.sh or by setting environment variables:
   - **PRJ_NAME** **DEVICE** **MPLAB_PATH** **XC_PATH**
3. Run build.sh

