mkdir build
cd build

set BUILD_CONFIG=Release

REM remove GL flag for now
set "CXXFLAGS=-MD"
REM Configure step
if "%ARCH%"=="32" (
    set CMAKE_GENERATOR=Visual Studio 15 2017
) else (
    set CMAKE_GENERATOR=Visual Studio 15 2017 Win64
)
:: set CMAKE_GENERATOR_TOOLSET=v140_xp
cmake -G "Ninja" ^

    -DCMAKE_BUILD_TYPE="%BUILD_CONFIG%" ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
    -DLLVM_INCLUDE_TESTS=OFF ^
    -DLLVM_INCLUDE_UTILS=OFF ^
    -DLLVM_INCLUDE_DOCS=OFF ^
    -DLLVM_ENABLE_RTTI=ON ^
    -DLLVM_INCLUDE_EXAMPLES=OFF ^
    -DCMAKE_VERBOSE_MAKEFILE=ON ^
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
