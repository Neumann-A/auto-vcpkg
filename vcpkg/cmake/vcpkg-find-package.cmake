option(VCPKG_TRACE_FIND_PACKAGE "Trace calls to find_package()" OFF)

# Backcompat for _find_package in vcpkg-cmake-wrapper.cmake
macro(_find_package z_vcpkg_find_package_package_name)
  find_package(${z_vcpkg_find_package_package_name} ${ARGN} BYPASS_PROVIDER)
endmacro()

# NOTE: this is not a function, which means that arguments _are not_ perfectly forwarded
# this is fine for `find_package`, since there are no usecases for `;` in arguments,
# so perfect forwarding is not important
set(z_vcpkg_find_package_backup_id "0")
macro(vcpkg_find_package dep_method z_vcpkg_find_package_package_name)
  if(VCPKG_TRACE_FIND_PACKAGE)
    string(REPEAT "  " "${z_vcpkg_find_package_backup_id}" z_vcpkg_find_package_indent)
    string(JOIN " " z_vcpkg_find_package_argn ${ARGN})
    message(STATUS "${z_vcpkg_find_package_indent}find_package(${z_vcpkg_find_package_package_name} ${z_vcpkg_find_package_argn})")
    unset(z_vcpkg_find_package_argn)
    unset(z_vcpkg_find_package_indent)
  endif()

  if(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_in_wrapper AND
     "${z_vcpkg_find_package_package_name}" STREQUAL "${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_NAME}")
    ## Somebody overwrote find_package make sure we don't do further recursive calls by bypassing the provider
    find_package(${z_vcpkg_find_package_package_name} ${ARGN} BYPASS_PROVIDER)
  endif()
  
  math(EXPR z_vcpkg_find_package_backup_id "${z_vcpkg_find_package_backup_id} + 1")
  set(z_vcpkg_find_package_package_name "${z_vcpkg_find_package_package_name}")
  set(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_NAME "${z_vcpkg_find_package_package_name}")
  set(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_ARGN "${ARGN}")
  set(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_vars "")

  string(TOLOWER "${z_vcpkg_find_package_package_name}" z_vcpkg_find_package_lowercase_package_name)
  set(z_vcpkg_find_package_vcpkg_cmake_wrapper_path
    "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/share/${z_vcpkg_find_package_lowercase_package_name}/vcpkg-cmake-wrapper.cmake")
  if(EXISTS "${z_vcpkg_find_package_vcpkg_cmake_wrapper_path}")
    if(VCPKG_TRACE_FIND_PACKAGE)
      string(REPEAT "  " "${z_vcpkg_find_package_backup_id}" z_vcpkg_find_package_indent)
      message(STATUS "${z_vcpkg_find_package_indent}using share/${z_vcpkg_find_package_lowercase_package_name}/vcpkg-cmake-wrapper.cmake")
      unset(z_vcpkg_find_package_indent)
    endif()
    list(APPEND z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_vars "ARGS")
    if(DEFINED ARGS)
      set(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_ARGS "${ARGS}")
    endif()
    set(ARGS "${z_vcpkg_find_package_package_name};${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_ARGN}")
    set(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_in_wrapper "TRUE")
    include("${z_vcpkg_find_package_vcpkg_cmake_wrapper_path}")
    unset(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_in_wrapper)
  else()
    find_package("${z_vcpkg_find_package_package_name}" ${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_ARGN} BYPASS_PROVIDER)
  endif()
  # Do not use z_vcpkg_find_package_package_name beyond this point since it might have changed!
  # Only variables using z_vcpkg_find_package_backup_id can used correctly below!
  foreach(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_var IN LISTS z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_vars)
    if(DEFINED z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_var})
      set("${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_var}" "${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_var}}")
    else()
      unset("${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_var}")
    endif()
    unset("z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_${z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_backup_var}")
  endforeach()
  unset(z_vcpkg_find_package_${z_vcpkg_find_package_backup_id}_NAME)
  math(EXPR z_vcpkg_find_package_backup_id "${z_vcpkg_find_package_backup_id} - 1")
  if(z_vcpkg_find_package_backup_id LESS "0")
    message(FATAL_ERROR "[vcpkg]: find_package ended with z_vcpkg_find_package_backup_id being less than 0! This is a logical error and should never happen. Please provide a cmake trace log via cmake cmd line option '--trace-expand'!")
  endif()
endmacro()

cmake_language(SET_DEPENDENCY_PROVIDER vcpkg_find_package
         SUPPORTED_METHODS FIND_PACKAGE)
 