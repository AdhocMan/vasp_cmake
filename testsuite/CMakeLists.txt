message(STATUS "-------- preparing testsuite ------------")

add_custom_target(copy_tests
	COMMAND ${CMAKE_COMMAND} -E copy_directory_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/"
        "${CMAKE_CURRENT_BINARY_DIR}"
    COMMENT "Copying testsuite"
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

# add test command for fast testsuite
add_custom_target(test
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/runtest --fast 2>&1 | tee testsuite.log
    COMMENT "Run the fast testsuite"
)
add_dependencies(test copy_tests)

add_custom_target(test_all
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/runtest --all 2>&1 | tee testsuite.log
    COMMENT "Run the full testsuite"
)
add_dependencies(test_all copy_tests)

