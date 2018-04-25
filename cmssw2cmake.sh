#!/bin/bash -e
SCRIPT_DIR=$(dirname $0)
if [ $(echo "${SCRIPT_DIR}" | grep '^/' | wc -l) -eq 0 ] ; then SCRIPT_DIR=$(/bin/pwd)/${SCRIPT_DIR} ; fi

REL=$1
if [ "X${REL}" = "X" ] ; then
  echo "Error: Missing release version"
  exit 1
fi
if [ ! -d $REL ] ; then
  scram p $REL  
  cd $REL
  scram setup ${SCRIPT_DIR}/cmake.xml
  ARCH=$(ls -d .SCRAM/slc* | sed 's|.*/||')
  mv .SCRAM/${ARCH}/Environment .SCRAM/${ARCH}/Environment.xx
  scram setup self
  scram setup
  rm -rf src
  git clone --reference /cvmfs/cms-ib.cern.ch/git/cms-sw/cmssw.git git@github.com:cms-sw/cmssw src
  (cd src;  git checkout $REL)
  sed -i -e 's|name="GeneratorInterfaceCascadeInterface"|name="GeneratorInterfaceCascadeInterfacePlugin"|' src/GeneratorInterface/CascadeInterface/plugins/BuildFile.xml
  sed -i -e 's|name="ValidationRecoMET"|name="ValidationRecoMETPlugin"|' src/Validation/RecoMET/plugins/BuildFile.xml
  mv src/BigProducts .
  scram build disable-biglib
  scram build -r echo_CXX
  eval `scram run -sh`
  $SCRIPT_DIR/scram2cmake.pl
fi

