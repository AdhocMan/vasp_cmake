set(_VASP_OFLAG_DEFAULT -O2)
set(_VASP_OFLAG_O1 -O1)
set(_VASP_OFLAG_O2 -O2)
set(_VASP_OFLAG_O3 -O3)
set(_VASP_OFLAG_IN ${_VASP_OFLAG_DEFAULT})
set(_VASP_OFLAG_LIB ${_VASP_OFLAG_O1})
set(_VASP_SOURCES_O1)
set(_VASP_SOURCES_O2)
set(_VASP_SOURCES_O3)
set(_VASP_SOURCES_IN)


file(READ "${PROJECT_SOURCE_DIR}/src/.objects" VASP_OBJECTS_CONTENT)

# convert a string containing object file names to a list of fortran files with ".F" suffix
function(objects_to_fortran_files objects_string out_var_name)
	string(REGEX MATCHALL "[a-zA-Z_0-9-]+\.o" objects ${objects_string})
	set(_files)
	foreach(obj IN LISTS objects)
		string(REGEX REPLACE "\\.[^.]*$" "" file_name ${obj})
		list(APPEND _files ${file_name}.F)
	endforeach()
	set(${out_var_name}  ${_files} PARENT_SCOPE)
endfunction()

string(REGEX MATCH ".*SOURCE_O1" _VASP_OBJECTS ${VASP_OBJECTS_CONTENT})
string(REGEX MATCH "SOURCE_O1.*SOURCE_O2" _VASP_OBJECTS_O1 ${VASP_OBJECTS_CONTENT})
string(REGEX MATCH "SOURCE_O2.*SOURCE_IN" _VASP_OBJECTS_O2 ${VASP_OBJECTS_CONTENT})
string(REGEX MATCH "SOURCE_IN.*" _VASP_OBJECTS_IN ${VASP_OBJECTS_CONTENT})
objects_to_fortran_files(${_VASP_OBJECTS} _VASP_SOURCES_DEFAULT)
objects_to_fortran_files(${_VASP_OBJECTS_O1} _VASP_SOURCES_O1)
objects_to_fortran_files(${_VASP_OBJECTS_O2} _VASP_SOURCES_O2)
objects_to_fortran_files(${_VASP_OBJECTS_IN} _VASP_SOURCES_IN)

set(_VASP_SOURCES "fftmpiw.F;fftmpi_map.F;fftw3d.F;fft3dlib.F")


#################################
# Compiler specific modifications
#################################

# Languages must be enabled to check compiler id
enable_language(C CXX Fortran)

set(VASP_FORTRAN_FLAGS)
# note: free and fixed format flags are set through target properties
if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
	list(APPEND VASP_FORTRAN_FLAGS -ffree-line-length-none -w -ffpe-summary=invalid,zero,overflow -fallow-argument-mismatch)
	# extend list of specially optimized files
	list(APPEND _VASP_SOURCES_O1 fftw3d.F fftmpi.F fftmpiw.F)
	list(APPEND _VASP_SOURCES_O2 fft3dlib.F)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
	list(APPEND VASP_FORTRAN_FLAGS -Mbackslash -Mlarge_arrays -Mextend -Minform=severe)
    set(_VASP_OFLAG_DEFAULT -fast)
	# overwrite list of specially optimized files
    set(_VASP_SOURCES_O1 pade_fit.F minimax_dependence.F)
    set(_VASP_SOURCES_O2 pead.F)
endif()


#########################
# Set user facing options
#########################

# set default optimization flags. Input from cmake/default_flags.cmake
set(VASP_OFLAG_DEFAULT "${_VASP_OFLAG_DEFAULT}" CACHE STRING "Default optimization flag")
set(VASP_OFLAG_O1 "${_VASP_OFLAG_O1}" CACHE STRING "")
set(VASP_OFLAG_O2 "${_VASP_OFLAG_O2}" CACHE STRING "")
set(VASP_OFLAG_O3 "${_VASP_OFLAG_O3}" CACHE STRING "")
set(VASP_OFLAG_LIB "${_VASP_OFLAG_LIB}" CACHE STRING "")
set(VASP_OFLAG_IN "${_VASP_OFLAG_IN}" CACHE STRING "")
set(VASP_SOURCES_O1 "${_VASP_SOURCES_O1}" CACHE STRING "")
set(VASP_SOURCES_O2 "${_VASP_SOURCES_O2}" CACHE STRING "")
set(VASP_SOURCES_O3 "${_VASP_SOURCES_O3}" CACHE STRING "")
set(VASP_SOURCES_IN "${_VASP_SOURCES_IN}" CACHE STRING "")
set(VASP_SOURCES "${_VASP_SOURCES}" CACHE STRING "Additional files to build")
set(VASP_SOURCES_DEFAULT "${_VASP_SOURCES_DEFAULT}" CACHE STRING "List of default sources to build")
mark_as_advanced(VASP_SOURCES_DEFAULT) # long list, hide by default in gui



