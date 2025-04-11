message(STATUS "-------- preparing testsuite ------------")

# copy all files
file(COPY
  "${CMAKE_CURRENT_SOURCE_DIR}/"
  DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
)

# build compare numbertable
add_executable(compare_numbertable_new tools/compare_numbertable_new.f90)
set_target_properties(compare_numbertable_new
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/tools"
)
set_target_properties(compare_numbertable_new PROPERTIES Fortran_FORMAT FREE)

# Set executable permissions for the runtest script
execute_process(COMMAND chmod +x "${CMAKE_BINARY_DIR}/testsuite/runtest")

# add test command
if(DEFINED ENV{VASP_TESTSUITE_RUN_FAST})
    set(VASP_TESTSUITE_RUN_FAST $ENV{VASP_TESTSUITE_RUN_FAST})
else()
    set(VASP_TESTSUITE_RUN_FAST True)
endif()

# add test command for fast testsuite
add_custom_target(test
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/runtest --fast 2>&1 | tee testsuite.log
    COMMENT "Run the fast testsuite"
)

add_custom_target(test_all
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/runtest --all 2>&1 | tee testsuite.log
    COMMENT "Run the full testsuite"
)

