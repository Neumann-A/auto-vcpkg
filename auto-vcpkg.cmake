cmake_minimum_required(VERSION 3.26)

include(CMakeDependentOption)

option(BUILD_SHARED_LIBS "Build shared libraries." OFF)

### General CMake setup for using vcpkg
if(NOT DEFINED CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL)
    set(CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL "MinSizeRel;Release;None;") # None is for Debian system packages
    if(VCPKG_VERBOSE)
        message(STATUS "VCPKG-Info: CMAKE_MAP_IMPORTED_CONFIG_MINSIZEREL set to MinSizeRel;Release;None;")
    endif()
endif()
if(NOT DEFINED CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO)
    set(CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO "RelWithDebInfo;Release;None;") # None is for Debian system packages
    if(VCPKG_VERBOSE)
        message(STATUS "VCPKG-Info: CMAKE_MAP_IMPORTED_CONFIG_RELWITHDEBINFO set to RelWithDebInfo;Release;None;")
    endif()
endif()

list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES VCPKG_HOST_TRIPLET VCPKG_TARGET_TRIPLET)

if(CMAKE_CROSSCOMPILING AND NOT DEFINED VCPKG_HOST_TRIPLET)
  message(SEND_ERROR "Unable to use auto-vcpkg if CMAKE_CROSSCOMPILING is used and VCPKG_HOST_TRIPLET is not defined! Please set VCPKG_HOST_TRIPLET to a valid value! auto-vcpkg is unable to deduce/generate a valid VCPKG_HOST_TRIPLET by itself!")
endif()

# VCPKG toolchain options.
option(VCPKG_VERBOSE "Enables messages from the VCPKG toolchain for debugging purposes." OFF)
mark_as_advanced(VCPKG_VERBOSE)

option(VCPKG_USE_SINGLE_CONFIG "Enable usage of a single config triplet!" OFF)
mark_as_advanced(VCPKG_USE_SINGLE_CONFIG)

# Manifest options and settings
if(NOT DEFINED VCPKG_MANIFEST_DIR)
    if(EXISTS "${CMAKE_SOURCE_DIR}/vcpkg/manifest/vcpkg.json")
        set(VCPKG_MANIFEST_DIR "${CMAKE_SOURCE_DIR}/vcpkg/manifest/")
    endif()
endif()
set(VCPKG_MANIFEST_DIR "${VCPKG_MANIFEST_DIR}" CACHE PATH "The path to the vcpkg manifest directory." FORCE)

set(VCPKG_BOOTSTRAP_OPTIONS "${VCPKG_BOOTSTRAP_OPTIONS}" CACHE STRING "Additional options to bootstrap vcpkg" FORCE)
set(VCPKG_OVERLAY_PORTS "${VCPKG_OVERLAY_PORTS}" CACHE STRING "Overlay ports to use for vcpkg install in manifest mode" FORCE)
set(VCPKG_OVERLAY_TRIPLETS "${VCPKG_OVERLAY_TRIPLETS}" CACHE STRING "Overlay triplets to use for vcpkg install in manifest mode" FORCE)
set(VCPKG_INSTALL_OPTIONS "${VCPKG_INSTALL_OPTIONS}" CACHE STRING "Additional install options to pass to vcpkg" FORCE)

set(VCPKG_GENERATE_DIR "${CMAKE_BINARY_DIR}/vcpkg-gen" CACHE STRING "Additional install options to pass to vcpkg" FORCE)
list(PREPEND VCPKG_OVERLAY_TRIPLETS "${VCPKG_GENERATE_DIR}")

get_property(Z_VCPKG_CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)
if(NOT Z_VCPKG_CMAKE_IN_TRY_COMPILE)
    include(FetchContent)
    message(STATUS "Fetching vcpkg!")
    FetchContent_Populate(
    vcpkg
    GIT_REPOSITORY https://github.com/microsoft/vcpkg.git
    GIT_TAG        master
    # If you ahve no asset cache defined or cache the DOWNLOADS folders nowhere always use master to avoid issues with MSYS getting outdated.
    # Port versions are pinned by defining a baseline in vcpkg-configuration.json or in the manifest
    SOURCE_DIR     "${CMAKE_SOURCE_DIR}/vcpkg/registry"
    QUIET
    )

    set(VCPKG_ROOT_DIR "${vcpkg_SOURCE_DIR}" CACHE INTERNAL "" )
endif()

include("${CMAKE_CURRENT_LIST_DIR}/vcpkg/cmake/setup-paths.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/vcpkg/cmake/vcpkg-find-package.cmake")


if(NOT Z_VCPKG_CMAKE_IN_TRY_COMPILE)
    include("${CMAKE_CURRENT_LIST_DIR}/vcpkg/cmake/generate-triplet.cmake")
    if(NOT CMAKE_CROSSCOMPILING)
        set(VCPKG_HOST_TRIPLET "${VCPKG_TARGET_TRIPLET}")
    endif()
    include("${CMAKE_CURRENT_LIST_DIR}/vcpkg/cmake/run-vcpkg.cmake")
endif()



list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
            VCPKG_TARGET_TRIPLET
            VCPKG_HOST_TRIPLET
            VCPKG_ROOT_DIR
)

if(Z_VCPKG_FATAL_ERROR)
    message(SEND_ERROR "${Z_VCPKG_FATAL_ERROR}")
endif()