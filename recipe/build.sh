set -x

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" cmake/modules/AddLLVM.cmake
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" cmake/modules/AddLLVM.cmake

mkdir build || true
cd build

cp -f "${RECIPE_DIR}"/{xcrun,xcodebuild} .

declare -a conditional_args
[[ ${target_platform} =~ .*inux.* ]] && conditional_args+=(-DLLVM_USE_INTEL_JITEVENTS=ON)
if [[ ${target_platform} == osx-64 ]]; then
  conditional_args+=(-DICONV_LIBRARY_PATH:FILEPATH=${CONDA_PREFIX}/lib/libiconv.dylib)
  conditional_args+=(-DLLVM_PTHREAD_LIBRARY_PATH:FILEPATH=${CONDA_PREFIX}/lib/libpthread.dylib)
  conditional_args+=(-DCMAKE_INSTALL_NAME_TOOL:FILEPATH=${INSTALL_NAME_TOOL})
  conditional_args+=(-DCMAKE_XCRUN:FILEPATH=${PWD}/xcrun)
fi

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=ON \
      -DLLVM_INCLUDE_GO_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=ON \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_LIBXML2=OFF \
      -DLLVM_ENABLE_ZLIB=OFF \
      -DHAVE_LIBEDIT=OFF \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_BUILD_LLVM_DYLIB=yes \
      -DLLVM_LINK_LLVM_DYLIB=yes \
      -DCMAKE_CXX:FILEPATH=${CXX} \
      -DCMAKE_LINKER:FILEPATH=${LD} \
      -DCMAKE_AR:FILEPATH=${AR} \
      -DCMAKE_AS:FILEPATH=${AS} \
      -DCMAKE_RANLIB:FILEPATH=${RANLIB} \
      -DCMAKE_ASM_COMPILER_AR:FILEPATH=${AR} \
      -DCMAKE_ASM_COMPILER_RANLIB:FILEPATH=${RANLIB} \
      -DCMAKE_INSTALL_NAME_TOOL:FILEPATH=${INSTALL_NAME_TOOL} \
      -DCMAKE_NM:FILEPATH=${NM} \
      -DCMAKE_OBJCOPY:FILEPATH=${OBJCOPY} \
      -DCMAKE_OBJDUMP:FILEPATH=${OBJDUMP} \
      -DCMAKE_STRIP:FILEPATH=${STRIP} \
      -DGOLD_EXECUTABLE:FILEPATH=${LD} \
      "${conditional_args[@]}" \
      ..

make -j${CPU_COUNT}

if [[ ${target_platform} == linux-64 ]] || [[ ${target_platform} == osx-64 ]]; then
    export TEST_CPU_FLAG="-mcpu=haswell"
else
    export TEST_CPU_FLAG=""
fi

bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

#make -j${CPU_COUNT} check-llvm

cd ../test
../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
