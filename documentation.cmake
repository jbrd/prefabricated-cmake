set(DOC_TEMPLATE_ROOT ${CMAKE_CURRENT_LIST_DIR}/docs)

# Allow Doxygen.in to be overridden in the project root directory.
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
	set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile.in)
else()
	set(DOXYGEN_IN ${DOC_TEMPLATE_ROOT}/Doxyfile.in)
endif()
message("-- Using Doxygen.In Template: ${DOXYGEN_IN}")

# Add a documentation target for the current directory.
function(add_documentation)

	# Does a docs folder exist?
	if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Docs)

		# Yes - add this folder to the global list of documentation folders so that
		# they can be consolidated when the docs target is built
		set_property(GLOBAL APPEND PROPERTY ALL_DOC_FOLDERS ${CMAKE_CURRENT_SOURCE_DIR}/Docs)

		# Generate Doxygen XML for this component (so that it can be referenced by
		# this components' documentation).
		configure_file(${DOXYGEN_IN} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)
		add_custom_target(${TARGET}_Doxygen
			${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
			WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
		)
		set_target_properties(${TARGET}_Doxygen PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD TRUE)
		set_target_properties(${TARGET}_Doxygen PROPERTIES FOLDER Documentation)
		set_property(GLOBAL APPEND PROPERTY ALL_DOXYGEN_TARGETS ${TARGET}_Doxygen)
		set_property(GLOBAL APPEND_STRING PROPERTY ALL_BREATHE_PROJECTS "'${TARGET}': '${CMAKE_CURRENT_BINARY_DIR}/xml/',")

	endif()
endfunction()

# This function should be called once all of the documentation targets have been
# declared. This function is responsible for adding the root-level docs target.
function(finalise_docs)

	# Configure conf.py.
	get_property(BREATHE_PROJECTS GLOBAL PROPERTY ALL_BREATHE_PROJECTS)
	configure_file(${DOC_TEMPLATE_ROOT}/sphinx/source/conf.py ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/configured/conf.py)

	# Copy doc/sphinx into the current binary directory, excluding index.rst
	# Then copy project-level documentation into the destination docs folder.
	add_custom_target(copy_sphinx_files)
	add_custom_command(TARGET copy_sphinx_files PRE_BUILD COMMAND ${CMAKE_COMMAND} ARGS -E copy_directory ${DOC_TEMPLATE_ROOT}/sphinx ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx)
	add_custom_command(TARGET copy_sphinx_files POST_BUILD COMMAND ${CMAKE_COMMAND} ARGS -E copy_directory ${PROJECT_SOURCE_DIR}/docs/sphinx ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx)

	# Copy each component's Docs folder into the destination docs folder. Whilst doing so,
	# built a Sphinx toctree that can be substituted into index.rst when it is configured.
	add_custom_target(copy_doc_folders)
	set(COMPONENT_TOCTREE "")
	get_property(DOC_FOLDERS GLOBAL PROPERTY ALL_DOC_FOLDERS)
	foreach (DOC_FOLDER ${DOC_FOLDERS})
		get_filename_component(COMPONENT_FOLDER ${DOC_FOLDER} DIRECTORY)
		get_filename_component(COMPONENT_NAME ${COMPONENT_FOLDER} NAME)
		add_custom_command(TARGET copy_doc_folders PRE_BUILD COMMAND ${CMAKE_COMMAND} -E copy_directory ${DOC_FOLDER} ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/${COMPONENT_NAME})
		set(COMPONENT_TOCTREE "${COMPONENT_TOCTREE}\n   ${COMPONENT_NAME}/index")
	endforeach()

	# Now that we have built the components toctree, we can configure index.rst.
	add_custom_target(copy_configured_doc_files)
	if (EXISTS ${PROJECT_SOURCE_DIR}/docs/sphinx/source/index.rst)
		set(INDEX_RST ${PROJECT_SOURCE_DIR}/docs/sphinx/source/index.rst)
	else()
		set(INDEX_RST ${DOC_TEMPLATE_ROOT}/sphinx/source/index.rst)
	endif()
	configure_file(${INDEX_RST} ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/configured/index.rst)
	add_custom_command(
		TARGET copy_configured_doc_files PRE_BUILD COMMAND ${CMAKE_COMMAND} -E copy
		${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/configured/conf.py
		${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/configured/index.rst
		${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source)

	# Now generate the docs target, which will invoke Sphinx to generate the docs.
	if (WIN32)
		set(SPHINX_COMMAND make.bat)
	else()
		set(SPHINX_COMMAND make)
	endif()
	
	add_custom_target(docs
		${SPHINX_COMMAND} html
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx
	)
	add_dependencies(docs copy_configured_doc_files)
	add_dependencies(copy_configured_doc_files copy_doc_folders)
	add_dependencies(copy_doc_folders copy_sphinx_files)

	set_target_properties(docs PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD TRUE)
	set_target_properties(docs PROPERTIES FOLDER Documentation)

	# Ensure all doxygen targets are added as dependencies of the docs target.
	get_property(DOXYGEN_TARGETS GLOBAL PROPERTY ALL_DOXYGEN_TARGETS)
	if (DEFINED DOXYGEN_TARGETS)
		add_dependencies(docs ${DOXYGEN_TARGETS})
	endif()

	# The install step copies the directory into . To reduce build times, the docs target is
	# NOT added to the ALL target. A consequence of this is that the docs target might not have
	# been built when running make install. So this install step is optional, and the project's
	# root-level makefile is responsible for ensuring that the docs target is always built before
	# the installation step.
	install(DIRECTORY ${DOC_TEMPLATE_ROOT}/sphinx/build/html/ DESTINATION docs OPTIONAL PATTERN docs/sphinx/build/html/*)

endfunction()
