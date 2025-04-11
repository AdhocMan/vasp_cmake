add_library(linpack_objects OBJECT
  linpack_double.f
)

target_compile_options(linpack_objects PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_LINPACK_FORTRAN_FLAGS}>)
set_target_properties(linpack_objects PROPERTIES Fortran_FORMAT FIXED)

set(PREPROCESSED_SOURCES "")

# Define source files for lib
set(SOURCE_FILES
  preclib.F
  diolib.F
  dlexlib.F
  drdatab.F
  timing_.c
  derrf_.c
  dclock_.c
)

# also here we have to invoke the preprocessor manually for Fortran files
foreach(SOURCE_FILE ${SOURCE_FILES})
  # Extract filename without extension
  get_filename_component(SOURCE_NAME_WE ${SOURCE_FILE} NAME_WE)
  get_filename_component(SOURCE_EXT ${SOURCE_FILE} EXT)
  set(PREPROCESSED_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  file(MAKE_DIRECTORY ${PREPROCESSED_DIR})

  # Define output file with correct suffix
  if(SOURCE_EXT MATCHES "\\.F$")
    set(PREPROCESSED_FILE ${PREPROCESSED_DIR}/${SOURCE_NAME_WE}.f90)
    set(PREPROCESS_COMMAND ${FPP_COMMAND})
    # Custom command to preprocess the file
    add_custom_command(
      OUTPUT ${PREPROCESSED_FILE}
      COMMAND ${PREPROCESS_COMMAND} ${PREPROCESSOR_DEFINITIONS} ${PROJECT_SOURCE_DIR}/src/lib/${SOURCE_FILE} > ${PREPROCESSED_FILE}
      DEPENDS ${PROJECT_SOURCE_DIR}/src/lib/${SOURCE_FILE}
      COMMENT "Preprocessing ${SOURCE_FILE}"
    )
  # for C-files we need to copy the file to the preprocessed directory but no preprocessing necessary
  elseif(SOURCE_EXT MATCHES "\\.c$")
    set(PREPROCESSED_FILE ${PREPROCESSED_DIR}/${SOURCE_NAME_WE}.c)
    configure_file(${SOURCE_FILE} ${PREPROCESSED_DIR}/${SOURCE_NAME_WE}.c COPYONLY)
  endif()

  # Collect preprocessed files
  list(APPEND PREPROCESSED_SOURCES ${PREPROCESSED_FILE})
endforeach()

# Now, use the preprocessed files in the library
add_library(lib_objects OBJECT ${PREPROCESSED_SOURCES})

# Apply the same Fortran properties and compiler options
set_target_properties(lib_objects PROPERTIES Fortran_FORMAT FREE)
target_compile_options(lib_objects PRIVATE
  $<$<COMPILE_LANGUAGE:Fortran>:${VASP_LIB_FORTRAN_FLAGS}>
  $<$<COMPILE_LANGUAGE:Fortran>:${VASP_OFLAG_LIB}>
  $<$<COMPILE_LANGUAGE:C>:${VASP_OFLAG_C_LIB}>)
target_link_options(lib_objects PRIVATE $<$<COMPILE_LANGUAGE:Fortran>:${VASP_FORTRAN_LINKER_FLAGS}>)

if(CMAKE_C_COMPILER_ID STREQUAL "NVHPC")
  target_compile_options(lib_objects PRIVATE $<$<COMPILE_LANGUAGE:C>:--diag_suppress set_but_not_used>)
endif()
