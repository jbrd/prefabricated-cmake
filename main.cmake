cmake_minimum_required(VERSION 3.28)

include(${CMAKE_CURRENT_LIST_DIR}/compiler.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/dependencies.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/documentation.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/platform.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sources.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/targets.cmake)

macro(build_components)
    set(PROJECT_ABI_VERSION ${PROJECT_VERSION_MAJOR})

    apply_platform_quirks()
    configure_compiler()
    gather_dependencies()
    enable_testing()

    add_all_subdirectories(src)

    finalise_dependencies()
    finalise_docs()
endmacro()