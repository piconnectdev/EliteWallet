#!/bin/bash

APP_ANDROID_NAME=""
APP_ANDROID_VERSION=""
APP_ANDROID_BUILD_VERSION=""
APP_ANDROID_ID=""
APP_ANDROID_PACKAGE=""

MONERO_SO="monero.so"
ELITEWALLET="elitewallet"
HAVEN="haven"
WOWNERO="wownero"

TYPES=($MONERO_SO $ELITEWALLET $HAVEN $WOWNERO)
APP_ANDROID_TYPE=$1

MONERO_SO_NAME="Monero.so"
MONERO_SO_VERSION="1.0.0"
MONERO_SO_BUILD_NUMBER=1
MONERO_SO_BUNDLE_ID="so.monero.app"
MONERO_SO_PACKAGE="so.monero.app"

ELITEWALLET_NAME="Elite Wallet"
ELITEWALLET_VERSION="1.1.0"
ELITEWALLET_BUILD_NUMBER=3
ELITEWALLET_BUNDLE_ID="sc.elitewallet.elitewallet"
ELITEWALLET_PACKAGE="sc.elitewallet.elitewallet"

HAVEN_NAME="Haven"
HAVEN_VERSION="1.0.0"
HAVEN_BUILD_NUMBER=1
HAVEN_BUNDLE_ID="sc.elitewallet.haven"
HAVEN_PACKAGE="sc.elitewallet.haven"

WOWNERO_NAME="Wownero"
WOWNERO_VERSION="1.0.0"
WOWNERO_BUILD_NUMBER=1
WOWNERO_BUNDLE_ID="sc.elitewallet.wownero"
WOWNERO_PACKAGE="sc.elitewallet.wownero"

if ! [[ " ${TYPES[*]} " =~ " ${APP_ANDROID_TYPE} " ]]; then
    echo "Wrong app type."
    return 1 2>/dev/null
    exit 1
fi

case $APP_ANDROID_TYPE in
	$MONERO_SO)
		APP_ANDROID_NAME=$MONERO_SO_NAME
		APP_ANDROID_VERSION=$MONERO_SO_VERSION
		APP_ANDROID_BUILD_NUMBER=$MONERO_SO_BUILD_NUMBER
		APP_ANDROID_BUNDLE_ID=$MONERO_SO_BUNDLE_ID
		APP_ANDROID_PACKAGE=$MONERO_SO_PACKAGE
		;;
	$ELITEWALLET)
		APP_ANDROID_NAME=$ELITEWALLET_NAME
		APP_ANDROID_VERSION=$ELITEWALLET_VERSION
		APP_ANDROID_BUILD_NUMBER=$ELITEWALLET_BUILD_NUMBER
		APP_ANDROID_BUNDLE_ID=$ELITEWALLET_BUNDLE_ID
		APP_ANDROID_PACKAGE=$ELITEWALLET_PACKAGE
		;;
	$HAVEN)
		APP_ANDROID_NAME=$HAVEN_NAME
		APP_ANDROID_VERSION=$HAVEN_VERSION
		APP_ANDROID_BUILD_NUMBER=$HAVEN_BUILD_NUMBER
		APP_ANDROID_BUNDLE_ID=$HAVEN_BUNDLE_ID
		APP_ANDROID_PACKAGE=$HAVEN_PACKAGE
		;;
	$WOWNERO)
		APP_ANDROID_NAME=$WOWNERO_NAME
		APP_ANDROID_VERSION=$WOWNERO_VERSION
		APP_ANDROID_BUILD_NUMBER=$WOWNERO_BUILD_NUMBER
		APP_ANDROID_BUNDLE_ID=$WOWNERO_BUNDLE_ID
		APP_ANDROID_PACKAGE=$WOWNERO_PACKAGE
		;;
esac

export APP_ANDROID_TYPE
export APP_ANDROID_NAME
export APP_ANDROID_VERSION
export APP_ANDROID_BUILD_NUMBER
export APP_ANDROID_BUNDLE_ID
export APP_ANDROID_PACKAGE
