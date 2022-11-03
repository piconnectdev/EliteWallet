#!/bin/sh

. ./config.sh

cd $EXTERNAL_IOS_LIB_DIR

LIBRANDOMX_PATH=${EXTERNAL_IOS_LIB_DIR}/monero/librandomx.a

if [ -f "$LIBRANDOMX_PATH" ]; then
    cp $LIBRANDOMX_PATH ./haven
    cp $LIBRANDOMX_PATH ./wownero
fi

libtool -static -o libboost.a ./libboost_*.a
libtool -static -o libhaven.a ./haven/*.a
libtool -static -o libwownero.a ./wownero/*.a
libtool -static -o libmonero.a ./monero/*.a

CW_HAVEN_EXTERNAL_LIB=../../../../../cw_haven/ios/External/ios/lib
CW_HAVEN_EXTERNAL_INCLUDE=../../../../../cw_haven/ios/External/ios/include
CW_WOWNERO_EXTERNAL_LIB=../../../../../cw_wownero/ios/External/ios/lib
CW_WOWNERO_EXTERNAL_INCLUDE=../../../../../cw_wownero/ios/External/ios/include
CW_MONERO_EXTERNAL_LIB=../../../../../cw_monero/ios/External/ios/lib
CW_MONERO_EXTERNAL_INCLUDE=../../../../../cw_monero/ios/External/ios/include

mkdir -p $CW_HAVEN_EXTERNAL_INCLUDE
mkdir -p $CW_WOWNERO_EXTERNAL_INCLUDE
mkdir -p $CW_MONERO_EXTERNAL_INCLUDE
mkdir -p $CW_HAVEN_EXTERNAL_LIB
mkdir -p $CW_WOWNERO_EXTERNAL_LIB
mkdir -p $CW_MONERO_EXTERNAL_LIB

ln -f ./libboost.a ${CW_HAVEN_EXTERNAL_LIB}/libboost.a
ln -f ./libcrypto.a ${CW_HAVEN_EXTERNAL_LIB}/libcrypto.a
ln -f ./libssl.a ${CW_HAVEN_EXTERNAL_LIB}/libssl.a
ln -f ./libsodium.a ${CW_HAVEN_EXTERNAL_LIB}/libsodium.a
cp ./libhaven.a $CW_HAVEN_EXTERNAL_LIB
cp ../include/haven/* $CW_HAVEN_EXTERNAL_INCLUDE

ln -f ./libboost.a ${CW_WOWNERO_EXTERNAL_LIB}/libboost.a
ln -f ./libcrypto.a ${CW_WOWNERO_EXTERNAL_LIB}/libcrypto.a
ln -f ./libssl.a ${CW_WOWNERO_EXTERNAL_LIB}/libssl.a
ln -f ./libsodium.a ${CW_WOWNERO_EXTERNAL_LIB}/libsodium.a
cp ./libwownero.a $CW_WOWNERO_EXTERNAL_LIB
cp ../include/wownero/* $CW_WOWNERO_EXTERNAL_INCLUDE
ln -f ./libwownero-seed.a ${CW_WOWNERO_EXTERNAL_LIB}/libwownero-seed.a
cp -R ../include/wownero_seed $CW_WOWNERO_EXTERNAL_INCLUDE

ln -f ./libboost.a ${CW_MONERO_EXTERNAL_LIB}/libboost.a
ln -f ./libcrypto.a ${CW_MONERO_EXTERNAL_LIB}/libcrypto.a
ln -f ./libssl.a ${CW_MONERO_EXTERNAL_LIB}/libssl.a
ln -f ./libsodium.a ${CW_MONERO_EXTERNAL_LIB}/libsodium.a
ln -f ./libunbound.a ${CW_MONERO_EXTERNAL_LIB}/libunbound.a
cp ./libmonero.a $CW_MONERO_EXTERNAL_LIB
cp ../include/monero/* $CW_MONERO_EXTERNAL_INCLUDE