mkdir build
cd build

REM remove GL flag for now
set "CXXFLAGS=-MD"

cmake -G "Ninja" ^
    -DCMAKE_BUILD_TYPE="Release" ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
    -DLLVM_USE_INTEL_JITEVENTS=ON ^
    -DLLVM_INCLUDE_EXAMPLES=OFF ^
    -DLLVM_INCLUDE_TESTS=OFF ^
    -DLLVM_INCLUDE_UTILS=ON ^
    -DLLVM_INCLUDE_DOCS=OFF ^
    -DLLVM_ENABLE_RTTI=ON ^
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly ^
    -DLLVM_INCLUDE_UTILS=OFF -DLLVM_INCLUDE_DOCS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF ^
    -DLLVM_ENABLE_ASSERTIONS=ON
    %SRC_DIR%

if errorlevel 1 exit 1

:: Building in parallel with VS2015 often fails:
:: c:\users\builder\m64\conda-bld\llvmdev_1511658421193\work\lib\codegen\globalisel\calllowering.cpp : fatal error C1002: compiler is out of heap space in pass 2
:: .. even though using a 16GB machine with 16 threads and the 64-bit compilers.
ninja -j%CPU_COUNT% -v
:: .. so just rerun from where it fell over.
ninja -j1 -v
if errorlevel 1 exit 1

ninja install
if errorlevel 1 exit 1

bin\opt -S -vector-library=SVML -mcpu=haswell -O3 %RECIPE_DIR%\numba-3016.ll | bin\FileCheck %RECIPE_DIR%\numba-3016.ll
if errorlevel 1 exit 1

rem cd ..\test
rem ..\build\bin\llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
