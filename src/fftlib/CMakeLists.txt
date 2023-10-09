add_library(fftlib_objects OBJECT
	src/fftlib.cpp
	)

target_link_libraries(fftlib_objects PRIVATE ${VASP_EXTERNAL_LIBS})
set_property(TARGET fftlib_objects PROPERTY CXX_STANDARD 14)
set_property(TARGET fftlib_objects PROPERTY CXX_STANDARD_REQUIRED On)
target_compile_definitions(fftlib_objects PRIVATE FFTLIB_THREADSAFE __fp16=float) #__fp16 in fftw3 not available in pgi / nvhpc and not used in vasp
target_include_directories(fftlib_objects PRIVATE include)
