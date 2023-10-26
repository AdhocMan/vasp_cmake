#.rst:
# FindFFTW
# -----------
#
# This module looks for the fftw3 library.
#
# The following variables are set each compnent, where COMPNENT is SERIAL, OMP or THREADS.
#
# ::
#
#   FFTW_FOUND           - True if double precision fftw library is found
#   FFTW_${COMPONENT}_LIBRARIES       - The required libraries
#   FFTW_${COMPONENT}_INCLUDE_DIRS    - The required include directory
#
# The following import target is created
#
# ::
#
#   FFTW::FFTW_${COMPONENT}

# check if FFTW can be provided by BLAS libraries like MKL and ArmPL
if(NOT TARGET BLAS::BLAS)
    find_package(BLAS MODULE QUIET)
endif()

macro(find_ffftw_component name lib_name lib_symbol)
    # set paths to look for library
    set(_FFTW_${name}_PATHS ${FFTW_${name}_ROOT} $ENV{FFTW_${name}_ROOT})
    set(_FFTW_${name}_INCLUDE_PATHS)

    set(_FFTW_${name}_DEFAULT_PATH_SWITCH)


    if(TARGET BLAS::BLAS)
        set(CMAKE_REQUIRED_LIBRARIES BLAS::BLAS)

        include(CheckFunctionExists)
        unset(FFTW_${name}_BLAS_SYMBOL CACHE) # Result is cached, so change of library will not lead to a new check automatically
        set(CMAKE_REQUIRED_QUIET TRUE)
        CHECK_FUNCTION_EXISTS(${lib_symbol} FFTW_${name}_BLAS_SYMBOL)

        if(FFTW_${name}_BLAS_SYMBOL)
            set(_FFTW_${name}_DEFAULT_PATH_SWITCH NO_DEFAULT_PATH)
            set(FFTW_${name}_LIBRARIES "BLAS::BLAS" CACHE STRING "" FORCE)
            foreach(blas_lib IN LISTS BLAS_LIBRARIES)
                get_filename_component(blas_lib_dir ${blas_lib} DIRECTORY)
                get_filename_component(blas_paraent_lib_dir ${blas_lib_dir} DIRECTORY)
                list(APPEND _FFTW_${name}_PATHS ${blas_lib_dir} ${blas_paraent_lib_dir})
            endforeach()
        endif()
    endif()


    if(_FFTW_${name}_PATHS)
        # disable default paths if ROOT is set
        set(_FFTW_${name}_DEFAULT_PATH_SWITCH NO_DEFAULT_PATH)
    else()
        # try to detect location with pkgconfig
        find_package(PkgConfig QUIET)
        if(PKG_CONFIG_FOUND)
          pkg_check_modules(PKG_FFTW_${name} QUIET "fftw3")
        endif()
        set(_FFTW_${name}_PATHS ${PKG_FFTW_${name}_LIBRARY_DIRS})
        set(_FFTW_${name}_INCLUDE_PATHS ${PKG_FFTW_${name}_INCLUDE_DIRS})
    endif()

    if(NOT FFTW_${name}_LIBRARIES)
        find_library(
            FFTW_${name}_LIBRARIES
            NAMES ${lib_name}
            HINTS ${_FFTW_${name}_PATHS}
            PATH_SUFFIXES "lib" "lib64"
            ${_FFTW_${name}_DEFAULT_PATH_SWITCH}
        )
    endif()

    find_path(FFTW_${name}_INCLUDE_DIRS
        NAMES "fftw3.h"
        HINTS ${_FFTW_${name}_PATHS} ${_FFTW_${name}_INCLUDE_PATHS}
        PATH_SUFFIXES "include_mp" "include" "include_mp/fftw" "include/fftw"
        ${_FFTW_${name}_DEFAULT_PATH_SWITCH}
    )


    # add target to link against
    if(FFTW_${name}_LIBRARIES AND FFTW_${name}_INCLUDE_DIRS)
        if(NOT TARGET FFTW::FFTW_${name})
            add_library(FFTW::FFTW_${name} INTERFACE IMPORTED)
        endif()
        set_property(TARGET FFTW::FFTW_${name} PROPERTY INTERFACE_LINK_LIBRARIES ${FFTW_${name}_LIBRARIES})
        set_property(TARGET FFTW::FFTW_${name} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${FFTW_${name}_INCLUDE_DIRS})
    endif()

    # prevent clutter in cache
    MARK_AS_ADVANCED(FFTW_${name}_LIBRARIES FFTW_${name}_INCLUDE_DIRS pkgcfg_lib_PKG_FFTW_${name}_fftw3)
endmacro()

set(FFTW_COMP SERIAL) # default
if(FFTW_FIND_COMPONENTS)
    set(FFTW_COMP ${FFTW_FIND_COMPONENTS})
endif()

set(FFTW_REQUIRED_VARS)

find_ffftw_component(SERIAL fftw3 fftw_plan_dft)
list(APPEND FFTW_REQUIRED_VARS FFTW_SERIAL_INCLUDE_DIRS FFTW_SERIAL_LIBRARIES)

foreach(comp IN LISTS FFTW_COMP)
    if(${comp} STREQUAL "OMP")
        find_ffftw_component(OMP fftw3_omp fftw_init_threads)
        target_link_libraries(FFTW::FFTW_OMP INTERFACE FFTW::FFTW_SERIAL)
        list(APPEND FFTW_REQUIRED_VARS FFTW_OMP_INCLUDE_DIRS FFTW_OMP_LIBRARIES)
    elseif(${comp} STREQUAL "THREADS")
        find_ffftw_component(THREADS fftw3_threads fftw_init_threads)
        list(APPEND FFTW_REQUIRED_VARS FFTW_THREADS_INCLUDE_DIRS FFTW_THREADS_LIBRARIES)
        target_link_libraries(FFTW::FFTW_THREADS INTERFACE FFTW::FFTW_SERIAL)
    elseif(NOT ${comp} STREQUAL "SERIAL")
        message(FATAL_ERROR "FindFFTW: Illegal component \"${comp}\"")
    endif()
endforeach()

# check if found
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FFTW REQUIRED_VARS ${FFTW_REQUIRED_VARS})
MARK_AS_ADVANCED(FFTW_FOUND)
