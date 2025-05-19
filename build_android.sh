#!/bin/bash

if [ -z "$NDK_DIR" ]; then
  echo "Please set NDK_DIR to the Android NDK folder"
  exit 1
fi

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function prepare
{
    if [ "$1" = "x86" ] ; then
        ARCH="x86"
        CPPFLAGS="-DLITTLE_ENDIAN=1234 -DBIG_ENDIAN=4321 -DBYTE_ORDER=LITTLE_ENDIAN"
        TARGET="i686-linux-android"
        API=21
    elif [ "$1" = "x86_64" ] ; then
        ARCH="x86_64"
	    CPPFLAGS="-DLITTLE_ENDIAN=1234 -DBIG_ENDIAN=4321 -DBYTE_ORDER=LITTLE_ENDIAN"
	    TARGET="x86_64-linux-android"
	    API=21
    elif [ "$1" = "armeabi-v7a" ] ; then
        ARCH="arm"
	    CPPFLAGS="-U_ARM_ASSEM_"
        TARGET="armv7a-linux-androideabi"
	    API=21
    elif [ "$1" = "arm64-v8a" ] ; then
        ARCH="aarch64"
	    CPPFLAGS="-U_ARM_ASSEM_ -DLITTLE_ENDIAN=1234 -DBIG_ENDIAN=4321 -DBYTE_ORDER=LITTLE_ENDIAN"
	    TARGET="aarch64-linux-android"
	    API=21
    fi    
	
	TOOLCHAIN="${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64"
    CC="${TOOLCHAIN}/bin/${TARGET}${API}-clang"
	CXX="${TOOLCHAIN}/bin/${TARGET}${API}-clang++"
	SYSROOT="${BASEDIR}/build/android/${TARGET}"
	CPPFLAGS="-I${TOOLCHAIN}/sysroot/usr/include -I${SYSROOT}/usr/local/include ${CPPFLAGS}"

    echo "Toolchain: $TOOLCHAIN"
    echo "CC: $CC"
    echo "CXX: $CXX"
    echo "SYSROOT: $SYSROOT"
    echo "CPPFLAGS: $CPPFLAGS"
    echo "BASEDIR: ${BASEDIR}"

	export CC=${CC}
	export CXX=${CXX}
	export CPPFLAGS=${CPPFLAGS}
}

function build_flac 
{
    prepare $1

	cd ${BASEDIR}/externals/flac
	CFLAGS="-Wn-oimplicit-function-declaration ${CFLAGS}"
	export CFLAGS=${CFLAGS}
	./autogen.sh
	./configure --host=${ARCH} --disable-ogg --disable-asm-optimizations --disable-doxygen-docs --disable-xmms-plugin --disable-examples --prefix=${SYSROOT}/usr/local/
	make -j 4
	make install
	make clean
	rm -f *~
}


function build_ogg
{
    prepare $1

	cd ${BASEDIR}/externals/ogg
	./autogen.sh
	./configure --host=${ARCH} --with-pic --prefix=${SYSROOT}/usr/local/
	make -j 4
	make install
	make clean
	rm -f *~
}

function build_opus
{
    prepare $1

    cd ${BASEDIR}/externals/opus
	./autogen.sh
	./configure --host=${ARCH} --prefix=${SYSROOT}/usr/local/
	make -j 4
	make install
	make clean
	rm test-driver
	rm celt/arm/armopts.s
}

function build_tremor
{
    prepare $1

	cd ${BASEDIR}/externals/tremor
	./autogen.sh
	./configure --host=${ARCH} --with-pic --prefix=${SYSROOT}/usr/local/ --with-ogg=${SYSROOT}/usr/local/ --with-ogg-libraries=${SYSROOT}/usr/local/lib --with-ogg-includes=${SYSROOT}/usr/local/include/ogg
	make -j 4
	make install
	make clean
	rm -rf .deps/
	rm Makefile
	rm Makefile.in
	rm Version_script
	rm aclocal.m4
	rm -rf autom4te.cache/
	rm compile
	rm config.guess
	rm config.h
	rm config.h.in
	rm config.log
	rm config.status
	rm config.sub
	rm configure
	rm depcomp
	rm install-sh
	rm libtool
	rm ltmain.sh
	rm missing
	rm stamp-h1
	rm vorbisidec.pc
}

function build_oboe
{
    prepare $1

	cd ${BASEDIR}/externals/oboe
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j 4 VERBOSE=1
	make DESTDIR=${SYSROOT} install
	make clean
	cd ..
	rm -rf build
}

function build_soxr
{
    prepare $1

	cd ${BASEDIR}/externals/soxr
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF -DWITH_OPENMP=OFF ..
	make -j 4 VERBOSE=1
	make DESTDIR=${SYSROOT} install
	make clean
	cd ..
	rm -rf build
}

function build_vorbis
{
    prepare $1

    cd ${BASEDIR}/externals/vorbis
	./autogen.sh
	./configure --host=${ARCH} --prefix=${SYSROOT}/usr/local/
	make -j 4
	make install
	make clean
	rm -f *~
}

build_flac x86
# build_ogg x86
# build_opus x86
# build_tremor x86
# build_oboe x86
# build_soxr x86
# build_vorbis x86

# build_flac x86_64
# build_ogg x86_64
# build_opus x86_64
# build_tremor x86_64
# build_oboe x86_64
# build_soxr x86_64
# build_vorbis x86_64

# build_flac armeabi-v7a
# build_ogg armeabi-v7a
# build_opus armeabi-v7a
# build_tremor armeabi-v7a
# build_oboe armeabi-v7a
# build_soxr armeabi-v7a
# build_vorbis armeabi-v7a

# build_flac arm64-v8a
# build_ogg arm64-v8a
# build_opus arm64-v8a
# build_tremor arm64-v8a
# build_oboe arm64-v8a
# build_soxr arm64-v8a
# build_vorbis arm64-v8a

cd ${BASEDIR}
./make_aar.sh build/aar/ flac 1.4.2 ./build/android/ libFLAC.a FLAC
./make_aar.sh build/aar/ ogg 1.3.5 ./build/android/ libogg.a ogg
./make_aar.sh build/aar/ opus 1.1.2 ./build/android/ libopus.a opus
./make_aar.sh build/aar/ tremor 1.0.1 ./build/android/ libvorbisidec.a tremor
./make_aar.sh build/aar/ oboe 1.9.0 ./build/android/ liboboe.a oboe
./make_aar.sh build/aar/ soxr 0.1.3 ./build/android/ libsoxr.a soxr.h
./make_aar.sh build/aar/ vorbis 1.3.7 ./build/android/ libvorbis.a vorbis
./make_aar.sh build/aar/ boost 1.85.0 ./build/android/ "" boost_1_85_0/boost
