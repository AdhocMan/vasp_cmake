set(_VASP_OFLAG_DEFAULT -O2)
set(_VASP_OFLAG_DEB -g)
set(_VASP_OFLAG_O1 -O1)
set(_VASP_OFLAG_O2 -O2)
set(_VASP_OFLAG_O3 -O3)
set(_VASP_OFLAG_MAIN -O0)
set(_VASP_OFLAG_C_LIB -O)
set(_VASP_SOURCES_DEB)
set(_VASP_SOURCES_O1)
set(_VASP_SOURCES_O2)
set(_VASP_SOURCES_O3)
set(_VASP_SOURCES_IN)


# read here all required source files from the .objects file
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

set(_VASP_SOURCES "")


#################################
# Compiler specific modifications
#################################

# IMPORTANT: if the compiler is not identified, the precompiler falls back to gcc

# Languages must be enabled to check compiler id
enable_language(C CXX Fortran)

# now we specify compiler specific options and importantly
# specify how the preprocessor should be called
set(VASP_FORTRAN_FLAGS)
set(VASP_FORTRAN_LINKER_FLAGS)
# note: free and fixed format flags are set through target properties
if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  set(FPP_COMMAND ${CMAKE_Fortran_COMPILER} -E -C -w)
  list(APPEND VASP_FORTRAN_FLAGS -ffree-line-length-none -w -ffpe-summary=invalid,zero,overflow -fallow-argument-mismatch)
  set(_VASP_OFLAG_DEFAULT -O3)
  set(_VASP_OFLAG_DEB -g -Wall -Wextra -Warray-temporaries -Wconversion -fimplicit-none -fbacktrace -ffree-line-length-0 -fcheck=all -ffpe-trap=invalid,zero,overflow,underflow -finit-real=nan)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel" OR CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM")
  set(FPP_COMMAND fpp -f_com=no -free -w0)
  list(APPEND VASP_FORTRAN_FLAGS -w0 -names lowercase -assume byterecl -w)
  set(_VASP_OFLAG_DEFAULT -O2)
  set(_VASP_OFLAG_DEB -g -check all -fpe0 -warn -traceback -debug extended)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
  set(FPP_COMMAND ${CMAKE_Fortran_COMPILER} -Mpreprocess -Mfree -Mextend -E)
  list(APPEND VASP_FORTRAN_FLAGS -Mbackslash -Mlarge_arrays -Mextend)
  list(APPEND VASP_FORTRAN_LINKER_FLAGS -mp -c++libs)
  set(_VASP_OFLAG_DEFAULT -fast)
  set(_VASP_OFLAG_MAIN -O0 -traceback)
  set(_VASP_SOURCES_O1 pade_fit.F minimax_dependence.F)
  set(_VASP_SOURCES_O2 pead.F)
  set(_VASP_OFLAG_DEB -Minfo=all -g -traceback)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Flang")
  set(FPP_COMMAND ${CMAKE_Fortran_COMPILER} -E -ffree-form -C -w)
  set(_VASP_OFLAG_DEFAULT -O2)
  list(APPEND VASP_FORTRAN_FLAGS -ffree-form -ffree-line-length-none -w -fno-fortran-main -Mbackslash)
  set(_VASP_OFLAG_DEB -g)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Fujitsu")
  set(FPP_COMMAND ${CMAKE_Fortran_COMPILER} -Ccpp -E)
  set(_VASP_OFLAG_DEFAULT --Kfast)
  list(APPEND VASP_FORTRAN_FLAGS -Ksimd_nouse_multiple_structures -X03)
  list(APPEND VASP_FORTRAN_LINKER_FLAGS -Kfz,simd_nouse_multiple_structures)
  set(_VASP_SOURCES_O1 elphon_common.F minimax_dependence.F)
  set(_VASP_SOURCES_O2 nonl.F vdw_nl.F)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NFORT")
  set(FPP_COMMAND gcc -E -C -w)
  list(APPEND VASP_FORTRAN_FLAGS -no-ftrace -finline-functions -finline-file=random.f90 -fdiag-parallel=0 -fdiag-vector=0 -fdiag-inline=0 -w)
  list(APPEND VASP_FORTRAN_LINKER_FLAGS -cxxlib)
  set(_VASP_OFLAG_DEFAULT -O3)
  endif()

  if(NOT _VASP_OFLAG_IN)
    set(_VASP_OFLAG_IN ${_VASP_OFLAG_DEFAULT})
  endif()
  if(NOT _VASP_OFLAG_LIB)
    set(_VASP_OFLAG_LIB ${_VASP_OFLAG_O1})
  endif()


  #########################
  # Set user facing options
  #########################

  # set default optimization flags.
  set(VASP_OFLAG_DEFAULT "${_VASP_OFLAG_DEFAULT}" CACHE STRING "Default optimization flag")
  set(VASP_OFLAG_DEB "${_VASP_OFLAG_DEB}" CACHE STRING "")
  set(VASP_OFLAG_O1 "${_VASP_OFLAG_O1}" CACHE STRING "")
  set(VASP_OFLAG_O2 "${_VASP_OFLAG_O2}" CACHE STRING "")
  set(VASP_OFLAG_O3 "${_VASP_OFLAG_O3}" CACHE STRING "")
  set(VASP_OFLAG_LIB "${_VASP_OFLAG_LIB}" CACHE STRING "")
  set(VASP_OFLAG_C_LIB "${_VASP_OFLAG_C_LIB}" CACHE STRING "")
  set(VASP_OFLAG_IN "${_VASP_OFLAG_IN}" CACHE STRING "")
  set(VASP_OFLAG_MAIN "${_VASP_OFLAG_MAIN}" CACHE STRING "")
  set(VASP_SOURCES_DEB "${_VASP_SOURCES_DEB}" CACHE STRING "")
  set(VASP_SOURCES_O1 "${_VASP_SOURCES_O1}" CACHE STRING "")
  set(VASP_SOURCES_O2 "${_VASP_SOURCES_O2}" CACHE STRING "")
  set(VASP_SOURCES_O3 "${_VASP_SOURCES_O3}" CACHE STRING "")
  set(VASP_SOURCES_IN "${_VASP_SOURCES_IN}" CACHE STRING "")
  set(VASP_SOURCES "${_VASP_SOURCES}" CACHE STRING "Additional files to build")
  set(VASP_SOURCES_DEFAULT "${_VASP_SOURCES_DEFAULT}" CACHE STRING "List of default sources to build")
  mark_as_advanced(VASP_SOURCES_DEFAULT) # long list, hide by default in gui



