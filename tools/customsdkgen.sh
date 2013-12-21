#!/bin/bash

SDK_VER=19
CUSTOM_VER=119
CUSTOM_NAME=aokp
TOPDIR=$(gettop)

STUBJAR=${TOPDIR}/out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes.jar
FRAMEWORKJAR=${TOPDIR}/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/classes.jar
COREJAR=${TOPDIR}/out/target/common/obj/JAVA_LIBRARIES/core_intermediates/classes.jar
FRAMEWORKRESJAR=${TOPDIR}/out/target/common/obj/JAVA_LIBRARIES/framework-base_intermediates/classes.jar

TMP_DIR=${TOPDIR}/out/tmp
mkdir -p ${TMP_DIR}
$(cd ${TMP_DIR}; jar -xf ${STUBJAR})
$(cd ${TMP_DIR}; jar -xf ${COREJAR})
$(cd ${TMP_DIR}; jar -xf ${FRAMEWORKJAR})
$(cd ${TMP_DIR}; jar -xf ${FRAMEWORKRESJAR})

jar -cf ${TOPDIR}/out/android.jar -C ${TMP_DIR}/ .

echo "android.jar created at ${TOPDIR}/out/android.jar"
echo "now attempting to create new sdk platform with it"

cp -rf ${ANDROID_HOME}/platforms/android-${SDK_VER} ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}
rm -f ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/android.jar
cp -f ${TOPDIR}/android.jar ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/android.jar
sed -i 's/^ro\.build\.version\.sdk=.*/ro.build.version.sdk=119/g' ${TOPDIR}/android.jar ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/build.prop
sed -i 's/^ro\.build\.version\.release=.*/ro.build.version.release=4.4-aokp/g' ${TOPDIR}/android.jar ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/build.prop
