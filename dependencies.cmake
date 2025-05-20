# Option to control strict compilation (all warnings, warnings as errors)
option(CLANG_FORMAT "Include Clang Format targets [on/off]" ON)
option(VALGRIND "Additionally run unit tests through Valgrind memcheck (if installed, Linux only) [on/off]" ON)
set(VALGRIND_ARGS "" CACHE STRING "Additional arguments to pass Valgrind memcheck")

# Gathers dependencies for the project.
macro(gather_dependencies)

	# clang-format
	if (${CLANG_FORMAT})
		find_program(CLANG_FORMAT_PATH NAMES "clang-format" DOC "Path to clang-format executable" HINTS "$ENV{VCINSTALLDIR}/Tools/Llvm/bin")
		if (NOT CLANG_FORMAT_PATH)
			message(STATUS "clang-format not found")
		else()
			execute_process(COMMAND clang-format --version OUTPUT_VARIABLE CLANG_FORMAT_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
			message(STATUS "${CLANG_FORMAT_VERSION} found: ${CLANG_FORMAT_PATH}")
		endif()
	endif()

	# valgrind
	if (${VALGRIND})
		find_program(VALGRIND_PATH valgrind DOC "Valgrind location (optional)")
	endif()

	# documentation dependencies
	gather_documentation_dependencies()

endmacro(gather_dependencies)

# Set up any additional targets that are provided by dependencies (usually toolchain dependencies)
function(finalise_dependencies)
	get_property(SRC GLOBAL PROPERTY ALL_SOURCES)
	if (${CLANG_FORMAT})
		add_custom_target(format COMMAND ${CLANG_FORMAT_PATH} -i -style=file ${SRC})
		set_target_properties(format PROPERTIES FOLDER Formatting)
		add_custom_target(format-check COMMAND ${CLANG_FORMAT_PATH} -i -style=file --dry-run --Werror --verbose ${SRC})
		set_target_properties(format-check PROPERTIES FOLDER Formatting)
	endif()
endfunction()
