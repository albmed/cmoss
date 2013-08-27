#!/bin/bash
set -e

# Copyright (c) 2011, Mevan Samaratunga
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Mevan Samaratunga may not be used to endorse or
#       promote products derived from this software without specific prior
#       written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Download source
if [ "${SQLCIPHER_VERSION}" == "master" ] && [ ! -e "sqlcipher-master.zip" ]
then
	curl $PROXY -o "sqlcipher-master.zip" -L "https://github.com/sqlcipher/sqlcipher/archive/master.zip"
elif [ ! -e "sqlcipher-${SQLCIPHER_VERSION}.zip" ]
then
	curl $PROXY -o "sqlcipher-${SQLCIPHER_VERSION}.zip" -L "https://github.com/sqlcipher/sqlcipher/archive/v${SQLCIPHER_VERSION}.zip"
fi

# Extract source
rm -rf sqlcipher-${SQLCIPHER_VERSION}
unzip "sqlcipher-${SQLCIPHER_VERSION}.zip"

# Build
pushd sqlcipher-${SQLCIPHER_VERSION}
export CC=${DROIDTOOLS}-gcc
export LD=${DROIDTOOLS}-ld
export CPP=${DROIDTOOLS}-cpp
export CXX=${DROIDTOOLS}-g++
export AR=${DROIDTOOLS}-ar
export AS=${DROIDTOOLS}-as
export NM=${DROIDTOOLS}-nm
export STRIP=${DROIDTOOLS}-strip
export CXXCPP=${DROIDTOOLS}-cpp
export RANLIB=${DROIDTOOLS}-ranlib
export LDFLAGS="-Os -fpic -lc -Wl,-rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${ROOTDIR}/lib -lssl -lcrypto"
export CFLAGS="-Os -D_FILE_OFFSET_BITS=64 -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include -DSQLITE_HAS_CODEC"
export CXXFLAGS="-Os -D_FILE_OFFSET_BITS=64 -pipe -isysroot ${SYSROOT} -I${ROOTDIR}/include -DSQLITE_HAS_CODEC"

./configure --host=${ARCH}-android-linux --target=${PLATFORM} --prefix=${ROOTDIR} --disable-readline --disable-tcl --enable-threadsafe --enable-cross-thread-connections --enable-tempstore=no

# Fix libtool to not create versioned shared libraries
mv "libtool" "libtool~"
sed "s/library_names_spec=\".*\"/library_names_spec=\"~##~libname~##~{shared_ext}\"/" libtool~ > libtool~1
sed "s/soname_spec=\".*\"/soname_spec=\"~##~{libname}~##~{shared_ext}\"/" libtool~1 > libtool~2
sed "s/~##~/\\\\$/g" libtool~2 > libtool
chmod u+x libtool

make
make install
popd

# Clean up
rm -rf sqlcipher-${SQLCIPHER_VERSION}
