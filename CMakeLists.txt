cmake_minimum_required(VERSION 3.20 FATAL_ERROR)
set(CMAKE_POLICY_DEFAULT_CMP0048 NEW)

project(vasp
    VERSION 6.3.0
    DESCRIPTION "VASP"
    LANGUAGES Fortran C CXX)

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
		"Debug" "Release" "MinSizeRel" "RelWithDebInfo"
		)
endif()

# set language and standard
set(CMAKE_CXX_STANDARD 14)

# set binary directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# make sure preprocessing is on
set(CMAKE_Fortran_PREPROCESS ON)

# Get GNU standard install prefixes
include(GNUInstallDirs)

# Options
include(CMakeDependentOption)

option(VASP_PROFILING "Enable profiling" OFF)
option(VASP_COLLECTIVE "Enable MPI collectives" OFF)
set(VASP_MPI_BLOCK "8000" CACHE STRING "MPI block size")
set(VASP_HOST_NAME ${CMAKE_SYSTEM_NAME} CACHE STRING "Host system name")
option(VASP_AVOIDALLOC "Avoid automatic allocation" OFF)
option(VASP_VASP6 "Enable VASP 6.x features" ON)
option(VASP_TBDYN "Enable advanced molecular dynamics" ON)
option(VASP_FOCK_DBLBUF "Enable double buffering for exchange potential" OFF)
option(VASP_SHMEM "Enable shared memory for reduced memory usage" OFF)
option(VASP_SHMEM_BCAST "Enable shared memory MPI bcast" OFF)
option(VASP_SHMEM_RPROJ "Enable shared memory for PAW projections" OFF)
option(VASP_SYSV "Enable shared-memory for ipcs and system-V" OFF)
option(VASP_BSE "Enable BSE method" ON)

option(VASP_OPENMP "Enable OpenMP" OFF)
cmake_dependent_option(VASP_FFTLIB "Enable internal FFTLIB" ON "VASP_OPENMP" OFF)
option(VASP_SCALAPACK "Enable ScaLAPACK" OFF)
option(VASP_HDF5 "Enable hdf5" OFF)
option(VASP_LIBBEEF "Enable libbeef for van-der-Waals functionals" OFF)
option(VASP_DFTD4 "Enable DFTD4 library" OFF)
option(VASP_WANNIER90 "Enable Wannier90 library" OFF)
option(VASP_LIBXC "Enable Libxc library" OFF)
option(VASP_CUDA "Enable cuda accelaration" OFF)
cmake_dependent_option(VASP_NCCLP2P "Enable NCCL library collectives instead of MPI" ON "VASP_CUDA" OFF)

set(CMAKE_CUDA_ARCHITECTURES "60;70;80" CACHE STRING "Cuda architectures")

set(VASP_EXTERNAL_LIBS)
set(VASP_FORTRAN_FLAGS)


set(VASP_DEFINITIONS
	MPI
	"HOST=\"${VASP_HOST_NAME}\""
	MPI_BLOCK=${VASP_MPI_BLOCK}
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
	$<$<BOOL:${VASP_BSE}>:use_bse_te>
	$<$<BOOL:${VASP_OPENMP}>:_OPENMP>
	$<$<BOOL:${VASP_SCALAPACK}>:scaLAPACK>
	$<$<BOOL:${VASP_HDF5}>:VASP_HDF5>
	$<$<BOOL:${VASP_LIBXC}>:USELIBXC>
	$<$<BOOL:${VASP_WANNIER90}>:VASP2WANNIER90>
	$<$<BOOL:${VASP_CUDA}>:_OPENACC>
	$<$<BOOL:${VASP_CUDA}>:USENCCL>
	$<$<BOOL:${VASP_NCCLP2P}>:USENCCLP2P>
	)

if(VASP_OPENMP)
	find_package(OpenMP MODULE COMPONENTS Fortran CXX REQUIRED)
    list(APPEND VASP_EXTERNAL_LIBS OpenMP::OpenMP_Fortran OpenMP::OpenMP_CXX)
endif()

if(VASP_SCALAPACK)
	find_package(SCALAPACK MODULE REQUIRED)
    list(APPEND VASP_EXTERNAL_LIBS SCALAPACK::SCALAPACK)
endif()

if(VASP_HDF5)
	find_package(HDF5 MODULE COMPONENTS Fortran REQUIRED)
    list(APPEND VASP_EXTERNAL_LIBS hdf5::hdf5_fortran)
endif()

if(VASP_LIBXC)
	find_package(LibXC MODULE REQUIRED)
    list(APPEND VASP_EXTERNAL_LIBS LibXC::libxc)
endif()

if(VASP_WANNIER90)
	find_package(WANNIER90 MODULE REQUIRED)
	list(APPEND VASP_EXTERNAL_LIBS WANNIER90::wannier90)
endif()

#TODO: remaining options
if(VASP_LIBBEEF OR VASP_DFTD4)
	message(FATAL_ERROR "VASP_LIBBEEF and VASP_DFTD4 not yet supported through CMake.")
endif()


find_package(MPI MODULE COMPONENTS Fortran)
list(APPEND VASP_EXTERNAL_LIBS MPI::MPI_Fortran)

set(BLA_SIZEOF_INTEGER 4) # only look for 32-bit BLAS / LAPACK
find_package(BLAS MODULE REQUIRED)
list(APPEND VASP_EXTERNAL_LIBS BLAS::BLAS)

find_package(LAPACK MODULE REQUIRED)
list(APPEND VASP_EXTERNAL_LIBS LAPACK::LAPACK)

# The FindFFTW module will use the blas library if it provides FFTW symbols like MKL or ArmPL
if(VASP_OPENMP)
	find_package(FFTW MODULE REQUIRED COMPONENTS OMP)
	list(APPEND VASP_EXTERNAL_LIBS FFTW::FFTW_OMP)
else()
	find_package(FFTW MODULE REQUIRED COMPONENTS SERIAL)
	list(APPEND VASP_EXTERNAL_LIBS FFTW::FFTW_SERIAL)
endif()


if(VASP_CUDA)
	if(NOT CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
		message(FATAL_ERROR "CUDA accelaration requires NVHPC fortran compiler.")
	endif()

	set(VASP_CUDA_ARCH ${CMAKE_CUDA_ARCHITECTURES})
	list(POP_FRONT VASP_CUDA_ARCH VASP_FIRST_ARCH)
	set(VASP_GPU_FLAG "-gpu=cc${VASP_FIRST_ARCH}")

	foreach(arch IN LISTS VASP_CUDA_ARCH)
		set(VASP_GPU_FLAG "${VASP_GPU_FLAG},cc${arch}")
	endforeach()

	list(APPEND VASP_FORTRAN_FLAGS -acc ${VASP_GPU_FLAG})
	list(APPEND VASP_EXTERNAL_LIBS "-cudalib=cublas,cusolver,cufft,nccl -cuda -acc ${VASP_GPU_FLAG}")
endif()


# set compiler specific settings
# note: free and fixed format flags are set through target properties
if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
	list(APPEND VASP_FORTRAN_FLAGS -ffree-line-length-none -w -ffpe-summary=invalid,zero,overflow -fallow-argument-mismatch)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
	find_package(QD MODULE REQUIRED)
	list(APPEND VASP_EXTERNAL_LIBS QD::qd)
	list(APPEND VASP_DEFINITIONS qd_emulate)
	list(APPEND VASP_FORTRAN_FLAGS -Mbackslash -Mlarge_arrays -Mextend)
endif()


add_subdirectory(src)
