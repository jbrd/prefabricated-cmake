# Useful function to add all subdirectories in the current directory
# during the CMake source tree traversal.
function(add_all_subdirectories ROOT_DIR)

	file(GLOB DIRECTORIES "${ROOT_DIR}/*")
	foreach(DIRECTORY ${DIRECTORIES})
		if(IS_DIRECTORY ${DIRECTORY})
			add_subdirectory(${DIRECTORY})
		endif()
	endforeach()

endfunction(add_all_subdirectories)

# Some IDE-based CMake generators make use of 'source groups' to create
# virtual folders in the IDE's project file for organising source files.
# This function generates cmake source groups for the given set of source
# files using their parent directory structure, such that the virtual
# folders in the IDE project file matches the source file directory structure
function(make_source_groups FILES)

	foreach(FILE ${FILES})
		get_filename_component(DIR ${FILE} DIRECTORY)
		string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" DIR ${DIR})
		string(REPLACE "/" "\\" DIR "${DIR}")
		source_group("${DIR}" FILES ${FILE})
	endforeach(FILE)

endfunction(make_source_groups)

# Gathers the source files for a cmake project by recursively looking for
# .cpp and .h files. It includes .h files such that IDE-based cmake
# generators include them in the resultant IDE project file. It also
# ensures cmake 'source groups' are defined for the set of source files,
# such that subdirectory structure is reflected in resultant IDE project
# files.
function(gather_sources PREFIX SOURCES HEADERS)

	file(GLOB_RECURSE SOURCE_FILES ${PREFIX}/*.cpp)
	file(GLOB_RECURSE HEADER_FILES ${PREFIX}/*.h)
	set(SOURCES_LOCAL ${SOURCE_FILES})
	list(APPEND SOURCES_LOCAL ${HEADER_FILES})
	set(${SOURCES} ${SOURCES_LOCAL} PARENT_SCOPE)
	set(${HEADERS} ${HEADER_FILES} PARENT_SCOPE)
	if(NOT "${SOURCES_LOCAL}" STREQUAL "")
		make_source_groups("${SOURCES_LOCAL}")
	endif()
	foreach(f ${SOURCES_LOCAL})
		set_property(GLOBAL APPEND PROPERTY ALL_SOURCES ${f})
	endforeach()

endfunction(gather_sources)
