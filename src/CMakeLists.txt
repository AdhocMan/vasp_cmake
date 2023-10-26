function(vasp_create_executable name sources)
	add_executable(${name} ${sources})
	target_compile_definitions(${name} PRIVATE ${VASP_DEFINITIONS})
	target_compile_options(${name} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_FORTRAN_FLAGS}>)
	target_link_libraries(${name} PRIVATE linpack_objects lib_objects parser_objects ${VASP_EXTERNAL_LIBS})
	set_target_properties(${name} PROPERTIES LINKER_LANGUAGE Fortran)
	set_target_properties(${name} PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}_mod_files)
	set_target_properties(${name} PROPERTIES Fortran_FORMAT FREE)
	if(VASP_FFTLIB)
		target_link_libraries(vasp_std PRIVATE fftlib_objects)
	endif()
endfunction()


file(READ ".objects" VASP_OBJECTS_CONTENT)

string(REGEX MATCHALL "[a-zA-Z_0-9-]+\.o" VASP_OBJECTS ${VASP_OBJECTS_CONTENT})

set(VASP_SOURCES)
foreach(object IN LISTS VASP_OBJECTS)
    string(REGEX REPLACE "\\.[^.]*$" "" file_name ${object})
    list(APPEND VASP_SOURCES ${file_name}.F)
endforeach()

list(APPEND VASP_SOURCES fftmpiw.F fftmpi_map.F fftw3d.F fft3dlib.F main.F)
list(REMOVE_ITEM VASP_SOURCES
	wave_gpu.F # does not exist
	)
if(NOT VASP_CUDA)
	list(REMOVE_ITEM VASP_SOURCES
		openacc.F # issues when compiling without nvfortran. Not required without CUDA.
		)
endif()
list(REMOVE_DUPLICATES VASP_SOURCES)

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

