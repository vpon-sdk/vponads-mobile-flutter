#!/bin/sh

# run unit test

#xcodebuild test -project iphone-vpon-sdk.xcodeproj -scheme iphone-vpon-sdk -destination 'platform=iOS Simulator,OS=8.1,name=iPad 2'
#if test $? -eq 0
#then

DEBUG_PREFIX=0

function loading {
    sleep 1s
    echo ".\c"
}

function echo()
{
    builtin echo -e "$1"
}

function debug_log()
{
    if [ $DEBUG_PREFIX -eq 1 ]; then
        echo "[DEBUG] $1"
    fi
}

function log()
{
    echo "$COLOR_WHITE[ LOG ]$COLOR_NONE $1"
}

function error_log()
{
    echo "$COLOR_RED[ERROR] $1"
    echo "Build failed!$COLOR_NONE"
    exit 1
}

function check_error()
{
    # check log with grep error exists
    grep "error:\s+" "$ARCHIVE_PATH/$LOG_NAME.log"
    if [ $? == 0 ]; then
        error_log "$1"
    exit 1
    else
        log "$2"
    fi
}

# build lib
# set -ex
echo "================== Script begin ==================\n"

COLOR_WHITE="\033[33;37m"
COLOR_GREEN="\033[33;32m"
COLOR_BLUE="\033[33;34m"
COLOR_YELLOW="\033[33;33m"
COLOR_RED="\033[33;31m"
COLOR_NONE="\033[0m"

if [ $DEBUG_PREFIX -eq 1 ]; then
    log "Debug mode = "$COLOR_YELLOW"On"$COLOR_NONE
else
    log "Debug mode = "$COLOR_GREEN"Off"$COLOR_NONE
fi

OUTPUT_PATH=$WORKSPACE/artifacts
[ -z $OUTPUT_PATH ] || OUTPUT_PATH=$PWD/sdk_archive

rm -rf $OUTPUT_PATH
mkdir -p $OUTPUT_PATH

ARCHIVE_PATH=$OUTPUT_PATH/archive
HEADERS_PATH=$ARCHIVE_PATH/Headers
XCFRAMEWORK_PATH=$ARCHIVE_PATH/VpadnSDKAdKit.xcframework
BUILD_PATH=$PWD/build

mkdir -p $ARCHIVE_PATH
mkdir -p $HEADERS_PATH

PRE_FIX_FILE_NAME=$(git log -n 1 --pretty=format:"%h")
BUILD_DATE=$(date +"%y%m%d%H%M")
IOS_BUILD_NUMBER=$(grep "BUILD_NUMBER" ./vpon-sdk/Constant/VponConstants.swift | awk -F \" '{ print $2 }')
IOS_SDK_PLATFORM=$(grep "SDK_PLATFORM" ./vpon-sdk/Constant/VponConstants.swift | awk -F \" '{ print $2 }')
IOS_SDK_VERSION=$(grep "SDK_VERSION" ./vpon-sdk/Constant/VponConstants.swift | awk -F \" '{ print $2 }')
OUTPUT_LIB_NAME="ios-vpadn-sdk-"$IOS_SDK_VERSION"-"$IOS_BUILD_NUMBER"-"$BUILD_DATE"-"$PRE_FIX_FILE_NAME
TAR_NAME="i-sdk-"$BUILD_DATE"-"$IOS_SDK_VERSION"-"$IOS_BUILD_NUMBER"-"$PRE_FIX_FILE_NAME
LOG_NAME="vpadn-sdk-build-"$IOS_SDK_VERSION"-"$IOS_BUILD_NUMBER"-"$BUILD_DATE"-"$PRE_FIX_FILE_NAME

log "Build time = `date +"%Y-%m-%d %H:%M"`"
log "Version = $COLOR_YELLOW\"$IOS_SDK_PLATFORM$IOS_SDK_VERSION\"$COLOR_YELLOW"
log "Output folder = \"$OUTPUT_PATH/\"\n"

echo "================== Build vpadn ===================\n"

debug_log "------------------------------"
debug_log "PROJ = $PROJ"
debug_log "BUILD_DATE = $BUILD_DATE"
debug_log "PRE_FIX_FILE_NAME = $PRE_FIX_FILE_NAME"
debug_log "IOS_BUILD_NUMBER = $IOS_BUILD_NUMBER"
debug_log "IOS_SDK_VERSION = $IOS_SDK_VERSION"
debug_log "OUTPUT_LIB_NAME = $OUTPUT_LIB_NAME"
debug_log "LOG_NAME = $LOG_NAME"
debug_log "TAR_NAME = $TAR_NAME"
debug_log "------------------------------\n"

#==================================
# build vpadn
#==================================
echo "1. Building VponADN library..."

log "Building VponADN for simulators..."
xcodebuild -target VponADN clean >> $ARCHIVE_PATH/$LOG_NAME.log
xcodebuild -target VponADN -configuration Release -sdk iphonesimulator build >> $ARCHIVE_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

log "Building VponADN for devices..."
#xcodebuild -target VponADN clean >> $ARCHIVE_PATH/$LOG_NAME.log
xcodebuild -target VponADN -configuration Release -sdk iphoneos build >> $ARCHIVE_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

log "Generating VponADN library..."

# copy headers to output folder
cp -R $BUILD_PATH/Release-iphoneos/include/* $ARCHIVE_PATH/Headers/

# lipo default outputs nothing
lipo -create $BUILD_PATH/Release-iphoneos/libVponADN.a $BUILD_PATH/Release-iphonesimulator/libVponADN.a -output $ARCHIVE_PATH/$OUTPUT_LIB_NAME.a >> $ARCHIVE_PATH/$LOG_NAME.log 2>&1
check_error "lipo: Library GENERATE FAILED!" $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "Done!\n"

echo "2. Building VpadnSDKAdKit framework"

log "Building VpadnSDKAdKit for simulators..."
xcodebuild archive \
-project "vpon-sdk.xcodeproj" \
-scheme "VpadnSDKAdKit" \
-destination "generic/platform=iOS Simulator" \
-archivePath "sdk_archive/VpadnSDKAdKit-iOS-Simulator" \
VALID_ARCHS="arm64 x86_64 i386" \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES >> $ARCHIVE_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

log "Building VpadnSDKAdKit for devices..."
xcodebuild archive \
-project "vpon-sdk.xcodeproj" \
-scheme "VpadnSDKAdKit" \
-destination "generic/platform=iOS" \
-archivePath "sdk_archive/VpadnSDKAdKit-iOS" \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES >> $ARCHIVE_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

log "Generating VpadnSDKAdKit XCFramework..."
xcodebuild -create-xcframework \
-framework $OUTPUT_PATH/VpadnSDKAdKit-iOS-Simulator.xcarchive/Products/Library/Frameworks/VpadnSDKAdKit.framework \
-framework $OUTPUT_PATH/VpadnSDKAdKit-iOS.xcarchive/Products/Library/Frameworks/VpadnSDKAdKit.framework \
-output $XCFRAMEWORK_PATH >> $ARCHIVE_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "3. Removing temp data..."
rm -rf $BUILD_PATH
rm -rf $OUTPUT_PATH/VpadnSDKAdKit-iOS-Simulator.xcarchive
rm -rf $OUTPUT_PATH/VpadnSDKAdKit-iOS.xcarchive
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "Done!\n"

echo "============= Processing final steps =============\n"

echo "1. Packing sdk files..."

tar czvf ./sdk_archive/$TAR_NAME.tar.gz --directory="./sdk_archive/archive/" . | grep "error"
if [ $? == 0 ]; then
    rm -rf $OUTPUT_PATH/$TAR_NAME.tar.gz
    error_log "tar: PACKING FAILED"
    exit 1
else
    log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE
fi

echo "Done!\n"

echo "2. Verifying xcodebuild result..."

log "Verifying "$COLOR_BLUE"vpadn"$COLOR_NONE" build result:"
log "Completed with $COLOR_YELLOW$(grep -ac "warning" "$ARCHIVE_PATH/$LOG_NAME.log") warnings $COLOR_RED$(grep -ac "error:/s+" "$ARCHIVE_PATH/$LOG_NAME.log") errors$COLOR_NONE"

echo "Done!\n"

echo "3. Uploading packed SDK to server..."

scp $OUTPUT_PATH/$TAR_NAME.tar.gz root@10.0.1.3:/var/www/html/yum/CentOS/vpon/sdk

echo "Done\n"

echo "================= End of script =================="
#==================================

#else
#echo "Failed"
#fi
