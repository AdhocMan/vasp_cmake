#.rst:
# FindSCALAPACK
# -----------
#
# This module searches for the ScaLAPACK library.
#
# The following variables are set
#
# ::
#
#   SCALAPACK_FOUND           - True if double precision ScaLAPACK library is found
#   SCALAPACK_FLOAT_FOUND     - True if single precision ScaLAPACK library is found
#   SCALAPACK_LIBRARIES       - The required libraries
#   SCALAPACK_INCLUDE_DIRS    - The required include directory
#
# The following import target is created
#
# ::
#
#   SCALAPACK::SCALAPACK



# set paths to look for library
set(_SCALAPACK_PATHS ${SCALAPACK_ROOT} $ENV{SCALAPACK_ROOT})
set(_SCALAPACK_INCLUDE_PATHS)

set(_SCALAPACK_DEFAULT_PATH_SWITCH)

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
    NAMES "scalapack" "scalapack-mpich" "scalapack-openmpi"
    HINTS ${_SCALAPACK_PATHS}
    PATH_SUFFIXES "lib" "lib64"
    ${_SCALAPACK_DEFAULT_PATH_SWITCH}
)

# check if found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SCALAPACK REQUIRED_VARS SCALAPACK_LIBRARIES )


# add target to link against
if(SCALAPACK_FOUND)
    if(NOT TARGET SCALAPACK::SCALAPACK)
        add_library(SCALAPACK::SCALAPACK INTERFACE IMPORTED)
    endif()
    set_property(TARGET SCALAPACK::SCALAPACK PROPERTY INTERFACE_LINK_LIBRARIES ${SCALAPACK_LIBRARIES})
endif()

# prevent clutter in cache
MARK_AS_ADVANCED(SCALAPACK_FOUND SCALAPACK_LIBRARIES SCALAPACK_INCLUDE_DIRS pkgcfg_lib_PKG_SCALAPACK_scalapack )
