#!/bin/bash

# react-native 打包脚本

# 安装包类型
PACKAGES=''
# 是否打渠道包
CHANNEL=false
# bundle 包类型
BUNDLE=''
# 打包环境
EVN=''
# 是否打安装包
BUILD_PACKAGES=false

buildBothBundle() {
  buildAndroidBundle
  buildIOSBundle
}

buildAndroidBundle() {
  rm -rf temp
  mkdir temp

  # build android bundle
  react-native bundle --platform android --dev false --entry-file index.js \
    --bundle-output temp/index.android.bundle --assets-dest temp

  cd temp
  zip -rmgq bundleAnd.zip ./
  mv bundleAnd.zip ../packages/
  cd ..
  rm -rf temp
}

buildIOSBundle() {
  rm -rf temp
  mkdir temp

  # build ios bundle
  react-native bundle --platform ios --dev false --entry-file index.js \
    --bundle-output temp/main.jsbundle --assets-dest temp

  cd temp
  zip -rmgq bundleiOS.zip ./
  mv bundleiOS.zip ../packages/
  cd ..
  rm -rf temp
}

buildBundle() {
  if [[ $BUNDLE = 'android' ]]; then
    buildAndroidBundle
  elif [[ $BUNDLE = 'ios' ]]; then
    buildIOSBundle
  else
    buildBothBundle
  fi
}

buildTestBundle() {
  cp -rf src/config/test.js src/config/index.js

  buildBundle
}

buildReleaseBundle() {
  cp -rf src/config/release.js src/config/index.js

  buildBundle
}

buildApk() {
  cd ./android
  rm -rf ./app/build/outputs/apk

  # disable react-native lanch packager
  export RCT_NO_LAUNCH_PACKAGER=true

  if [ "$CHANNEL" == "true" ]; then
    ./gradlew assembleRelease

    for channel in $(ls ./app/build/outputs/apk); do
      mv -f ./app/build/outputs/apk/${channel}/release/*.apk ../packages/android/
    done
  else
    ./gradlew assembleAndroidRelease

    mv -f ./app/build/outputs/apk/android/release/*.apk ../packages/android/
  fi

  cd ..
}

buildIpa() {
  cd ./ios
  mkdir -p build

  # disable react-native lanch packager
  export RCT_NO_LAUNCH_PACKAGER=true

  xcodebuild clean \
    -workspace BIBFX.xcworkspace -scheme demo -configuration "Release"

  xcodebuild archive \
    -workspace BIBFX.xcworkspace -scheme demo -configuration "Release" \
    -archivePath "./build/demo-prod.xcarchive"

  xcodebuild \
    -exportArchive -archivePath "./build/demo-prod.xcarchive" \
    -exportPath "./build/" \
    -exportOptionsPlist "./ExportOptions.plist"

  mv -f ./build/demo.ipa ../packages/ios/
  rm -rf ./build
  cd ..
}

echoMD5() {
  cd packages

  if [ -f "md5.txt" ]; then
    rm md5.txt
  fi

  for file in $(ls *.zip); do
    md5 $file
    md5 $file >>md5.txt
  done

  cd ..
}

usage() {
  echo "build [-options] value"
  echo "-a  安装包，取值 ios|android|ios:android"
  echo "-b  bundle 包，取值 ios|android|ios:android"
  echo "-c  所有渠道包，取值 ios|android|ios:android"
  echo "-e  环境(必填)，取值 test|release"
  echo "-h  help"
  exit 0
}

main() {
  if [ -z "$EVN" ]; then
    echo "请指定 -e 打包环境参数"
    exit 0
  fi

  # 删除旧包
  rm -rf packages
  mkdir packages

  if [[ $EVN = 'test' ]]; then
    buildTestBundle
  else
    buildReleaseBundle
  fi

  if [ "$BUILD_PACKAGES" == "true" ]; then
    if [[ "$PACKAGES" = 'android' ]]; then
      mkdir packages/android
      buildApk
    elif [[ "$PACKAGES" = 'ios' ]]; then
      mkdir packages/ios
      buildIpa
    else
      mkdir packages/android packages/ios
      buildApk
      buildIpa
    fi
  fi

  echoMD5
  echo '打包完成'
  open ./packages
}

while getopts 'a:b:ce:h' options; do
  case "$options" in
  a)
    PACKAGES=${OPTARG}
    BUILD_PACKAGES=true
    ;;
  c)
    CHANNEL=true
    BUILD_PACKAGES=true
    ;;
  b) BUNDLE=${OPTARG} ;;
  e) EVN=${OPTARG} ;;
  *) usage ;;
  esac
done

main
