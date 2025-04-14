# CMakeLists.txt for building VASP (Vienna Ab Initio Simulation Package)
#
# Original CMake port by Simon Frasch (CSCS)
# GitHub: https://github.com/AdhocMan/vasp_cmake/
#
# This file configures the build system for VASP using CMake.

cmake_minimum_required(VERSION 3.20 FATAL_ERROR)
set(CMAKE_DEPENDS_USE_COMPILER TRUE)
set(CMAKE_POLICY_DEFAULT_CMP0048 NEW)

# set default flags. Must be called before project() enables languages.
macro(set_mode_flags languages mode value)
  foreach(lang ${languages})
    set(CMAKE_${lang}_FLAGS_${mode} "${value}" CACHE STRING "")
  endforeach()
endmacro()

set_mode_flags("C;CXX" "DEBUG" "-g")
set_mode_flags("C;CXX" "RELWITHDEBINFO" "-g -DNDEBUG")
set_mode_flags("C;CXX" "RELEASE" "-DNDEBUG")
set_mode_flags("C;CXX" "MINSIZEREL" "-DNDEBUG")

set_mode_flags("Fortran" "DEBUG" "-g")
set_mode_flags("Fortran" "RELWITHDEBINFO" "-g")
set_mode_flags("Fortran" "RELEASE" "")
set_mode_flags("Fortran" "MINSIZEREL" "")

message(STATUS "-------- compiler detection -------------")
project(vasp
  VERSION 6.5.0
  DESCRIPTION "VASP"
  LANGUAGES Fortran C CXX)

# check for NEC Fortran compiler
string(FIND "${CMAKE_Fortran_COMPILER}" "nfort" FOUND_NFORT)
if (FOUND_NFORT GREATER -1)
  set(CMAKE_Fortran_COMPILER_ID NFORT)
  message(STATUS "Detected NEC Fortran compiler nfort")
endif()

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

# allow {module}_ROOT variables to be set
if(POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

# use INTERFACE_LINK_LIBRARIES property if available
if(POLICY CMP0022)
  cmake_policy(SET CMP0022 NEW)
endif()

# set default build type to RELEASE
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release" "RelWithDebInfo"
  )
endif()

# set binary directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# make sure preprocessing is off! Custom preprocessor is used in src/CMakeLists.txt
set(CMAKE_Fortran_PREPROCESS OFF)

# Get GNU standard install prefixes
include(GNUInstallDirs)

# Options
include(CMakeDependentOption)

option(VASP_PROFILING "Enable profiling" OFF)
set(VASP_CACHE_SIZE "4000" CACHE STRING "Cache size")
option(VASP_COLLECTIVE "Enable MPI collectives" ON)
set(VASP_MPI_BLOCK "8000" CACHE STRING "MPI block size")
set(VASP_HOST_NAME ${CMAKE_SYSTEM_NAME} CACHE STRING "Host system name")
option(VASP_AVOIDALLOC "Avoid automatic allocation" ON)
option(VASP_VASP6 "Enable VASP 6.x features" ON)
option(VASP_TBDYN "Enable advanced molecular dynamics" ON)
option(VASP_FOCK_DBLBUF "Enable double buffering for exchange potential" ON)
option(VASP_SHMEM "Enable shared memory for reduced memory usage" OFF)
option(VASP_SHMEM_BCAST "Enable shared memory MPI bcast" OFF)
option(VASP_SHMEM_RPROJ "Enable shared memory for PAW projections" OFF)
option(VASP_SYSV "Enable shared-memory for ipcs and system-V" OFF)
option(VASP_MPI_INPLACE "Use MPI inplace" ON)

option(VASP_OPENMP "Enable OpenMP" OFF)
option(VASP_PLUGINS "Enable VASP Plugin support" OFF)
option(VASP_FFTLIB "Enable internal FFTLIB" OFF)
option(VASP_SCALAPACK "Enable ScaLAPACK" ON)
option(QD_EMULATE "use QD library for quadruple precision types" OFF)
option(USE_ERF "use internal ERF implementation" OFF)

option(VASP_LIBBEEF "Enable libbeef for van-der-Waals functionals" OFF)
option(VASP_DFTD4 "Enable DFTD4 library" OFF)
option(VASP_WANNIER90 "Enable Wannier90 library" OFF)
option(VASP_LIBXC "Enable Libxc library" OFF)
option(VASP_CUDA "Enable cuda accelaration" OFF)
option(VASP_OMP_OFFLOAD "Enable OMP device offloading" OFF)
set(VASP_CUDA_VERSION "Default" CACHE STRING "Set the CUDA version passed on to the NVHPC compiler")
cmake_dependent_option(VASP_CUSOLVERMP "Enable usage of cuSOLVERmp" OFF "VASP_CUDA" OFF)

set(VASP_PP_EXTRA "" CACHE STRING "Extra preprocessor flags not covered by the options above")

option(VASP_TESTSUITE "Enable testsuite in build dir" ON)

set(CMAKE_CUDA_ARCHITECTURES "native" CACHE STRING "Cuda architectures list or native for automatic detection. Example: \"60;70;80\"")

# Additional options for source file selection and optimization flags
include(cmake/sources_and_flags_options.cmake)

set(VASP_EXTERNAL_LIBS)

# Get the LIBRARY_PATH environment variable and convert it to a CMake list
set(ENV_LIBRARY_PATH $ENV{LIBRARY_PATH})
string(REPLACE ":" ";" LIBRARY_PATH_LIST "${ENV_LIBRARY_PATH}")
# Append LIBRARY_PATH to CMAKE_LIBRARY_PATH and CMAKE_PREFIX_PATH
list(APPEND CMAKE_LIBRARY_PATH ${LIBRARY_PATH_LIST})
foreach(PATH ${CMAKE_LIBRARY_PATH})
  get_filename_component(PARENT_DIR ${PATH} PATH)
  list(APPEND CMAKE_PREFIX_PATH ${PARENT_DIR})
  list(APPEND CMAKE_INCLUDE_PATH ${PARENT_DIR}/include)
endforeach()

#-----------------------------
# mandatory external libraries
#-----------------------------
message(STATUS "-------- MPI detection ------------------")
find_package(MPI MODULE REQUIRED
  COMPONENTS Fortran)
list(APPEND VASP_EXTERNAL_LIBS MPI::MPI_Fortran)
# for scaLAPACK it is useful to detect if we are using OMPI
set (MPI_IS_OMPI FALSE)
execute_process(COMMAND grep -i "OMPI_MPI" ${MPI_Fortran_F77_HEADER_DIR}/mpi.h
  RESULT_VARIABLE MPI_GREP_RESULT
  OUTPUT_QUIET
  ERROR_QUIET)

if(MPI_GREP_RESULT EQUAL 0)
  set(MPI_IS_OMPI TRUE)
endif()

message(STATUS "-------- Lapack detection ---------------")
set(BLA_SIZEOF_INTEGER 4) # only look for 32-bit BLAS / LAPACK
# for NEC we specify the linking library manually
if(CMAKE_Fortran_COMPILER_ID STREQUAL "NFORT")
  set(BLAS_LIBRARIES "-lblas_sequential -lcblas" CACHE STRING "Manually set BLAS libraries" FORCE)
endif()
find_package(BLAS MODULE REQUIRED)
list(APPEND VASP_EXTERNAL_LIBS BLAS::BLAS)

find_package(LAPACK MODULE REQUIRED)
list(APPEND VASP_EXTERNAL_LIBS LAPACK::LAPACK)

message(STATUS "-------- FFTW detection -----------------")
# The FindFFTW module will use the blas library if it provides FFTW symbols like MKL or ArmPL
# for NEC we specify the linking library manually
if(CMAKE_Fortran_COMPILER_ID STREQUAL "NFORT")
  set(NLC_ROOT $ENV{NLC_ROOT})
  add_library(FFTW::FFTW_SERIAL INTERFACE IMPORTED)
  set_property(TARGET FFTW::FFTW_SERIAL PROPERTY INTERFACE_LINK_LIBRARIES aslfftw3_mpi asl_mpi_sequential)
  set_property(TARGET FFTW::FFTW_SERIAL PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${NLC_ROOT}/include)
  target_compile_options(FFTW::FFTW_SERIAL INTERFACE -cxxlib -static -static-nec)
  list(APPEND VASP_EXTERNAL_LIBS FFTW::FFTW_SERIAL)
else()
  if(VASP_OPENMP)
    find_package(FFTW MODULE REQUIRED COMPONENTS OMP)
    list(APPEND VASP_EXTERNAL_LIBS FFTW::FFTW_OMP)
  else()
    find_package(FFTW MODULE REQUIRED COMPONENTS SERIAL)
    list(APPEND VASP_EXTERNAL_LIBS FFTW::FFTW_SERIAL)
  endif()
endif()

#-----------------------------
# optional external libraries
#-----------------------------
if(VASP_SCALAPACK)
  message(STATUS "-------- ScaLAPACK detection ------------")
  find_package(SCALAPACK MODULE REQUIRED)
  list(APPEND VASP_EXTERNAL_LIBS SCALAPACK::SCALAPACK)
endif()

message(STATUS "-------- Optional dependencies ----------")

if(VASP_OPENMP)
  find_package(OpenMP MODULE COMPONENTS Fortran CXX REQUIRED)
  list(APPEND VASP_EXTERNAL_LIBS OpenMP::OpenMP_Fortran OpenMP::OpenMP_CXX)
endif()

# try to find HDF5 always
find_package(HDF5 MODULE COMPONENTS Fortran)
if(HDF5_FOUND)
  list(APPEND VASP_EXTERNAL_LIBS hdf5::hdf5_fortran)
  set(VASP_HDF5 ON)
else()
  message(STATUS "HDF5 not found - VASP HDF5 support disabled.")
  set(VASP_HDF5 OFF)
endif()

if(VASP_LIBXC)
  find_package(LibXC MODULE REQUIRED)
  list(APPEND VASP_EXTERNAL_LIBS LibXC::libxc)
endif()

if(VASP_WANNIER90)
  find_package(WANNIER90 MODULE REQUIRED)
  list(APPEND VASP_EXTERNAL_LIBS WANNIER90::wannier90)
endif()

if(VASP_LIBBEEF OR VASP_DFTD4)
  message(FATAL_ERROR "VASP_LIBBEEF and VASP_DFTD4 not yet supported through CMake.")
endif()

#-----------------------------
# GPU support
#-----------------------------

# Find CUDA
message(STATUS "-------- GPU support detection ----------")
include(CheckLanguage)
check_language(CUDA)
if(CMAKE_CUDA_COMPILER)
  enable_language(CUDA)
  set(VASP_CUDA ON)
endif()

if(VASP_CUDA)
  message(STATUS "CUDA and an offloading device was found enabling OpenACC port")

  if(${CMAKE_CUDA_ARCHITECTURES} STREQUAL "native")
    message(STATUS "setting default CUDA compute capability of present device")
    set(VASP_GPU_FLAG "-gpu=ccnative")
    message(STATUS "overwrite this by calling cmake with -DCMAKE_CUDA_ARCHITECTURES=XX")
  else()
    message(STATUS "setting user specified CUDA compute capability")
    set(VASP_CUDA_ARCH ${CMAKE_CUDA_ARCHITECTURES})
    list(POP_FRONT VASP_CUDA_ARCH VASP_FIRST_ARCH)
    set(VASP_GPU_FLAG "-gpu=cc${VASP_FIRST_ARCH}")

    foreach(arch IN LISTS VASP_CUDA_ARCH)
      set(VASP_GPU_FLAG "${VASP_GPU_FLAG},cc${arch}")
    endforeach()
  endif()

  if(VASP_CUDA_VERSION AND NOT ${VASP_CUDA_VERSION} STREQUAL "Default")
    message(STATUS "CUDA version: ${VASP_CUDA_VERSION}")
    set(VASP_GPU_FLAG "${VASP_GPU_FLAG},cuda${VASP_CUDA_VERSION}")
  else()
    message(STATUS "default CUDA version, use -DVASP_CUDA_VERSION=XX to change")
  endif()
  message(STATUS "CUDA compile flags: ${VASP_GPU_FLAG}")

  set(_CUDA_LIB_LIST "cublas,cusolver,cufft,nccl")
  if(VASP_CUSOLVERMP)
    set(_CUDA_LIB_LIST "${_CUDA_LIB_LIST},cusolvermp,cublasmp")
  endif()

  list(APPEND VASP_FORTRAN_FLAGS -acc ${VASP_GPU_FLAG})
  list(APPEND VASP_EXTERNAL_LIBS "-cudalib=${_CUDA_LIB_LIST} -cuda -acc ${VASP_GPU_FLAG}")
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC" OR QD_EMULATE)
  set(QD_EMULATE ON)
endif()

if(QD_EMULATE)
  find_package(QD MODULE REQUIRED)
  list(APPEND VASP_EXTERNAL_LIBS QD::qd)
  set(QD_EMULATE ON)
endif()

message(STATUS "-------- done checking dependencies -----")

#-----------------------------
# set precompiler definitions
#-----------------------------
set(VASP_DEFINITIONS
  MPI
  "HOST=\"${VASP_HOST_NAME}\""
  MPI_BLOCK=${VASP_MPI_BLOCK}
  CACHE_SIZE=${VASP_CACHE_SIZE}
  $<$<BOOL:${VASP_MPI_INPLACE}>:MPI_INPLACE>
  $<$<BOOL:${VASP_PROFILING}>:PROFILING>
  $<$<BOOL:${VASP_COLLECTIVE}>:use_collective>
  $<$<BOOL:${VASP_AVOIDALLOC}>:avoidalloc>
  $<$<BOOL:${VASP_VASP6}>:vasp6>
  $<$<BOOL:${VASP_TBDYN}>:tbdyn>
  $<$<BOOL:${VASP_FOCK_DBLBUF}>:fock_dblbuf>
  $<$<BOOL:${VASP_SHMEM}>:use_shmem>
  $<$<BOOL:${VASP_SHMEM_BCAST}>:shmem_bcast_buffer>
  $<$<BOOL:${VASP_SHMEM_RPROJ}>:shmem_rproj>
  $<$<BOOL:${VASP_SYSV}>:sysv>
  $<$<BOOL:${VASP_OPENMP}>:_OPENMP>
  $<$<BOOL:${VASP_SCALAPACK}>:scaLAPACK>
  $<$<BOOL:${VASP_HDF5}>:VASP_HDF5>
  $<$<BOOL:${VASP_PLUGINS}>:PLUGINS>
  $<$<BOOL:${VASP_LIBXC}>:USELIBXC>
  $<$<BOOL:${VASP_WANNIER90}>:VASP2WANNIER90>
  $<$<BOOL:${QD_EMULATE}>:qd_emulate>
  # nvhpc already defines _OPENACC with "-acc", but not defining it seems to cause issues with dependency detection with make. Ninja works without it.
  $<$<BOOL:${VASP_CUDA}>:ACC_OFFLOAD>
  $<$<BOOL:${VASP_CUDA}>:USENCCL>
  $<$<BOOL:${VASP_CUDA}>:NVCUDA>
  $<$<BOOL:${VASP_CUSOLVERMP}>:CUSOLVERMP>
  $<$<BOOL:${VASP_CUSOLVERMP}>:CUBLASMP>
)

# add additional preprocessor flags passed via VASP_PP_EXTRA
if(VASP_PP_EXTRA AND NOT VASP_PP_EXTRA STREQUAL "")
  separate_arguments(PP_EXTRA UNIX_COMMAND "${VASP_PP_EXTRA}")
  list(APPEND VASP_DEFINITIONS ${PP_EXTRA})
endif()

# NEC compiler specific definitions
if(CMAKE_Fortran_COMPILER_ID STREQUAL "NFORT")
  list(APPEND VASP_DEFINITIONS __NEC__)
  list(APPEND VASP_DEFINITIONS __NEC_TUNE__)
  list(APPEND VASP_DEFINITIONS DCRREXP_inline )
  list(APPEND VASP_DEFINITIONS RPROMU_DGEMV)
  list(APPEND VASP_DEFINITIONS USE_ERF)
endif()

# Convert the target definitions to preprocessor flags
set(PREPROCESSOR_DEFINITIONS "")
foreach(DEFINITION ${VASP_DEFINITIONS})
  if(DEFINITION MATCHES "^\\$<\\$<BOOL:(ON|OFF)>:(.+)>$")  # Match the pattern
    set(BOOL_VALUE ${CMAKE_MATCH_1})  # Extract ON/OFF
    set(ACTUAL_DEFINITION ${CMAKE_MATCH_2})  # Extract the actual macro name

    if(BOOL_VALUE STREQUAL "ON")  # Only add if BOOL is ON
      list(APPEND PREPROCESSOR_DEFINITIONS "-D${ACTUAL_DEFINITION}")
    endif()
  else()
    # escape strings to pass them correctly
    string(REPLACE "\"" "\\\"" ESCAPED_DEFINITION "${DEFINITION}")
    list(APPEND PREPROCESSOR_DEFINITIONS "-D${ESCAPED_DEFINITION}")
  endif()
endforeach()
# print the preprocessor definitions once
if(NOT PP_MESSAGE_SHOWN)
  string(JOIN "\n   " PP_LIST_FORMAT ${PREPROCESSOR_DEFINITIONS})
  message(STATUS "VASP preprocessor definitions (CPP_OPTIONS):")
  message(STATUS "${PP_LIST_FORMAT}")
endif()
set(PP_MESSAGE_SHOWN TRUE CACHE INTERNAL "Message shown flag")

# move on to the actual build
add_subdirectory(src)

# Testing
if(VASP_TESTSUITE)
  # for now just use the custom runtest script
  # enable testing here if other tests are added
  # enable_testing()
  add_subdirectory(testsuite)
endif()
