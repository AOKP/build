#!/bin/bash

SDK_VER=21
CUSTOM_VER=121
CUSTOM_NAME=aokp

. ${ANDROID_BUILD_TOP}/vendor/aokp/tools/colors

if [ -z "$OUT" ]; then
    echo -e $CL_RED"Please lunch a product before using this command"$CL_RST
    exit 1
else
    OUTDIR=${OUT%/*/*/*}
fi

STUBJAR=${OUTDIR}/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes.jar
FRAMEWORKJAR=${OUTDIR}/target/common/obj/JAVA_LIBRARIES/framework_intermediates/classes.jar
COREJAR=${OUTDIR}/target/common/obj/JAVA_LIBRARIES/core_intermediates/classes.jar
FRAMEWORKRESJAR=${OUTDIR}/target/common/obj/JAVA_LIBRARIES/framework-base_intermediates/classes.jar
TELEPHONYJAR=${OUTDIR}/target/common/obj/JAVA_LIBRARIES/telephony-common_intermediates/classes.jar
COMMONJAR=${OUTDIR}/target/common/obj/JAVA_LIBRARIES/android-common_intermediates/classes.jar

if [ ! -f $STUBJAR ]; then
make $STUBJAR
fi
if [ ! -f $FRAMEWORKJAR ]; then
make $FRAMEWORKJAR
fi
if [ ! -f $COREJAR ]; then
make $COREJAR
fi
if [ ! -f $FRAMEWORKRESJAR ]; then
make $FRAMEWORKRESJAR
fi
if [ ! -f $TELEPHONYJAR ]; then
make $TELEPHONYJAR
fi
if [ ! -f $COMMONJAR ]; then
make $COMMONJAR
fi

TMP_DIR=${OUTDIR}/tmp
mkdir -p ${TMP_DIR}
$(cd ${TMP_DIR}; jar -xf ${STUBJAR})
$(cd ${TMP_DIR}; jar -xf ${COREJAR})
$(cd ${TMP_DIR}; jar -xf ${FRAMEWORKJAR})
$(cd ${TMP_DIR}; jar -xf ${FRAMEWORKRESJAR})
$(cd ${TMP_DIR}; jar -xf ${TELEPHONYJAR})
$(cd ${TMP_DIR}; jar -xf ${COMMONJAR})

jar -cf ${OUTDIR}/android.jar -C ${TMP_DIR}/ .

echo -e $CL_GRN"android.jar created at ${OUTDIR}/android.jar"$CL_RST
echo -e $CL_YLW"Now attempting to create new sdk platform with it"$CL_RST

if [ -z "$ANDROID_HOME" ]; then
    ANDROID=$(command -v emulator)
    ANDROID_HOME=${ANDROID%/*}
    if [ -z "$ANDROID_HOME" ]; then
        echo -e $CL_RED"ANDROID_HOME variable is not set. Do you have the sdk installed ?"$CL_RST
        exit 1
    fi
fi

cp -rf ${ANDROID_HOME}/platforms/android-${SDK_VER} ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}
rm -f ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/android.jar
cp -f ${OUTDIR}/android.jar ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/android.jar
sed -i 's/^ro\.build\.version\.sdk=.*/ro.build.version.sdk=121/g' ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/build.prop
sed -i 's/^ro\.build\.version\.release=.*/ro.build.version.release=5.0.2-aokp/g' ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/build.prop
sed -i 's/AndroidVersion.ApiLevel=19/AndroidVersion.ApiLevel=121/' ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/source.properties
sed -i 's/Pkg.Desc=/Pkg.Desc=AOKP /' ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/source.properties

if [ -f ${ANDROID_HOME}/platforms/android-${SDK_VER}-${CUSTOM_NAME}/android.jar ]; then
    echo -e $CL_CYN"New SDK platform with custom android.jar created inside ${ANDROID_HOME}"$CL_RST
fi

