#!/bin/bash

aar_root=$1
aar_name=$2
aar_version=$3
build_root=$4
libs=$5
include=$6

echo "root: $aar_root"
echo "name: $aar_name"
echo "version: $aar_version"

has_libs=true
if [ -z "$libs" ]; then
    has_libs=false
fi

aar_root=$aar_root/$aar_name-$aar_version
mkdir -p "$aar_root/prefab"

# Create prefab.json
printf '{\n    "schema_version": 1,\n    "name": "%s",\n    "version": "%s",\n    "dependencies": []\n}' $aar_name $aar_version > $aar_root/prefab/prefab.json

# Create AndroidManifest.xml
printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="de.badaix.%s" android:versionCode="1" android:versionName="1.0">\n	<uses-sdk android:minSdkVersion="16" android:targetSdkVersion="29"/>\n</manifest>' $aar_name > $aar_root/AndroidManifest.xml

if [ "$has_libs" = true ]; then
    for lib_file in $libs; do
        # Extract library name without 'lib' prefix and '.a' suffix
        lib_name=$(echo "$lib_file" | sed 's/lib\(.*\)\.a/\1/')

        # Create module directory for this library
        aar_libs=$aar_root/prefab/modules/$lib_name/libs
        aar_include=$aar_root/prefab/modules/$lib_name/include

        mkdir -p "$aar_include"
        mkdir -p "$aar_libs/android.arm64-v8a"
        mkdir -p "$aar_libs/android.armeabi-v7a"
        mkdir -p "$aar_libs/android.x86"
        mkdir -p "$aar_libs/android.x86_64"

        # Create abi.json files for each architecture
        echo '{"abi":"arm64-v8a","api":21,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.arm64-v8a/abi.json
        echo '{"abi":"armeabi-v7a","api":16,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.armeabi-v7a/abi.json
        echo '{"abi":"x86","api":16,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.x86/abi.json
        echo '{"abi":"x86_64","api":21,"ndk":21,"stl":"c++_shared"}' > $aar_libs/android.x86_64/abi.json

        # Create module.json for this library
        # if [ "$aar_name" = "openssl" ]; then
        #     echo '{}' > $aar_root/prefab/modules/$lib_name/module.json
        # else
        echo -e '{\n    "export_libraries": [],\n    "library_name": "'$lib_name'",\n    "android": {\n      "export_libraries": [],\n      "library_name": "'$lib_name'"\n    }\n}' > $aar_root/prefab/modules/$lib_name/module.json
        # fi

        # Copy the library file for each architecture
        cp "$build_root/x86_64-linux-android/usr/local/lib/$lib_file" "$aar_libs/android.x86_64/$lib_file"
        cp "$build_root/i686-linux-android/usr/local/lib/$lib_file" "$aar_libs/android.x86/$lib_file"
        cp "$build_root/armv7a-linux-androideabi/usr/local/lib/$lib_file" "$aar_libs/android.armeabi-v7a/$lib_file"
        cp "$build_root/aarch64-linux-android/usr/local/lib/$lib_file" "$aar_libs/android.arm64-v8a/$lib_file"

        # Copy include files for this module
        cp -r "$build_root/x86_64-linux-android/usr/local/include/$include" "$aar_include/"
    done
else
    # Handle the boost hack (no libraries, only include)
    aar_include=$aar_root/prefab/modules/$aar_name/include
    mkdir -p "$aar_include"
    cp -r "$include" "$aar_include/"

    echo -e '{\n    "export_libraries": [],\n    "library_name": null,\n    "android": {\n      "export_libraries": [],\n      "library_name": null\n    }\n}' > $aar_root/prefab/modules/$aar_name/module.json

fi

# Create the AAR file
cd "$aar_root"
zip -9 -r "../$aar_name-$aar_version.aar" .
cd -
