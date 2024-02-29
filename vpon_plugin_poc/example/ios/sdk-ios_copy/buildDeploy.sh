#!/bin/sh

# run unit test

#xcodebuild test -project iphone-vpon-sdk.xcodeproj -scheme iphone-vpon-sdk -destination 'platform=iOS Simulator,OS=8.1,name=iPad 2'
#if test $? -eq 0
#then

DEBUG_PREFIX=1

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

echo "================== 腳本啟動 ==================\n"

COLOR_WHITE="\033[33;37m"
COLOR_GREEN="\033[33;32m"
COLOR_BLUE="\033[33;34m"
COLOR_YELLOW="\033[33;33m"
COLOR_RED="\033[33;31m"
COLOR_NONE="\033[0m"

# 取得Git的Hash Tag
PRE_FIX_FILE_NAME=$(git log -n 1 --pretty=format:"%h")
# 產生當下的時間
BUILD_DATE=$(date +"%y_%m_%d_%H_%M")
# 取得SDK內的Build Number
IOS_BUILD_NUMBER=$(grep "BUILD_NUMBER" ./vpon-sdk/Constant/VponConstants.swift | awk -F \" '{ print $2 }')
# 取得SDK所屬的平台
IOS_SDK_PLATFORM=$(grep "SDK_PLATFORM" ./vpon-sdk/Constant/VponConstants.swift | awk -F \" '{ print $2 }')
# 取得SDK當前的版號
IOS_SDK_VERSION=$(grep "SDK_VERSION" ./vpon-sdk/Constant/VponConstants.swift | awk -F \" '{ print $2 }')
IOS_SDK_VERSION=${IOS_SDK_VERSION#"v"}

# Log檔案名稱
LOG_NAME="Vpon_sdk_cd_logs_"$IOS_SDK_VERSION"-"$PRE_FIX_FILE_NAME"-"$BUILD_DATE""
# 壓縮檔名稱
TAR_NAME="VpadnSDKiOS-"$IOS_SDK_VERSION

if [ $DEBUG_PREFIX -eq 1 ]; then
    log "Debug mode = "$COLOR_YELLOW"On"$COLOR_NONE
else
    log "Debug mode = "$COLOR_GREEN"Off"$COLOR_NONE
fi

log "Build time = `date +"%Y-%m-%d %H:%M"`"
log "Version = $COLOR_YELLOW\"$IOS_SDK_PLATFORM$IOS_SDK_VERSION\"$COLOR_NONE\n"

debug_log "------------------------------"
debug_log "BUILD_DATE = $BUILD_DATE"
debug_log "PRE_FIX_FILE_NAME = $PRE_FIX_FILE_NAME"
debug_log "SDK_BUILD_NUMBER = $IOS_BUILD_NUMBER"
debug_log "SDK_SDK_VERSION = $IOS_SDK_VERSION"
debug_log "LOG_NAME = $LOG_NAME"
debug_log "TAR_NAME = $TAR_NAME"
debug_log "------------------------------\n"

echo "================== 部署啟動 ===================\n"

echo "1. Create File Path..."

cd ..

PODS_FOLDER=$PWD
TAR_PATH=$PODS_FOLDER/$TAR_NAME.tgz
XCFRAMEWORK_FOLDER=$PODS_FOLDER/VpadnSDKiOS-$IOS_SDK_VERSION
XCFRAMEWORK_PATH=$XCFRAMEWORK_FOLDER/VpadnSDKAdKit.xcframework

rm -rf $XCFRAMEWORK_FOLDER
mkdir -p $XCFRAMEWORK_FOLDER

cd sdk-ios

SDK_FOLDER=$PWD
LOG_PATH=$SDK_FOLDER/Logs/CD_Logs
mkdir -p $LOG_PATH

BUILD_PATH=$SDK_FOLDER/build
mkdir -p $BUILD_PATH

echo "Done!\n"

echo "2. Building VpadnSDKAdKit xcframework..."

log "Building VpadnSDKAdKit for simulators..."
xcodebuild archive \
-project "vpon-sdk.xcodeproj" \
-scheme "VpadnSDKAdKit" \
-destination "generic/platform=iOS Simulator" \
-archivePath "$BUILD_PATH/VpadnSDKAdKit-iOS-Simulator" \
VALID_ARCHS="arm64 x86_64 i386" \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES >> $LOG_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

log "Building VpadnSDKAdKit for devices..."
xcodebuild archive \
-project "vpon-sdk.xcodeproj" \
-scheme "VpadnSDKAdKit" \
-destination "generic/platform=iOS" \
-archivePath "$BUILD_PATH/VpadnSDKAdKit-iOS" \
SKIP_INSTALL=NO \
BUILD_LIBRARY_FOR_DISTRIBUTION=YES >> $LOG_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

log "Generating VpadnSDKAdKit XCFramework..."
xcodebuild -create-xcframework \
-framework $BUILD_PATH/VpadnSDKAdKit-iOS-Simulator.xcarchive/Products/Library/Frameworks/VpadnSDKAdKit.framework \
-framework $BUILD_PATH/VpadnSDKAdKit-iOS.xcarchive/Products/Library/Frameworks/VpadnSDKAdKit.framework \
-output $XCFRAMEWORK_PATH >> $LOG_PATH/$LOG_NAME.log
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "Done!\n"

echo "3. Removing temp data..."

rm -rf $BUILD_PATH
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "Done!\n"

echo "4. Packing sdk files..."

cd $PODS_FOLDER

tar -czvf $TAR_PATH VpadnSDKiOS-$IOS_SDK_VERSION | grep "error" >> $LOG_PATH/$LOG_NAME.log
if [ $? == 0 ]; then
    rm -rf $TAR_PATH
    error_log "tar: PACKING FAILED"
    exit 1
else
    log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE
fi

echo "Done!\n"

echo "5. Verifying xcodebuild result..."

log "Verifying "$COLOR_BLUE"vpadn"$COLOR_NONE" build result:"
log "Completed with $COLOR_YELLOW$(grep -ac "warning" "$LOG_PATH/$LOG_NAME.log") warnings $COLOR_RED$(grep -ac "error:/s+" "$LOG_PATH/$LOG_NAME.log") errors$COLOR_NONE"

echo "Done!\n"

echo "6. Uploading packed SDK to server..."

scp $TAR_PATH root@10.0.1.3:/var/www/html/yum/CentOS/vpon/sdk

TEMP_DIR=temp
mkdir -p $TEMP_DIR
tar -zxvf $TAR_PATH -C $TEMP_DIR
cd $TEMP_DIR
mv VpadnSDKAdKit.xcframework $TAR_NAME
zip -r $TAR_NAME.zip $TAR_NAME

#測試機 /tmp/mobile/m/stable/sdk/ios/
CDN_DIR=/xfs/mobile/m/stable/sdk/ios
ssh root@10.0.1.3 mkdir -p $CDN_DIR
scp $TAR_NAME.zip root@10.0.1.3:$CDN_DIR/$TAR_NAME.zip
ssh root@10.0.1.3 chown mi:mi $CDN_DIR/$TAR_NAME.zip
cd ..

rm -rf $TEMP_DIR

echo "Done\n"

echo "7. Removing tgz data..."

rm -rf $TAR_PATH
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "Done!\n"

echo "================= 開始部署Pods ==================\n"

echo "1. Create podspec file..."

cd $PODS_FOLDER

PODSPEC_NAME=$(basename $(find . -name *.podspec) | sed 's/.podspec//g' )
OLD_VERSION=$(awk '/\.version/' $PODSPEC_NAME.podspec | awk '/[0-9]\.[0-9]\.[0-9]/' | sed 's/.version//g'  | sed 's/[^0-9/.]//g')

debug_log "------------------------------"
debug_log "PODS_NAME = $COLOR_YELLOW$PODSPEC_NAME$COLOR_NONE"
debug_log "PODS_VERSION = $OLD_VERSION -> $COLOR_GREEN$IOS_SDK_VERSION$COLOR_NONE"
debug_log "------------------------------\n"

sed -i '' 's/'$OLD_VERSION'/'$IOS_SDK_VERSION'/g' $PODSPEC_NAME.podspec

echo "Done!\n"

echo "2. Pod library valid..."

pod lib lint --allow-warnings --verbose --skip-import-validation >> $LOG_PATH/$LOG_NAME.log

echo "Done!\n"

echo "3. Pod trunk push..."

# 此次是否直接的發布
[[ ! -z "$1" ]] && DEPLOY=$1 || DEPLOY="no"

if [ $DEPLOY = "yes" ]; 
then
    pod trunk push $PODSPEC_NAME.podspec --allow-warnings --verbose --skip-import-validation >> $LOG_PATH/$LOG_NAME.log
else
    echo "not auto deploy."
fi

echo "Done!\n"

echo "4. Removing old floder..."

rm -rf VpadnSDKiOS-$IOS_SDK_VERSION
log $COLOR_GREEN"SUCCEEDED"$COLOR_NONE

echo "Done!\n"

#else
#echo "Failed"
#fi
