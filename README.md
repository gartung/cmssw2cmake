# cmssw2cmake
This repository contains scripts to convert cms-sw/cmssw build rules (which are based on cms-sw/SCRAM) in to CMAKE. In order to use these , you need to
- Login to a machine with cms env e.g. lxplus  cmsdev machines at CERN
- clone this repository: git clone htts://github.com/cms-sw/cmssw2cmake
- Run the script `cmssw2cmake.sh` and pass it a CMSSW release which is already installed.
```
  ./cmssw2cmake/cmssw2cmake.sh CMSSW_10_2_0_pre1
  cd CMSSW_10_2_0_pre1
  cmsenv
  mkdir build
  cd build
  cmake ../src
  gmake -k -j $(nproc) VERBOSE=1
```
