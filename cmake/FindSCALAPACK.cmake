set(_SCALAPACK_PATHS ${SCALAPACK_ROOT} $ENV{SCALAPACK_ROOT})
list(APPEND _SCALAPACK_PATHS ${CMAKE_LIBRARY_PATH_LIST})
set(MKLROOT $ENV{MKLROOT})
set(_SCALAPACK_INCLUDE_PATHS)
set(_SCALAPACK_DEFAULT_PATH_SWITCH)

# First try to see if the user has its own build scalapack library and prioritize it 
if(_SCALAPACK_PATHS)
  # disable default paths if ROOT is set
  set(_SCALAPACK_DEFAULT_PATH_SWITCH NO_DEFAULT_PATH)
else()
  # try to detect location with pkgconfig
  find_package(PkgConfig QUIET)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(PKG_SCALAPACK QUIET "scalapack")
  endif()
  set(_SCALAPACK_PATHS ${PKG_SCALAPACK_LIBRARY_DIRS})
  set(_SCALAPACK_INCLUDE_PATHS ${PKG_SCALAPACK_INCLUDE_DIRS})
endif()

find_library(
  SCALAPACK_LIBRARIES
  NAMES scalapack scalapack-mpich scalapack-openmpi
  HINTS ${_SCALAPACK_PATHS}
  PATH_SUFFIXES "lib" "lib64"
  ${_SCALAPACK_DEFAULT_PATH_SWITCH}
)

# if we did not find it yet and LAPACK is provided by Intel MKL try this
if(NOT SCALAPACK_LIBRARIES AND LAPACK_LIBRARIES MATCHES "mkl")

  # check first if we are using openmpi
  set (MPI_IS_OMPI FALSE)
  execute_process(COMMAND grep -i "OMPI_MPI" ${MPI_Fortran_F77_HEADER_DIR}/mpi.h
    RESULT_VARIABLE MPI_GREP_RESULT
    OUTPUT_QUIET
    ERROR_QUIET)

  if(MPI_GREP_RESULT EQUAL 0)
    set(MPI_MODE openmpi)
  else()
    set(MPI_MODE intelmpi)
  endif()

  # now check if lapack is lp or ilp
  if(LAPACK_LIBRARIES MATCHES "lp64")
    set(SCALAPACK_MODE "lp64")
  elseif(LAPACK_LIBRARIES MATCHES "ilp64")
    set(SCALAPACK_MODE "ilp64")
  endif()

  # Use Intel MKL libraries for Scalapack and BLACS
  if(${SCALAPACK_MODE} STREQUAL "lp64")
    set(MKL_SCALAPACK_NAMES mkl_scalapack_lp64)
    set(MKL_BLACS_MPI_NAMES mkl_blacs_${MPI_MODE}_lp64)
  elseif(${SCALAPACK_MODE} STREQUAL "ilp64")
    set(MKL_SCALAPACK_NAMES mkl_scalapack_ilp64)
    set(MKL_BLACS_MPI_NAMES mkl_blacs_${$MPI_MODE}_ilp64)
  endif()

  find_library(
    MKL_SCALAPACK_LIBRARY
    NAMES ${MKL_SCALAPACK_NAMES}
    HINTS ${_SCALAPACK_PATHS} ${MKLROOT}
    PATH_SUFFIXES "lib" "lib64" "lib/intel64"
  )

  find_library(
    MKL_BLACS_LIBRARY
    NAMES ${MKL_BLACS_MPI_NAMES}
    HINTS ${_SCALAPACK_PATHS} ${MKLROOT}
    PATH_SUFFIXES "lib" "lib64" "lib/intel64"
  )

  if(MKL_SCALAPACK_LIBRARY AND MKL_BLACS_LIBRARY)
    if(NOT SCALAPACK_MESSAGE_SHOWN)
      message(STATUS "Found ScaLAPACK provided via Intel MKL")
    endif()
    set(SCALAPACK_LIBRARIES ${MKL_SCALAPACK_LIBRARY} ${MKL_BLACS_LIBRARY})
  else()
    message(STATUS "Could not find Intel MKL Scalapack or BLACS libraries")
  endif()
endif()

# if we did not find it till here throy an error
if(NOT SCALAPACK_LIBRARIES)
  message(FATAL_ERROR "Could not find Scalapack libraries, please specify SCALAPACK_ROOT")
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SCALAPACK REQUIRED_VARS SCALAPACK_LIBRARIES)

# add target to link against
if(SCALAPACK_FOUND)
  if(NOT TARGET SCALAPACK::SCALAPACK)
    add_library(SCALAPACK::SCALAPACK INTERFACE IMPORTED)
  endif()
  set_property(TARGET SCALAPACK::SCALAPACK PROPERTY INTERFACE_LINK_LIBRARIES ${SCALAPACK_LIBRARIES})
  set(SCALAPACK_MESSAGE_SHOWN TRUE CACHE INTERNAL "Message shown flag")
endif()

# prevent clutter in cache
mark_as_advanced(SCALAPACK_FOUND SCALAPACK_LIBRARIES SCALAPACK_INCLUDE_DIRS pkgcfg_lib_PKG_SCALAPACK_scalapack )
