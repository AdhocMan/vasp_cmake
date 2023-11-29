macro(set_mode_flags languages mode value)
	foreach(lang ${languages})
		set(CMAKE_${lang}_FLAGS_${mode} "${value}" CACHE STRING "")
	endforeach()
endmacro()

# set default language flags. Must be called before language is enabled.
set_mode_flags("C;CXX;Fortran" "DEBUG" "-g")
set_mode_flags("C;CXX;Fortran" "RELWITHDEBINFO" "-g -DNDEBUG")
set_mode_flags("C;CXX;Fortran" "RELEASE" "-DNDEBUG")
set_mode_flags("C;CXX;Fortran" "MINSIZEREL" "-DNDEBUG")

set(_VASP_OFLAG_DEFAULT -O2)
set(_VASP_OFLAG_O1 -O1)
set(_VASP_OFLAG_O2 -O2)
set(_VASP_OFLAG_O3 -O3)
set(_VASP_OFLAG_LIB -O1)
set(_VASP_SOURCES_O1)
set(_VASP_SOURCES_O2)
set(_VASP_SOURCES_O3)

set(VASP_FORTRAN_FLAGS)

# Languages must be enabled to check compiler id
enable_language(C CXX Fortran)

# note: free and fixed format flags are set through target properties
if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
	list(APPEND VASP_FORTRAN_FLAGS -ffree-line-length-none -w -ffpe-summary=invalid,zero,overflow -fallow-argument-mismatch)
    set(_VASP_SOURCES_O1 fftw3d.F fftmpi.F fftmpiw.F)
    set(_VASP_SOURCES_O2 fft3dlib.F)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
	list(APPEND VASP_FORTRAN_FLAGS -Mbackslash -Mlarge_arrays -Mextend -Minform=severe)
    set(_VASP_OFLAG_DEFAULT -fast)
    set(_VASP_SOURCES_O1 pade_fit.F minimax_dependence.F)
    set(_VASP_SOURCES_O2 pead.F)
endif()
