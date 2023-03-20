#!/bin/sh

export IOS_SCRIPTS_DIR=`pwd`
export EW_ROOT=${IOS_SCRIPTS_DIR}/../..
export EXTERNAL_DIR=${EW_ROOT}/ew_shared_external/ios/External
export EXTERNAL_IOS_DIR=${EXTERNAL_DIR}/ios
export EXTERNAL_IOS_SOURCE_DIR=${EXTERNAL_IOS_DIR}/sources
export EXTERNAL_IOS_LIB_DIR=${EXTERNAL_IOS_DIR}/lib
export EXTERNAL_IOS_INCLUDE_DIR=${EXTERNAL_IOS_DIR}/include
export ELITEWALLET_DATA_DIR=~/elite_wallet_data
export LOCAL_GIT_REPOS=${ELITEWALLET_DATA_DIR}/repos
export LOCAL_GIT_DEPS=${ELITEWALLET_DATA_DIR}/deps
export BUILD_TYPE="release"
export LOCAL_GIT_DEPS_SUBDIR=${LOCAL_GIT_DEPS}/${BUILD_TYPE}
export LAST_DEPS_CHANGE_GITHASH="fcd1a9"
export CURRENT_DEPS=${LOCAL_GIT_DEPS_SUBDIR}/${LAST_DEPS_CHANGE_GITHASH}

mkdir -p $EXTERNAL_IOS_LIB_DIR
mkdir -p $EXTERNAL_IOS_INCLUDE_DIR
mkdir -p $ELITEWALLET_DATA_DIR
mkdir -p $LOCAL_GIT_REPOS
mkdir -p $LOCAL_GIT_DEPS
mkdir -p $LOCAL_GIT_DEPS_SUBDIR
