#.rst:
# FindWANNIER90
# -----------
#
# This module tries to find the WANNIER90 library.
#
# The following variables are set
#
# ::
#
#   WANNIER90_FOUND           - True if wannier90 is found
#   WANNIER90_LIBRARIES       - The required libraries
#   WANNIER90_INCLUDE_DIRS    - The required include directory
#
# The following import target is created
#
# ::
#
#   WANNIER90::wannier90

#set paths to look for library from ROOT variables.If new policy is set, find_library() automatically uses them.
if(NOT POLICY CMP0074)
    set(_WANNIER90_PATHS ${WANNIER90_ROOT} $ENV{WANNIER90_ROOT})
endif()

find_library(
    WANNIER90_LIBRARIES
    NAMES wannier
    HINTS ${_WANNIER90_PATHS}
    PATH_SUFFIXES "wannier90/lib" "wannier90/lib64" "wannier90" "lib" "lib64"
)
find_path(
    WANNIER90_INCLUDE_DIRS
    NAMES w90_wannierise.mod
    HINTS ${_WANNIER90_PATHS}
    PATH_SUFFIXES "modules" "wannier90/modules" "include" "inc" "wannier90" "wannier90/include" "include/wannier90"
)

# check if found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WANNIER90 REQUIRED_VARS WANNIER90_INCLUDE_DIRS WANNIER90_LIBRARIES)

# add target to link against
if(WANNIER90_FOUND)
    if(NOT TARGET WANNIER90::wannier90)
        add_library(WANNIER90::wannier90 INTERFACE IMPORTED)
    endif()
    set_property(TARGET WANNIER90::wannier90 PROPERTY INTERFACE_LINK_LIBRARIES ${WANNIER90_LIBRARIES})
    set_property(TARGET WANNIER90::wannier90 PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${WANNIER90_INCLUDE_DIRS})
endif()

# prevent clutter in cache
MARK_AS_ADVANCED(WANNIER90_FOUND WANNIER90_LIBRARIES WANNIER90_INCLUDE_DIRS)
