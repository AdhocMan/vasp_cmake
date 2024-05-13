add_library(fftlib_objects OBJECT
    src/fftlib.cpp
    )

target_link_libraries(fftlib_objects PRIVATE ${VASP_EXTERNAL_LIBS})
set_property(TARGET fftlib_objects PROPERTY CXX_STANDARD 14)
set_property(TARGET fftlib_objects PROPERTY CXX_STANDARD_REQUIRED On)
# __fp16 type used by some FFTW implementations not supported by some compilers like nvhpc
target_compile_definitions(fftlib_objects PRIVATE FFTLIB_THREADSAFE __fp16=float)
target_include_directories(fftlib_objects PRIVATE include)
target_compile_options(fftlib_objects PRIVATE ${VASP_OFLAG_DEFAULT})
