# Applies platform-specific quirks.
macro(apply_platform_quirks)

    # On Windows, translate CMAKE_SIZEOF_VOID_P into a Visual Studio
    # compatible architecture variable.
	if (${CMAKE_SIZEOF_VOID_P} EQUAL "8")
		set(ARCH "x64")
	else()
		set(ARCH "Win32")
	endif()

	# The Windows dynamic linker doesn't support RPATH. So, to ensure that we can directly
	# run or debug the executable targets in this project, without having to perform an
	# install step, we ensure that all runtime binaries are written to the same directory,
	# so that the linker can find any dependency .dlls.
	if (WIN32)
		set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
		set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
	endif()

endmacro()

# Private function to add an origin to the given executable's RPATH such that shared libraries
# are searched for in the same directory as the executable itself (for the platforms that need
# it, some platforms do this by default anyway, e.g. Windows). This is necessary for the components
# that are defined as runtime libraries (they are considered private to the project and therefore
# deployed to the bin directory rather than the lib directory)
function(add_rpath_origin TARGET)
	if(APPLE)
		set_property(TARGET ${TARGET} PROPERTY INSTALL_RPATH "@loader_path")
	elseif(UNIX)
		set_property(TARGET ${TARGET} PROPERTY INSTALL_RPATH "$ORIGIN")
	endif()
endfunction()
