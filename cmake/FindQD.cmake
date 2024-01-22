#.rst:
# FindQD
# -----------
#
# This module tries to find the QD library.
#
# The following variables are set
#
# ::
#
#   QD_FOUND           - True if qd is found
#   QD_LIBRARIES       - The required libraries
#   QD_INCLUDE_DIRS    - The required include directory
#
# The following import target is created
#
# ::
#
#   QD::qd

#set paths to look for library from ROOT variables.If new policy is set, find_library() automatically uses them.
if(NOT POLICY CMP0074)
    set(_QD_PATHS ${QD_ROOT} $ENV{QD_ROOT})
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
    get_filename_component(QD_PREFIX_PATH ${CMAKE_Fortran_COMPILER} DIRECTORY)
    set(_QD_PATHS ${_QD_PATHS} ${QD_PREFIX_PATH})
    get_filename_component(QD_PREFIX_PATH ${QD_PREFIX_PATH} DIRECTORY)
    set(_QD_PATHS ${_QD_PATHS} ${QD_PREFIX_PATH})
    get_filename_component(QD_PREFIX_PATH ${QD_PREFIX_PATH} DIRECTORY)
    set(_QD_PATHS ${_QD_PATHS} ${QD_PREFIX_PATH})
    get_filename_component(QD_PREFIX_PATH ${QD_PREFIX_PATH} DIRECTORY)
    set(_QD_PATHS ${_QD_PATHS} ${QD_PREFIX_PATH})
endif()

find_library(
    QD_LIBRARIES
    NAMES qd
    HINTS ${_QD_PATHS}
    PATH_SUFFIXES "qd/lib" "qd/lib64" "qd" "compilers/extras/qd/lib"
)
find_library(
    QD_FORTRAN_LIBRARIES
    NAMES qdmod
    HINTS ${_QD_PATHS}
    PATH_SUFFIXES "qd/lib" "qd/lib64" "qd" "compilers/extras/qd/lib"
)
find_path(
    QD_INCLUDE_DIRS
    NAMES qdmodule.mod
    HINTS ${_QD_PATHS}
    PATH_SUFFIXES "modules" "qd/modules" "qd" "qd/include" "include/qd" "compilers/extras/qd/include/qd"
)

# check if found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(QD REQUIRED_VARS QD_INCLUDE_DIRS QD_LIBRARIES QD_FORTRAN_LIBRARIES)

# add target to link against
if(QD_FOUND)
    if(NOT TARGET QD::qd)
        add_library(QD::qd INTERFACE IMPORTED)
    endif()
    set_property(TARGET QD::qd PROPERTY INTERFACE_LINK_LIBRARIES ${QD_LIBRARIES} ${QD_FORTRAN_LIBRARIES})
    set_property(TARGET QD::qd PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${QD_INCLUDE_DIRS})
endif()

# prevent clutter in cache
MARK_AS_ADVANCED(QD_FOUND QD_LIBRARIES QD_INCLUDE_DIRS)
