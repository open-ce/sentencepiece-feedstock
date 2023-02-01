#!/bin/bash
#
# (C) Copyright IBM Corp. 2019,2022. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************

set -ex

if [[ $ppc_arch == "p10" ]]
then
  if [[ -z "${GCC_11_HOME}" ]];
  then
    echo "Please set GCC_11_HOME to the install path of gcc-toolset-11"
    exit 1
  else
    export CMAKE_PREFIX_PATH=$PREFIX
    export GCC_AR=$GCC_11_HOME/bin/ar
    # Removing Anaconda supplied libstdc++.so so that generated libs build against
    # libstdc++.so present on the system provided by gcc-toolset-10
    rm ${PREFIX}/lib/libstdc++.so*
    rm ${BUILD_PREFIX}/lib/libstdc++.so*
  fi
fi

ARCH=`uname -p`
if [[ "${ARCH}" == 'ppc64le' ]]; then
    ARCH_SO_NAME="powerpc64le"
else
    ARCH_SO_NAME=${ARCH}
fi

PAGE_SIZE=`getconf PAGE_SIZE`

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} .. -DSPM_BUILD_TEST=ON -DSPM_ENABLE_TCMALLOC=OFF -DSPM_USE_BUILTIN_PROTOBUF=ON -DCMAKE_AR=$GCC_AR
make -j $(nproc)

export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:${PKG_CONFIG_PATH}
export LD_LIBRARY_PATH=${PREFIX}/lib:${PREFIX}/lib64:${LD_LIBRARY_PATH}
make install

cd ../python

python setup.py install

SYS_PYTHON_MAJOR=$(python -c "import sys;print(sys.version_info.major)")
SYS_PYTHON_MINOR=$(python -c "import sys;print(sys.version_info.minor)")
if [[ "${SYS_PYTHON_MINOR}" -gt '7' ]]; then
    patchelf --page-size ${PAGE_SIZE} --set-rpath $LD_LIBRARY_PATH $PREFIX/lib/python${SYS_PYTHON_MAJOR}.${SYS_PYTHON_MINOR}/site-packages/sentencepiece-$PKG_VERSION-py${SYS_PYTHON_MAJOR}.${SYS_PYTHON_MINOR}-linux-${ARCH}.egg/sentencepiece/_sentencepiece.cpython-${CONDA_PY}-${ARCH_SO_NAME}-linux-gnu.so
else
    patchelf --page-size ${PAGE_SIZE} --set-rpath $LD_LIBRARY_PATH $PREFIX/lib/python${SYS_PYTHON_MAJOR}.${SYS_PYTHON_MINOR}/site-packages/sentencepiece-$PKG_VERSION-py${SYS_PYTHON_MAJOR}.${SYS_PYTHON_MINOR}-linux-${ARCH}.egg/sentencepiece/_sentencepiece.cpython-${CONDA_PY}m-${ARCH_SO_NAME}-linux-gnu.so
fi

exit 0
