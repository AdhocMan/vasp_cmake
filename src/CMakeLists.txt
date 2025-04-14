function(vasp_create_executable name sources)
  # preprocessing all sources
  set(PREPROCESSED_DIR "${CMAKE_CURRENT_BINARY_DIR}/${name}")
  file(MAKE_DIRECTORY ${PREPROCESSED_DIR})

  # copy all include files over
  file(GLOB INCLUDE_FILES "${PROJECT_SOURCE_DIR}/src/*.inc")
  foreach(INCLUDE_FILE ${INCLUDE_FILES})
    get_filename_component(FILE_NAME ${INCLUDE_FILE} NAME)
    configure_file(${INCLUDE_FILE} ${PREPROCESSED_DIR}/${FILE_NAME} COPYONLY)
  endforeach()

  # now we have to add the PP options incl vasp version specific ones
  set(PP_DEF_${name} PREPROCESSOR_DEFINITIONS)
  if (${name} STREQUAL "vasp_std")
    list(APPEND PP_DEF_${name} "-DNGZhalf")
  endif()
  if (${name} STREQUAL "vasp_gam")
    list(APPEND PP_DEF_${name} "-DNGZhalf")
    list(APPEND PP_DEF_${name} "-DwNGZhalf")
  endif()
  # Add custom command to run preprocessor
  # without this problems occur with:
  # file dependencies, empty module files, intel oneapi 2025 (no option to pass fpp options)
  # this also cleanly separates the pp part from the build part
  foreach(SOURCE_FILE ${sources})
    get_filename_component(FILE_NAME ${SOURCE_FILE} NAME_WE)
    set(PREPROCESSED_FILE ${PREPROCESSED_DIR}/${FILE_NAME}.f90)

    add_custom_command(
      OUTPUT ${PREPROCESSED_FILE}
      COMMAND ${FPP_COMMAND} ${PREPROCESSOR_DEFINITIONS} ${PROJECT_SOURCE_DIR}/src/${SOURCE_FILE} > ${PREPROCESSED_FILE}
      DEPENDS ${SOURCE_FILE}
      COMMENT "Preprocessing ${SOURCE_FILE}"
    )

    list(APPEND PREPROCESSED_SOURCES ${PREPROCESSED_FILE})
  endforeach()

  # run preprocessing before compiling
  add_custom_target(${name}_pp DEPENDS ${PREPROCESSED_SOURCES})

  # set optimization flags
  foreach(pp_source ${PREPROCESSED_SOURCES})
    get_filename_component(source ${pp_source} NAME_WE)
    set(_opt_flag ${VASP_OFLAG_DEFAULT})
    if(${source}.F IN_LIST VASP_SOURCES_O3)
      set(_opt_flag ${VASP_OFLAG_O3})
    endif()
    if(${source}.F IN_LIST VASP_SOURCES_O2)
      set(_opt_flag ${VASP_OFLAG_O2})
    endif()
    if(${source}.F IN_LIST VASP_SOURCES_O1)
      set(_opt_flag ${VASP_OFLAG_O1})
    endif()
    if(${source}.F IN_LIST VASP_SOURCES_IN)
      set(_opt_flag ${VASP_OFLAG_IN})
    endif()
    if(${source}.F IN_LIST VASP_SOURCES_DEB)
      if(${name} STREQUAL "vasp_std")
        message(STATUS "debugging for ${source} enabled. Flags: ${VASP_OFLAG_DEB}")
      endif()
      set(_opt_flag ${VASP_OFLAG_DEB})
    endif()
    if(${source}.F STREQUAL "main.F")
      set(_opt_flag ${VASP_OFLAG_MAIN})
    endif()
    list(JOIN _opt_flag " " _opt_flag_str) # convert list to string
    set_source_files_properties(${pp_source} PROPERTIES COMPILE_FLAGS ${_opt_flag_str})
  endforeach()

  # now create the actual target
  add_executable(${name} ${PREPROCESSED_SOURCES})

  target_compile_options(${name} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_FORTRAN_FLAGS}>)
  target_link_options(${name} PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_FORTRAN_LINKER_FLAGS}>)
  target_link_libraries(${name} PRIVATE linpack_objects lib_objects parser_objects ${VASP_EXTERNAL_LIBS})
  set_target_properties(${name} PROPERTIES LINKER_LANGUAGE Fortran)
  set_target_properties(${name} PROPERTIES Fortran_MODULE_DIRECTORY ${PREPROCESSED_DIR})
  set_target_properties(${name} PROPERTIES Fortran_FORMAT FREE)
  # making LIB_DIR/mod available for libraries linking LIB
  target_include_directories(${name} INTERFACE ${PREPROCESSED_DIR})
  if(VASP_FFTLIB)
    target_link_libraries(vasp_std PRIVATE fftlib_objects)
  endif()
endfunction()

#--------------------------------------------
# add src files add run custom target command
#--------------------------------------------

# add all source files
set(VASP_SOURCES ${VASP_SOURCES} ${VASP_SOURCES_DEFAULT})
list(APPEND VASP_SOURCES main.F)
list(REMOVE_DUPLICATES VASP_SOURCES)

if(NOT ${VASP_SOURCES_DEB} STREQUAL "")
  message(STATUS "for debug marked files: ${VASP_SOURCES_DEB}")
endif()

# add extra source files for the lib
if(VASP_FFTLIB)
  add_subdirectory(fftlib)
endif()
add_subdirectory(lib)
add_subdirectory(parser)

# here the add_executables are generated via the custom function
vasp_create_executable(vasp_std "${VASP_SOURCES}")
vasp_create_executable(vasp_gam "${VASP_SOURCES}")
vasp_create_executable(vasp_ncl "${VASP_SOURCES}")

install(TARGETS vasp_std DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS vasp_gam DESTINATION ${CMAKE_INSTALL_BINDIR})
install(TARGETS vasp_ncl DESTINATION ${CMAKE_INSTALL_BINDIR})

# if no install prefix is set, use the current source dir/bin folder as in the old build system
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/bin CACHE PATH "Default install path" FORCE)
endif()
