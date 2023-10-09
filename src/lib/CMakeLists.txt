
if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
	set(LINPACK_FORTRAN_FLAGS)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
	set(LINPACK_FORTRAN_FLAGS -Mfixed)
endif()

add_library(linpack_objects OBJECT
	linpack_double.f
	)

target_compile_options(linpack_objects PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${LINPACK_FORTRAN_FLAGS}>)

if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
	set(LIB_FORTRAN_FLAGS -ffree-form -ffree-line-length-none)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "NVHPC")
	set(LIB_FORTRAN_FLAGS -Mfixed -Mfree)
endif()


add_library(lib_objects OBJECT
	preclib.F
	timing_.c
	derrf_.c
	dclock_.c
	diolib.F
	dlexlib.F
	drdatab.F
	)

target_link_libraries(lib_objects PRIVATE ${VASP_EXTERNAL_LIBS} linpack_objects)
target_compile_options(lib_objects PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${LIB_FORTRAN_FLAGS}>)
