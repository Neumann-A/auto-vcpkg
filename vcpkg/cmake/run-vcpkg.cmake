### Bootstrap

if(NOT EXISTS "${Z_VCPKG_EXECUTABLE}" AND NOT Z_VCPKG_HAS_FATAL_ERROR)
  message(STATUS "Bootstrapping vcpkg before install")

  set(Z_VCPKG_BOOTSTRAP_LOG "${CMAKE_BINARY_DIR}/vcpkg-bootstrap.log")
  file(TO_NATIVE_PATH "${Z_VCPKG_BOOTSTRAP_LOG}" Z_NATIVE_VCPKG_BOOTSTRAP_LOG)
  execute_process(
    COMMAND "${Z_VCPKG_BOOTSTRAP_SCRIPT}" ${VCPKG_BOOTSTRAP_OPTIONS}
    OUTPUT_FILE "${Z_VCPKG_BOOTSTRAP_LOG}"
    ERROR_FILE "${Z_VCPKG_BOOTSTRAP_LOG}"
    RESULT_VARIABLE Z_VCPKG_BOOTSTRAP_RESULT)

  if(Z_VCPKG_BOOTSTRAP_RESULT EQUAL "0")
    message(STATUS "Bootstrapping vcpkg before install - done")
  else()
    message(STATUS "Bootstrapping vcpkg before install - failed")
    z_vcpkg_add_fatal_error("vcpkg install failed. See logs for more information: ${Z_NATIVE_VCPKG_BOOTSTRAP_LOG}")
  endif()
endif()

## Run vcpkg
if(NOT Z_VCPKG_HAS_FATAL_ERROR)
  message(STATUS "Running vcpkg install")

  set(Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS)

  if(DEFINED VCPKG_HOST_TRIPLET AND NOT VCPKG_HOST_TRIPLET STREQUAL "")
    list(APPEND Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS "--host-triplet=${VCPKG_HOST_TRIPLET}")
  endif()

  if(VCPKG_OVERLAY_PORTS)
    foreach(Z_VCPKG_OVERLAY_PORT IN LISTS VCPKG_OVERLAY_PORTS)
      list(APPEND Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS "--overlay-ports=${Z_VCPKG_OVERLAY_PORT}")
    endforeach()
  endif()
  if(VCPKG_OVERLAY_TRIPLETS)
    foreach(Z_VCPKG_OVERLAY_TRIPLET IN LISTS VCPKG_OVERLAY_TRIPLETS)
      list(APPEND Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS "--overlay-triplets=${Z_VCPKG_OVERLAY_TRIPLET}")
    endforeach()
  endif()

  if(DEFINED VCPKG_FEATURE_FLAGS OR DEFINED CACHE{VCPKG_FEATURE_FLAGS})
    list(JOIN VCPKG_FEATURE_FLAGS "," Z_VCPKG_FEATURE_FLAGS)
    set(Z_VCPKG_FEATURE_FLAGS "--feature-flags=${Z_VCPKG_FEATURE_FLAGS}")
  endif()

  foreach(Z_VCPKG_FEATURE IN LISTS VCPKG_MANIFEST_FEATURES)
    list(APPEND Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS "--x-feature=${Z_VCPKG_FEATURE}")
  endforeach()

  if(VCPKG_MANIFEST_NO_DEFAULT_FEATURES)
    list(APPEND Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS "--x-no-default-features")
  endif()

  set(Z_VCPKG_MANIFEST_INSTALL_ECHO_PARAMS ECHO_OUTPUT_VARIABLE ECHO_ERROR_VARIABLE)

  execute_process(
    COMMAND "${Z_VCPKG_EXECUTABLE}" install
      --triplet "${VCPKG_TARGET_TRIPLET}"
      --vcpkg-root "${VCPKG_ROOT_DIR}"
      "--x-wait-for-lock"
      "--x-manifest-root=${VCPKG_MANIFEST_DIR}"
      "--x-install-root=${VCPKG_INSTALLED_DIR}"
      ${Z_VCPKG_FEATURE_FLAGS}
      ${Z_VCPKG_ADDITIONAL_MANIFEST_PARAMS}
      ${VCPKG_INSTALL_OPTIONS}
    OUTPUT_VARIABLE Z_VCPKG_MANIFEST_INSTALL_LOGTEXT
    ERROR_VARIABLE Z_VCPKG_MANIFEST_INSTALL_LOGTEXT
    RESULT_VARIABLE Z_VCPKG_MANIFEST_INSTALL_RESULT
    ${Z_VCPKG_MANIFEST_INSTALL_ECHO_PARAMS}
  )

  set(Z_VCPKG_MANIFEST_INSTALL_LOGFILE "${CMAKE_BINARY_DIR}/vcpkg-manifest-install.log")
  file(TO_NATIVE_PATH "${Z_VCPKG_MANIFEST_INSTALL_LOGFILE}" Z_NATIVE_VCPKG_MANIFEST_INSTALL_LOGFILE)
  file(WRITE "${Z_VCPKG_MANIFEST_INSTALL_LOGFILE}" "${Z_VCPKG_MANIFEST_INSTALL_LOGTEXT}")

  if(Z_VCPKG_MANIFEST_INSTALL_RESULT EQUAL "0")
    message(STATUS "Running vcpkg install - done")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
      "${VCPKG_MANIFEST_DIR}/vcpkg.json")
    if(EXISTS "${VCPKG_MANIFEST_DIR}/vcpkg-configuration.json")
      set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS
        "${VCPKG_MANIFEST_DIR}/vcpkg-configuration.json")
    endif()
  else()
    message(STATUS "Running vcpkg install - failed")
    z_vcpkg_add_fatal_error("vcpkg install failed. See logs for more information: ${Z_NATIVE_VCPKG_MANIFEST_INSTALL_LOGFILE}")
  endif()
endif()