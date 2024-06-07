# Apply compiler defaults that are common across all targets
macro(configure_compiler)

	# Expose software version to C++ via compiler definitions.
	add_compile_definitions(PROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR})
	add_compile_definitions(PROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR})
	add_compile_definitions(PROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH})

	# Warning severity (STRICT by default).
	set( STRICT True CACHE BOOL "Enable strict mode (on by default)" )
	if( STRICT )
		if( WIN32 )
			set( CMAKE_C_FLAGS "/W4 /WX ${CMAKE_C_FLAGS}" )
			set( CMAKE_CXX_FLAGS "/W4 /WX ${CMAKE_CXX_FLAGS}" )
		else()
			set( CMAKE_C_FLAGS "-Wall -Wextra -Werror -Wmissing-prototypes -Wstrict-prototypes -Wold-style-definition -pedantic-errors ${CMAKE_C_FLAGS}" )
			set( CMAKE_CXX_FLAGS "-Wall -Wextra -Werror -pedantic-errors ${CMAKE_CXX_FLAGS}" )
		endif()
	endif( )

	# Standard definitions - PUBLIC_API macro for marking symbols to be exported in .dlls
	if( WIN32 )
		add_compile_definitions(PUBLIC_API=__declspec\(dllexport\))
	else()
		add_compile_definitions(PUBLIC_API=)
	endif()

	# Make the repository src directory available on the system
	# include search path
	include_directories(${PROJECT_SOURCE_DIR}/src)

	# Use folders to organise Visual Studio projects in Solution Explorer
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)

endmacro()
