# Gathers dependencies for the project.
macro(gather_dependencies)

	# clang-format
	find_program(CLANG_FORMAT NAMES "clang-format" DOC "Path to clang-format executable" HINTS "$ENV{VCINSTALLDIR}/Tools/Llvm/bin")
	if (NOT CLANG_FORMAT)
		message(STATUS "clang-format not found")
	else()
		execute_process(COMMAND clang-format --version OUTPUT_VARIABLE CLANG_FORMAT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
		message(STATUS "${CLANG_FORMAT_VERSION} found: ${CLANG_FORMAT}")
	endif()

	# valgrind
	find_program(VALGRIND valgrind DOC "Valgrind location (optional)")

	# doxygen
	find_package(Doxygen REQUIRED)

	# python3
	find_package(Python3 REQUIRED)

	# sphinx
	find_program(SPHINX NAMES "sphinx-build" DOC "Sphinx (Python Module)")
	if (NOT SPHINX)
		message(FATAL_ERROR "-- Sphinx (Python Module) not found.")
	else()
		message("-- Sphinx (Python Module) found.")
	endif()

	# breathe
	find_program(BREATHE NAMES "breathe-apidoc" DOC "Breathe (Python Module)")
	if (NOT BREATHE)
		message(FATAL_ERROR "-- Breathe (Python Module) not found.")
	else()
		message("-- Breathe (Python Module) found.")
	endif()

	# sphinx_rtd_theme
	execute_process(COMMAND ${Python3_EXECUTABLE} -c "import sphinx_rtd_theme" OUTPUT_QUIET ERROR_QUIET RESULT_VARIABLE RTDTHEME_FAILED)
	if(${RTDTHEME_FAILED})
		message(FATAL_ERROR "-- sphinx-rtd-theme (Python Module) not found.")
	else()
		message("-- sphinx-rtd-theme (Python Module) found.")
	endif()

endmacro(gather_dependencies)

# Set up any additional targets that are provided by dependencies (usually toolchain dependencies)
function(finalise_dependencies)
	get_property(SRC GLOBAL PROPERTY ALL_SOURCES)
	add_custom_target(format COMMAND ${CLANG_FORMAT} -i -style=file ${SRC})
	set_target_properties(format PROPERTIES FOLDER Formatting)
	add_custom_target(format-check COMMAND ${CLANG_FORMAT} -i -style=file --dry-run --Werror --verbose ${SRC})
	set_target_properties(format-check PROPERTIES FOLDER Formatting)
endfunction()
