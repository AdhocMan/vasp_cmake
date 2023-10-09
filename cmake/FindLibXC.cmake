#.rst:
# FindLibXC
# -----------
#
# This module tries to find the LibXC library.
#
# The following variables are set
#
# ::
#
#   LibXC_FOUND           - True if libxc is found
#   LibXC_LIBRARIES       - The required libraries
#   LibXC_INCLUDE_DIRS    - The required include directory
#
# The following import target is created
#
# ::
#
#   LibXC::libxc

#set paths to look for library from ROOT variables.If new policy is set, find_library() automatically uses them.
if(NOT POLICY CMP0074)
    set(_LibXC_PATHS ${LibXC_ROOT} $ENV{LibXC_ROOT})
endif()

find_library(
    LibXC_LIBRARIES
    NAMES xc
    HINTS ${_LibXC_PATHS}
    PATH_SUFFIXES "libxc/lib" "libxc/lib64" "libxc"
)
find_library(
    LibXC_FORTRAN_LIBRARIES
    NAMES xcf03
    HINTS ${_LibXC_PATHS}
    PATH_SUFFIXES "libxc/lib" "libxc/lib64" "libxc"
)
find_path(
    LibXC_INCLUDE_DIRS
    NAMES xc.h xc_f90_types_m.mod
    HINTS ${_LibXC_PATHS}
    PATH_SUFFIXES "inc" "libxc" "libxc/include" "include/libxc"
)

# check if found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibXC REQUIRED_VARS LibXC_INCLUDE_DIRS LibXC_LIBRARIES LibXC_FORTRAN_LIBRARIES)

# add target to link against
if(LibXC_FOUND)
    if(NOT TARGET LibXC::libxc)
        add_library(LibXC::libxc INTERFACE IMPORTED)
    endif()
    set_property(TARGET LibXC::libxc PROPERTY INTERFACE_LINK_LIBRARIES ${LibXC_LIBRARIES} ${LibXC_FORTRAN_LIBRARIES})
    set_property(TARGET LibXC::libxc PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${LibXC_INCLUDE_DIRS})
endif()

# prevent clutter in cache
MARK_AS_ADVANCED(LibXC_FOUND LibXC_LIBRARIES LibXC_INCLUDE_DIRS)
