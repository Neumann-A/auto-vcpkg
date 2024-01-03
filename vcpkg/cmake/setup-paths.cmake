#[===[.md:
# z_vcpkg_add_fatal_error
Add a fatal error.

```cmake
z_vcpkg_add_fatal_error(<message>...)
```

We use this system, instead of `message(FATAL_ERROR)`,
since cmake prints a lot of nonsense if the toolchain errors out before it's found the build tools.

This `Z_VCPKG_HAS_FATAL_ERROR` must be checked before any filesystem operations are done,
since otherwise you might be doing something with bad variables set up.
#]===]
# this is defined above everything else so that it can be used.
set(Z_VCPKG_FATAL_ERROR)
set(Z_VCPKG_HAS_FATAL_ERROR OFF)
function(z_vcpkg_add_fatal_error ERROR)
    if(NOT Z_VCPKG_HAS_FATAL_ERROR)
        set(Z_VCPKG_HAS_FATAL_ERROR ON PARENT_SCOPE)
        set(Z_VCPKG_FATAL_ERROR "${ERROR}" PARENT_SCOPE)
    else()
        string(APPEND Z_VCPKG_FATAL_ERROR "\n${ERROR}")
    endif()
endfunction()

if(NOT VCPKG_ROOT_DIR)
  z_vcpkg_add_fatal_error("Could not find .vcpkg-root")
endif()

if(DEFINED VCPKG_INSTALLED_DIR)
  set(VCPKG_INSTALLED_DIR "${CMAKE_BINARY_DIR}/vcpkg_installed")
endif()

set(VCPKG_INSTALLED_DIR "${VCPKG_INSTALLED_DIR}"
  CACHE PATH
  "The directory which contains the installed libraries for each triplet" FORCE)

function(z_vcpkg_add_vcpkg_to_cmake_path list suffix)
  set(vcpkg_paths
    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}${suffix}"
    "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug${suffix}"
  )
  if(NOT DEFINED CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE MATCHES "^[Dd][Ee][Bb][Uu][Gg]$")
    list(REVERSE vcpkg_paths) # Debug build: Put Debug paths before Release paths.
  endif()
  if(VCPKG_PREFER_SYSTEM_LIBS)
    list(APPEND "${list}" "${vcpkg_paths}")
  else()
    list(INSERT "${list}" "0" "${vcpkg_paths}") # CMake 3.15 is required for list(PREPEND ...).
  endif()
  set("${list}" "${${list}}" PARENT_SCOPE)
endfunction()
z_vcpkg_add_vcpkg_to_cmake_path(CMAKE_PREFIX_PATH "")
z_vcpkg_add_vcpkg_to_cmake_path(CMAKE_LIBRARY_PATH "/lib/manual-link")
z_vcpkg_add_vcpkg_to_cmake_path(CMAKE_FIND_ROOT_PATH "")

if(NOT VCPKG_PREFER_SYSTEM_LIBS)
  set(CMAKE_FIND_FRAMEWORK "LAST") # we assume that frameworks are usually system-wide libs, not vcpkg-built
  set(CMAKE_FIND_APPBUNDLE "LAST") # we assume that appbundles are usually system-wide libs, not vcpkg-built
endif()

# If one CMAKE_FIND_ROOT_PATH_MODE_* variables is set to ONLY, to  make sure that ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}
# and ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug are searched, it is not sufficient to just add them to CMAKE_FIND_ROOT_PATH,
# as CMAKE_FIND_ROOT_PATH specify "one or more directories to be prepended to all other search directories", so to make sure that
# the libraries are searched as they are, it is necessary to add "/" to the CMAKE_PREFIX_PATH
if(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE STREQUAL "ONLY" OR
   CMAKE_FIND_ROOT_PATH_MODE_LIBRARY STREQUAL "ONLY" OR
   CMAKE_FIND_ROOT_PATH_MODE_PACKAGE STREQUAL "ONLY")
   list(APPEND CMAKE_PREFIX_PATH "/")
endif()

set(VCPKG_CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}")


if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(Z_VCPKG_EXECUTABLE "${VCPKG_ROOT_DIR}/vcpkg.exe")
    set(Z_VCPKG_BOOTSTRAP_SCRIPT "${VCPKG_ROOT_DIR}/bootstrap-vcpkg.bat")
else()
    set(Z_VCPKG_EXECUTABLE "${VCPKG_ROOT_DIR}/vcpkg")
    set(Z_VCPKG_BOOTSTRAP_SCRIPT "${VCPKG_ROOT_DIR}/bootstrap-vcpkg.sh")
endif()

