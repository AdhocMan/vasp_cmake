add_library(parser_objects OBJECT
	sites.cpp functions.cpp radial.cpp basis.cpp
	lex.yy.c locproj.tab.c yywrap.c
	)
set_source_files_properties(lex.yy.c locproj.tab.c yywrap.c PROPERTIES LANGUAGE CXX)

target_link_libraries(parser_objects PRIVATE ${VASP_EXTERNAL_LIBS})
set_property(TARGET parser_objects PROPERTY CXX_STANDARD 14)
set_property(TARGET parser_objects PROPERTY CXX_STANDARD_REQUIRED On)
# __fp16 type used by some FFTW implementations not supported by some compilers like nvhpc
target_compile_definitions(parser_objects PRIVATE YY_parse_DEBUG=1 __fp16=float)
target_compile_options(parser_objects PRIVATE ${VASP_OFLAG_DEFAULT})
