#!/bin/bash

aar_root=$1
aar_name=$2
aar_version=$3

build_root=$4
lib=$5
include=$6

echo "root: $aar_root"
echo "name: $aar_name"
echo "version: $aar_version"
#echo "lib: $lib"
#echo "aar_include: $aar_include"

has_libs=true
if [ -z "$lib" ] ; then
    has_libs=false
fi

aar_root=$aar_root/$aar_name-$aar_version
aar_libs=$aar_root/prefab/modules/$aar_name/libs
aar_include=$aar_root/prefab/modules/$aar_name/include

mkdir -p "$aar_include"
mkdir -p "$aar_libs"
if [ "$has_libs" = true ] ; then
    mkdir "$aar_libs/android.arm64-v8a"
    mkdir "$aar_libs/android.armeabi-v7a"
    mkdir "$aar_libs/android.x86"
    mkdir "$aar_libs/android.x86_64"

    echo '{"abi":"arm64-v8a","api":21,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.arm64-v8a/abi.json
    echo '{"abi":"armeabi-v7a","api":16,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.armeabi-v7a/abi.json
    echo '{"abi":"x86","api":16,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.x86/abi.json
    echo '{"abi":"x86_64","api":21,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.x86_64/abi.json
fi

echo -e '{\n    "export_libraries": [],\n    "library_name": null,\n    "android": {\n      "export_libraries": [],\n      "library_name": null\n    }\n}' > $aar_root/prefab/modules/$aar_name/module.json

printf '{\n    "schema_version": 1,\n    "name": "%s",\n    "version": "%s",\n    "dependencies": []\n}' $aar_name $aar_version > $aar_root/prefab/prefab.json

printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="de.badaix.%s" android:versionCode="1" android:versionName="1.0">\n	<uses-sdk android:minSdkVersion="16" android:targetSdkVersion="29"/>\n</manifest>' $aar_name > $aar_root/AndroidManifest.xml

if [ "$has_libs" = true ] ; then
    cp "$build_root/x86_64-linux-android/usr/local/lib/$lib" "$aar_libs/android.x86_64/lib$aar_name.a" 
    cp "$build_root/i686-linux-android/usr/local/lib/$lib" "$aar_libs/android.x86/lib$aar_name.a" 
    cp "$build_root/armv7a-linux-androideabi/usr/local/lib/$lib" "$aar_libs/android.armeabi-v7a/lib$aar_name.a" 
    cp "$build_root/aarch64-linux-android/usr/local/lib/$lib" "$aar_libs/android.arm64-v8a/lib$aar_name.a" 
    cp -r "$build_root/x86_64-linux-android/usr/local/include/$include" "$aar_include/" 
else
    # the boost hack
    cp -r "$include" "$aar_include/" 
fi

cd "$aar_root"
zip -9 -r "../$aar_name-$aar_version.aar" .
cd -
