#.rst:
# FindFFTWOMP
# -----------
#
# This module looks for the fftw3 library.
#
# The following variables are set
#
# ::
#
#   FFTWOMP_FOUND           - True if double precision fftw library is found
#   FFTWOMP_LIBRARIES       - The required libraries
#   FFTWOMP_INCLUDE_DIRS    - The required include directory
#
# The following import target is created
#
# ::
#
#   FFTWOMP::FFTWOMP



# set paths to look for library
set(_FFTWOMP_PATHS ${FFTWOMP_ROOT} $ENV{FFTWOMP_ROOT})
set(_FFTWOMP_INCLUDE_PATHS)

set(_FFTWOMP_DEFAULT_PATH_SWITCH)

if(_FFTWOMP_PATHS)
    # disable default paths if ROOT is set
    set(_FFTWOMP_DEFAULT_PATH_SWITCH NO_DEFAULT_PATH)
else()
    # try to detect location with pkgconfig
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
      pkg_check_modules(PKG_FFTWOMP QUIET "fftw3")
    endif()
    set(_FFTWOMP_PATHS ${PKG_FFTWOMP_LIBRARY_DIRS})
    set(_FFTWOMP_INCLUDE_PATHS ${PKG_FFTWOMP_INCLUDE_DIRS})
endif()


find_library(
    FFTWOMP_LIBRARIES
    NAMES "fftw3_omp"
    HINTS ${_FFTWOMP_PATHS}
    PATH_SUFFIXES "lib" "lib64"
    ${_FFTWOMP_DEFAULT_PATH_SWITCH}
)
find_path(FFTWOMP_INCLUDE_DIRS
    NAMES "fftw3.h"
    HINTS ${_FFTWOMP_PATHS} ${_FFTWOMP_INCLUDE_PATHS}
    PATH_SUFFIXES "include" "include/fftw"
    ${_FFTWOMP_DEFAULT_PATH_SWITCH}
)

# check if found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FFTWOMP REQUIRED_VARS FFTWOMP_INCLUDE_DIRS FFTWOMP_LIBRARIES )

# add target to link against
if(FFTWOMP_FOUND)
    if(NOT TARGET FFTWOMP::FFTWOMP)
        add_library(FFTWOMP::FFTWOMP INTERFACE IMPORTED)
    endif()
    set_property(TARGET FFTWOMP::FFTWOMP PROPERTY INTERFACE_LINK_LIBRARIES ${FFTWOMP_LIBRARIES})
    set_property(TARGET FFTWOMP::FFTWOMP PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${FFTWOMP_INCLUDE_DIRS})
endif()

# prevent clutter in cache
MARK_AS_ADVANCED(FFTWOMP_FOUND FFTWOMP_LIBRARIES FFTWOMP_INCLUDE_DIRS pkgcfg_lib_PKG_FFTWOMP_fftw3)
