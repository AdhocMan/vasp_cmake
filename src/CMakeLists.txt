function(vasp_create_executable name sources)
	add_executable(${name} ${sources})
	target_compile_definitions(${name} PRIVATE ${VASP_DEFINITIONS})
	target_compile_options(${name} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_FORTRAN_FLAGS}>)
	target_link_libraries(${name} PRIVATE linpack_objects lib_objects parser_objects ${VASP_EXTERNAL_LIBS})
	set_target_properties(${name} PROPERTIES LINKER_LANGUAGE Fortran)
	set_target_properties(${name} PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}_mod_files)
	if(VASP_FFTLIB)
		target_link_libraries(vasp_std PRIVATE fftlib_objects)
	endif()
endfunction()


FILE(GLOB VASP_SOURCES *.F)

# Remove from sources as needed
list(REMOVE_ITEM VASP_SOURCES
	${CMAKE_CURRENT_SOURCE_DIR}/mp2.F # outdated. Only required with scalapack, provided by ump2.F instead
	${CMAKE_CURRENT_SOURCE_DIR}/zdotc.F
	${CMAKE_CURRENT_SOURCE_DIR}/dgemmtest.F
	${CMAKE_CURRENT_SOURCE_DIR}/zgemmtest.F
	${CMAKE_CURRENT_SOURCE_DIR}/ffttest.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dessl+furth.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dcray.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dfujitsu.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dbatched.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dnec.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dessl.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dlib_f77.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dsimple.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dfurth_f77.F
	${CMAKE_CURRENT_SOURCE_DIR}/fft3dfurth.F
	${CMAKE_CURRENT_SOURCE_DIR}/fftw3d+furth.F
	${CMAKE_CURRENT_SOURCE_DIR}/fftmpi.F
	${CMAKE_CURRENT_SOURCE_DIR}/makeparam.F
	)

if(NOT VASP_CUDA)
	list(REMOVE_ITEM VASP_SOURCES
		${CMAKE_CURRENT_SOURCE_DIR}/openacc.F
		)
endif()


if(VASP_FFTLIB)
	add_subdirectory(fftlib)
endif()

add_subdirectory(lib)
add_subdirectory(parser)


vasp_create_executable(vasp_std "${VASP_SOURCES}")
target_compile_definitions(vasp_std PRIVATE NGZhalf)

vasp_create_executable(vasp_gam "${VASP_SOURCES}")
target_compile_definitions(vasp_gam PRIVATE NGZhalf wNGZhalf)
add_dependencies(vasp_gam vasp_std)

vasp_create_executable(vasp_ncl "${VASP_SOURCES}")
add_dependencies(vasp_ncl vasp_gam)

install(TARGETS vasp_std DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS vasp_gam DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS vasp_ncl DESTINATION ${CMAKE_INSTALL_BINDIR})

