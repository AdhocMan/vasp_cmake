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


set(VASP_SOURCES ${VASP_SOURCES} ${VASP_SOURCES_DEFAULT})
list(APPEND VASP_SOURCES main.F)

list(REMOVE_ITEM VASP_SOURCES
    wave_gpu.F # does not exist
    )
if(NOT VASP_CUDA)
    list(REMOVE_ITEM VASP_SOURCES
        openacc.F # issues when compiling without nvfortran. Not required without CUDA.
        )
endif()
list(REMOVE_DUPLICATES VASP_SOURCES)

# set optmization flags
foreach(source IN LISTS VASP_SOURCES)
    set(_opt_flag ${VASP_OFLAG_DEFAULT})
    if(${source} IN_LIST VASP_SOURCES_O3)
        set(_opt_flag ${VASP_OFLAG_O3})
    endif()
    if(${source} IN_LIST VASP_SOURCES_O2)
        set(_opt_flag ${VASP_OFLAG_O2})
    endif()
    if(${source} IN_LIST VASP_SOURCES_O1)
        set(_opt_flag ${VASP_OFLAG_O1})
    endif()
    if(${source} IN_LIST VASP_SOURCES_IN)
        set(_opt_flag ${VASP_OFLAG_IN})
    endif()
    if(${source} STREQUAL "main.F")
        set(_opt_flag ${VASP_OFLAG_MAIN})
    endif()
    list(JOIN _opt_flag " " _opt_flag_str) # convert list to string
    set_source_files_properties(${source} PROPERTIES COMPILE_FLAGS ${_opt_flag_str})
endforeach()

if(VASP_FFTLIB)
    add_subdirectory(fftlib)
endif()

add_subdirectory(lib)
add_subdirectory(parser)


vasp_create_executable(vasp_std "${VASP_SOURCES}")
target_compile_definitions(vasp_std PRIVATE NGZhalf)

vasp_create_executable(vasp_gam "${VASP_SOURCES}")
target_compile_definitions(vasp_gam PRIVATE NGZhalf wNGZhalf)

vasp_create_executable(vasp_ncl "${VASP_SOURCES}")

install(TARGETS vasp_std DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS vasp_gam DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS vasp_ncl DESTINATION ${CMAKE_INSTALL_BINDIR})

