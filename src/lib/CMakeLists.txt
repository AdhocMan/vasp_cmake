add_library(linpack_objects OBJECT
	linpack_double.f
	)

target_compile_options(linpack_objects PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_LINPACK_FORTRAN_FLAGS}>)
set_target_properties(linpack_objects PROPERTIES Fortran_FORMAT FIXED)

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
set_target_properties(lib_objects PROPERTIES Fortran_FORMAT FREE)
target_compile_options(lib_objects PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_LIB_FORTRAN_FLAGS}> ${VASP_OFLAG_LIB})
