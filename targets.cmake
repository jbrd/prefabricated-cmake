# Applies target properties that are common to all targets in this repository.
# Override this function to apply common modifications to all targets
function(apply_common_target_properties TARGET)
endfunction()

# Applies target properties that are common to all targets in this repository.
function(apply_internal_target_properties TARGET)

	# Common target properties
	apply_common_target_properties(${TARGET})

	# Set version properties.
	set_target_properties(${TARGET} PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION ${PROJECT_ABI_VERSION})

	# Add the 'Public' and 'Private' directories to the include path.
	target_include_directories(${TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Private)
	target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/Public)

endfunction()

# Private function to add a test target to the project.
function(add_test_target TARGET SOURCES)
	add_executable(${TARGET} ${SOURCES})
	apply_common_target_properties(${TARGET})
	add_test(NAME ${TARGET} COMMAND $<TARGET_FILE:${TARGET}> WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
	if(${VALGRIND})
		if(VALGRIND_PATH)
			set(MEMCHECK_ARGS --tool=memcheck --leak-check=full --error-exitcode=1 ${VALGRIND_ARGS})
			add_test(NAME ${TARGET}_memcheck COMMAND ${VALGRIND_PATH} ${MEMCHECK_ARGS} $<TARGET_FILE:${TARGET}> WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
		endif()
	endif()
endfunction()

# Check whether there is a Tests directory. If so, add a corresponding test target.
function(gather_tests TARGET LABEL SOURCES)
	gather_sources("Tests" TEST_SOURCES TEST_HEADERS)
	if(NOT "${TEST_SOURCES}" STREQUAL "")
		set(COMBINED_SOURCES ${TEST_SOURCES})
		list(APPEND COMBINED_SOURCES ${SOURCES})
		add_test_target(${TARGET}_Tests "${COMBINED_SOURCES}")
		target_include_directories(${TARGET}_Tests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/Private)
		apply_internal_target_properties(${TARGET}_Tests)
		set_property(TARGET ${TARGET}_Tests PROPERTY PROJECT_LABEL ${LABEL}_Tests)
	endif()
endfunction()

# Use this when the current directory represents an executable program component.
# Programs are assumed to be public and are therefore included in the install target
# for the project.
function(add_component_program)

	# Use current directory name as component name
	get_filename_component(TARGET ${CMAKE_CURRENT_SOURCE_DIR} NAME)

	# Gather source files and header files from Private directory only.
	gather_sources("Private" PRIVATE_SOURCES PRIVATE_HEADERS)

	# Add executable target.
	add_executable(${TARGET} ${PRIVATE_SOURCES})
	apply_internal_target_properties(${TARGET})

	# Executable targets are given an $ORIGIN RPATH because (private) runtime
	# library components are deployed to the bin directory.
	add_rpath_origin(${TARGET})

	# Executable targets are deployed to the bin directory.
	install(TARGETS ${TARGET} DESTINATION bin)

	# Keep track of all executable targets.
	set_property(GLOBAL APPEND PROPERTY ALL_EXECUTABLE_TARGETS ${TARGET})

endfunction()

# Use this when the current directory represents a public library. Public libraries
# are included in the install target for the project, as are the corresponding header
# files. Both static and shared library variants are created to allow the consumer of
# the library to choose static or dynamic linking according to their requirements.
function(add_component_public_library)

	# Use current directory name as component name
	get_filename_component(TARGET ${CMAKE_CURRENT_SOURCE_DIR} NAME)

	# Gather source files and header files from Public and Private directories.
	gather_sources("Private" PRIVATE_SOURCES PRIVATE_HEADERS)
	gather_sources("Public" PUBLIC_SOURCES PUBLIC_HEADERS)
	set(SOURCES ${PRIVATE_SOURCES} ${PUBLIC_SOURCES})

	# Both static and shared libraries are made for public libraries (to give
	# library consumers choice over linkage). To avoid compiling source files
	# twice, source files are compiled under an objlib first, and then the objlib
	# is compiled into the shared and static targets afterwards.
	add_library(${TARGET} OBJECT ${SOURCES})
	set_property(TARGET ${TARGET} PROPERTY POSITION_INDEPENDENT_CODE 1)
	apply_internal_target_properties(${TARGET})

	# Add static library target.
	add_library(${TARGET}_Static STATIC $<TARGET_OBJECTS:${TARGET}>)
	apply_internal_target_properties(${TARGET}_Static)
	set_target_properties(${TARGET}_Static PROPERTIES FOLDER "Object Libraries")

	# Add shared library target.
	add_library(${TARGET}_Shared SHARED $<TARGET_OBJECTS:${TARGET}>)
	apply_internal_target_properties(${TARGET}_Shared)
	set_target_properties(${TARGET}_Shared PROPERTIES FOLDER "Object Libraries")

	# On Windows, .lib files are generated for both static and dynamic libraries
	# so the '_Static' and '_Shared' suffixes are kept to avoid conflicts. On other
	# platforms, the suffix is stripped.
	if(NOT WIN32)
		set_property(TARGET ${TARGET}_Static PROPERTY OUTPUT_NAME ${TARGET})
		set_property(TARGET ${TARGET}_Shared PROPERTY OUTPUT_NAME ${TARGET})
	endif()

	# Install the static and shared library to the lib directory.
	install(TARGETS ${TARGET}_Static LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
	install(TARGETS ${TARGET}_Shared LIBRARY DESTINATION lib)

	# Install public header files only to the include directory.
	install(FILES ${PUBLIC_HEADERS} DESTINATION include/)

	# Gather tests for this component
	gather_tests(${TARGET} ${TARGET} "${SOURCES}")

	# Add doxygen target to project.
	add_documentation()

endfunction()

# Use this when the current directory represents a private static library. Static
# libraries are not deployed as part of the install target for the project and
# are only available for static linking at build time.
function(add_component_static_library)

	# Use current directory name as component name
	get_filename_component(TARGET ${CMAKE_CURRENT_SOURCE_DIR} NAME)

	# Gather source files and header files from Public and Private directories.
	gather_sources("Private" PRIVATE_SOURCES PRIVATE_HEADERS)
	gather_sources("Public" PUBLIC_SOURCES PUBLIC_HEADERS)
	set(SOURCES ${PRIVATE_SOURCES} ${PUBLIC_SOURCES})

	# Add static library target.
	add_library(${TARGET}_Static STATIC ${SOURCES})
	apply_internal_target_properties(${TARGET}_Static)
	set_property(TARGET ${TARGET}_Static PROPERTY PROJECT_LABEL ${TARGET})

	# Gather tests for this component
	gather_tests(${TARGET}_Static ${TARGET} "${SOURCES}")

	# Add doxygen target to project.
	add_documentation()

endfunction()

# Use this when the current directory represents a private runtime library.
# Runtime libraries are only available for dynamic linking at build time
# and may also be dynamically loaded at runtime (via dlopen, LoadModule, etc).
#
# Runtime libraries are considered private to the project, so header files are not
# included as part of the install target and the library itself is not available for
# linking outside the project (e.g. not deployed to lib).
#
# The install location of a runtime library can be controlled with the optional
# `DESTINATION <arg>` argument, which can be useful when the runtime library is a
# plug-in that needs to be installed in some non-standard location dictated by the
# host application. If this argument is not specified, runtime libraries are deployed
# to the binaries folder by default.
function(add_component_runtime_library)

	# Optional argument defaults
	set(DESTINATION bin)

	# Iterate each argument, looking for optional arguments.
	set(OPTIONAL_ARG 0)
	set(INDEX 0)
	while(${INDEX} LESS ${ARGC})
		set(VALUE ${ARGV${INDEX}})
		if(${VALUE} STREQUAL DESTINATION)
			set(OPTIONAL_ARG 1)
		else()
			if (${OPTIONAL_ARG} EQUAL 0)
				message(FATAL_ERROR "add_component_runtime_library - unexpected optional argument")
			else()
				if (${OPTIONAL_ARG} EQUAL 1)
					set(DESTINATION ${VALUE})
					set(OPTIONAL_ARG 0)
				endif()
			endif()
		endif()
		math(EXPR INDEX ${INDEX}+1)
	endwhile()

	# Use current directory name as component name
	get_filename_component(TARGET ${CMAKE_CURRENT_SOURCE_DIR} NAME)

	# Gather source files and header files from Public and Private directories.
	gather_sources("Private" PRIVATE_SOURCES PRIVATE_HEADERS)
	gather_sources("Public" PUBLIC_SOURCES PUBLIC_HEADERS)
	set(SOURCES ${PRIVATE_SOURCES} ${PUBLIC_SOURCES})

	# Add shared library target.
	add_library(${TARGET}_Shared SHARED ${SOURCES})
	apply_internal_target_properties(${TARGET}_Shared)

	# Private runtime libraries have their 'lib' prefix removed to make them
	# easier to dlopen.
	set_property(TARGET ${TARGET}_Shared PROPERTY OUTPUT_NAME ${TARGET})
	set_property(TARGET ${TARGET}_Shared PROPERTY PREFIX "")
	set_property(TARGET ${TARGET}_Shared PROPERTY PROJECT_LABEL ${TARGET})

	# Private runtime libraries are deployed to the bin directory.
	install(TARGETS ${TARGET}_Shared LIBRARY DESTINATION ${DESTINATION} RUNTIME DESTINATION ${DESTINATION})

	# Gather tests for this component
	gather_tests(${TARGET}_Shared ${TARGET} "${SOURCES}")

	# Add doxygen target to project.
	add_documentation()

endfunction()

# Use this when the current directory represents a test executable. Test executables
# are considered private to the project and are therefore ignored by the install
# target. Test executables are automatically added to the test target for the
# project.
function(add_component_test)

	# Use current directory name as component name
	get_filename_component(TARGET ${CMAKE_CURRENT_SOURCE_DIR} NAME)

	# Gather tests for this component
	gather_sources("Tests" TEST_SOURCES TEST_HEADERS)
	if(NOT "${TEST_SOURCES}" STREQUAL "")
		add_test_target(${TARGET}_Tests ${TEST_SOURCES})
		apply_internal_target_properties(${TARGET}_Tests)
	endif()

endfunction()

# Sets dependencies for the component in the current directory.
#
# This function expects a list of arguments, for example:
#
#	set_component_dependencies(
#		SHARED arg1 arg2 ...
#		STATIC arg3 arg4 ...
#		SYSTEM arg5 arg6 ...
#	)
#
# where:
#
#	SHARED specifies to dynamically link against the following components
#	STATIC specifies to statically link against the following components
#	SYSTEM specifies to link against the following system libraries
#
function(set_component_dependencies)

	# Use current directory name as component name
	get_filename_component(TARGET ${CMAKE_CURRENT_SOURCE_DIR} NAME)

	# Iterate each argument, looking for SHARED/STATIC/SYSTEM directives. If any of these
	# are encountered then the loop will treat all subsequent arguments accordingly.
	set(ARRAY 0)
	set(INDEX 0)
	set(SUFFIX "")
	while(${INDEX} LESS ${ARGC})
		set(VALUE ${ARGV${INDEX}})
		if(${VALUE} STREQUAL SHARED)
			set(ARRAY 1)
			set(SUFFIX "_Shared")
		elseif(${VALUE} STREQUAL STATIC)
			set(ARRAY 2)
			set(SUFFIX "_Static")
		elseif(${VALUE} STREQUAL SYSTEM)
			set(ARRAY 3)
			set(SUFFIX "")
		else()
			if (${ARRAY} EQUAL 0)
				message(FATAL_ERROR "add_component_dependencies - expected either SHARED, STATIC, or SYSTEM")
			else()
				if (TARGET ${TARGET})
					target_link_libraries(${TARGET} ${VALUE}${SUFFIX})
					if (TARGET ${VALUE}${SUFFIX})
						add_dependencies(${TARGET} ${VALUE}${SUFFIX})
					endif()
				endif()
				if (TARGET ${TARGET}_Shared)
					target_link_libraries(${TARGET}_Shared ${VALUE}${SUFFIX})
					if (TARGET ${VALUE}${SUFFIX})
						add_dependencies(${TARGET}_Shared ${VALUE}${SUFFIX})
					endif()
				endif()
				if (TARGET ${TARGET}_Tests)
					target_link_libraries(${TARGET}_Tests ${VALUE}${SUFFIX})
					if (TARGET ${VALUE}${SUFFIX})
						add_dependencies(${TARGET}_Tests ${VALUE}${SUFFIX})
					endif()
				endif()
			endif()
		endif()
		math(EXPR INDEX ${INDEX}+1)
	endwhile()

endfunction()