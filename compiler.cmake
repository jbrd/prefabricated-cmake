# Option to control strict compilation (all warnings, warnings as errors)
option(STRICT "Strict compilation (all warnings, warnings as errors) [on/off]" ON)

# Option to explicitly control CXX11 ABI when compiling with GCC on Unix
set(CXX11_ABI "" CACHE STRING "On Linux platforms, if linking against libstdc++, this allows you to explicitly specify whether to use the CXX11 ABI or not [on/off]. If not specified (or left empty), the compiler's default will be used.")

# Set default C++ standard (can be overridden)
set(CMAKE_CXX_STANDARD 17 CACHE STRING "The C++ standard to use (see CMake docs)")

# Apply compiler defaults that are common across all targets
macro(configure_compiler)

	# Expose software version to C++ via compiler definitions.
	add_compile_definitions(PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR})
	add_compile_definitions(PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR})
	add_compile_definitions(PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH})

	# Warning severity (STRICT by default).
	if(${STRICT})
		if(WIN32)
			set(CMAKE_C_FLAGS "/W4 /WX ${CMAKE_C_FLAGS}")
			set(CMAKE_CXX_FLAGS "/W4 /WX ${CMAKE_CXX_FLAGS}")
		else()
			set(CMAKE_C_FLAGS "-Wall -Wextra -Werror -Wmissing-prototypes -Wstrict-prototypes -Wold-style-definition -pedantic-errors ${CMAKE_C_FLAGS}")
			set(CMAKE_CXX_FLAGS "-Wall -Wextra -Werror -pedantic-errors ${CMAKE_CXX_FLAGS}")
		endif()
	endif( )

	# Standard definitions - PUBLIC_API macro for marking symbols to be exported in .dlls
	if(WIN32)
		add_compile_definitions(PUBLIC_API=__declspec\(dllexport\))
	else()
		add_compile_definitions(PUBLIC_API=)
	endif()

	# On Unix platforms, if linking against libstdc++, allow the use of CXX11_ABI to be explicitly specified.
	if(UNIX)
		if(NOT ${CXX11_ABI} STREQUAL "")
			if(${CXX11_ABI} STREQUAL "on")
				add_compile_definitions(_GLIBCXX_USE_CXX11_ABI=1)
			elseif(${CXX11_ABI} STREQUAL "off")
				add_compile_definitions(_GLIBCXX_USE_CXX11_ABI=0)
			else()
				message(FATAL_ERROR "Invalid value '${CXX11_ABI}' specified for CXX11_ABI setting. Expected: [on,off,<empty>]")
			endif()
		endif()
	endif()

	# Make the repository src directory available on the system
	# include search path
	include_directories(${PROJECT_SOURCE_DIR}/src)

	# Use folders to organise Visual Studio projects in Solution Explorer
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)

endmacro()
