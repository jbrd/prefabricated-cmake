set(DOC_TEMPLATE_ROOT ${CMAKE_CURRENT_LIST_DIR}/docs)

# Add a documentation target for the current directory.
function(add_documentation)

	# Does a docs folder exist?
	if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Docs)

		# Yes - add this folder to the global list of documentation folders so that
		# they can be consolidated when the docs target is built
		set_property(GLOBAL APPEND PROPERTY ALL_DOC_FOLDERS ${CMAKE_CURRENT_SOURCE_DIR}/Docs)

		# Generate Doxygen XML for this component (so that it can be referenced by
		# this components' documentation).
		configure_file(${DOC_TEMPLATE_ROOT}/Doxyfile.in ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)
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

	# Copy doc/sphinx into the current binary directory
	file(COPY ${DOC_TEMPLATE_ROOT}/sphinx DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/docs)

	# Configure conf.py.
	get_property(BREATHE_PROJECTS GLOBAL PROPERTY ALL_BREATHE_PROJECTS)
	configure_file(${DOC_TEMPLATE_ROOT}/sphinx/source/conf.py ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/conf.py)

	# Copy each component's Docs folder into the destination docs folder. Whilst doing so,
	# built a Sphinx toctree that can be substituted into index.rst when it is configured.
	set(COMPONENT_TOCTREE "")
	get_property(DOC_FOLDERS GLOBAL PROPERTY ALL_DOC_FOLDERS)
	foreach (DOC_FOLDER ${DOC_FOLDERS})
		get_filename_component(COMPONENT_FOLDER ${DOC_FOLDER} DIRECTORY)
		get_filename_component(COMPONENT_NAME ${COMPONENT_FOLDER} NAME)
		file(COPY ${DOC_FOLDER}/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/${COMPONENT_NAME})
		set(COMPONENT_TOCTREE "${COMPONENT_TOCTREE}\n   ${COMPONENT_NAME}/index")
	endforeach()

	# Copy project-level documentation into the destination docs folder.
	file(GLOB PROJECT_DOC_FILES "${PROJECT_SOURCE_DIR}/docs/*")
	foreach(PROJECT_DOC_FILE ${PROJECT_DOC_FILES})
		file(COPY ${PROJECT_DOC_FILE} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source)
		message(INFO "Copying '${PROJECT_DOC_FILE}' to '${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source'")
	endforeach()

	# Now that we have built the components toctree, we can configure index.rst.
	file(RENAME ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/index.rst ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/index.rst.template)
	configure_file(${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/index.rst.template ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/index.rst)
	file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx/source/index.rst.template)

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

	set_target_properties(docs PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD TRUE)
	set_target_properties(docs PROPERTIES FOLDER Documentation)

	# Ensure all doxygen targets are added as dependencies of the docs target.
	get_property(DOXYGEN_TARGETS GLOBAL PROPERTY ALL_DOXYGEN_TARGETS)
	if (${DOXYGEN_TARGETS})
		add_dependencies(docs ${DOXYGEN_TARGETS})
	endif()

	# The install step copies the directory into . To reduce build times, the docs target is
	# NOT added to the ALL target. A consequence of this is that the docs target might not have
	# been built when running make install. So this install step is optional, and the project's
	# root-level makefile is responsible for ensuring that the docs target is always built before
	# the installation step.
	install(DIRECTORY ${DOC_TEMPLATE_ROOT}/sphinx/build/html/ DESTINATION docs OPTIONAL PATTERN docs/sphinx/build/html/*)

endfunction()
