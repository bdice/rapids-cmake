#=============================================================================
# Copyright (c) 2023, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#=============================================================================
include_guard(GLOBAL)

#[=======================================================================[.rst:
rapids_cpm_cccl
---------------

.. versionadded:: v24.02.00

Allow projects to find or build `CCCL` via `CPM` with built-in
tracking of these dependencies for correct export support.

Uses the version of CCCL :ref:`specified in the version file <cpm_versions>` for consistency
across all RAPIDS projects.

.. code-block:: cmake

  rapids_cpm_cccl( NAMESPACE <namespace>
                   [BUILD_EXPORT_SET <export-name>]
                   [INSTALL_EXPORT_SET <export-name>]
                   [<CPM_ARGS> ...])

``NAMESPACE``
  The namespace that the CCCL target will be constructed into.

.. |PKG_NAME| replace:: CCCL
.. include:: common_package_args.txt

.. versionadded:: v23.12.00
  When `BUILD_EXPORT_SET` is specified the generated build export set dependency
  file will automatically call `cccl_create_target(<namespace>::CCCL FROM_OPTIONS)`.

  When `INSTALL_EXPORT_SET` is specified the generated install export set dependency
  file will automatically call `cccl_create_target(<namespace>::CCCL FROM_OPTIONS)`.

Result Targets
^^^^^^^^^^^^^^
  <namespace>::CCCL target will be created

Result Variables
^^^^^^^^^^^^^^^^
  :cmake:variable:`CCCL_SOURCE_DIR` is set to the path to the source directory of CCCL.
  :cmake:variable:`CCCL_BINARY_DIR` is set to the path to the build directory of  CCCL.
  :cmake:variable:`CCCL_ADDED`      is set to a true value if CCCL has not been added before.
  :cmake:variable:`CCCL_VERSION`    is set to the version of CCCL specified by the versions.json.

#]=======================================================================]
# cmake-lint: disable=R0915
function(rapids_cpm_cccl NAMESPACE namespaces_name)
  list(APPEND CMAKE_MESSAGE_CONTEXT "rapids.cpm.cccl")

  include("${rapids-cmake-dir}/cpm/detail/package_details.cmake")
  rapids_cpm_package_details(CCCL version repository tag shallow exclude)

  set(to_install OFF)
  if(INSTALL_EXPORT_SET IN_LIST ARGN AND NOT exclude)
    set(to_install ON)
    # Make sure we install cccl into the `include/rapids` subdirectory instead of the default
    include(GNUInstallDirs)
    set(CMAKE_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}/rapids")
    set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/rapids")
  endif()

  include("${rapids-cmake-dir}/cpm/detail/generate_patch_command.cmake")
  rapids_cpm_generate_patch_command(CCCL ${version} patch_command)

  include("${rapids-cmake-dir}/cpm/find.cmake")
  rapids_cpm_find(CCCL ${version} ${ARGN}
                  GLOBAL_TARGETS ${namespaces_name}::CCCL
                  CPM_ARGS FIND_PACKAGE_ARGUMENTS EXACT
                  GIT_REPOSITORY ${repository}
                  GIT_TAG ${tag}
                  GIT_SHALLOW ${shallow}
                  PATCH_COMMAND ${patch_command}
                  EXCLUDE_FROM_ALL ${exclude}
                  OPTIONS "CCCL_ENABLE_INSTALL_RULES ${to_install}")

  include("${rapids-cmake-dir}/cpm/detail/display_patch_status.cmake")
  rapids_cpm_display_patch_status(CCCL)

  set(options)
  set(one_value BUILD_EXPORT_SET INSTALL_EXPORT_SET)
  set(multi_value)
  cmake_parse_arguments(_RAPIDS "${options}" "${one_value}" "${multi_value}" ${ARGN})

  set(post_find_code "if(NOT TARGET ${namespaces_name}::CCCL)"
                     "  cccl_create_target(${namespaces_name}::CCCL FROM_OPTIONS)" "endif()")

  if(CCCL_SOURCE_DIR)
    # Store where CMake can find the CCCL-config.cmake that comes part of CCCL source code
    include("${rapids-cmake-dir}/export/find_package_root.cmake")
    include("${rapids-cmake-dir}/export/detail/post_find_package_code.cmake")
    rapids_export_find_package_root(BUILD CCCL "${CCCL_SOURCE_DIR}/cmake"
                                    EXPORT_SET ${_RAPIDS_BUILD_EXPORT_SET})
    rapids_export_post_find_package_code(BUILD CCCL "${post_find_code}" EXPORT_SET
                                         ${_RAPIDS_BUILD_EXPORT_SET})

    rapids_export_find_package_root(INSTALL CCCL
                                    [=[${CMAKE_CURRENT_LIST_DIR}/../../rapids/cmake/cccl]=]
                                    EXPORT_SET ${_RAPIDS_INSTALL_EXPORT_SET} CONDITION to_install)
    rapids_export_post_find_package_code(INSTALL CCCL "${post_find_code}" EXPORT_SET
                                         ${_RAPIDS_INSTALL_EXPORT_SET} CONDITION to_install)
  endif()

  # Check for the existence of cccl_create_target so we support fetching CCCL with DOWNLOAD_ONLY
  if(NOT TARGET ${namespaces_name}::CCCL AND COMMAND cccl_create_target)
    cccl_create_target(${namespaces_name}::CCCL FROM_OPTIONS)
    set_target_properties(${namespaces_name}::CCCL PROPERTIES IMPORTED_NO_SYSTEM ON)
    if(TARGET _CCCL_CCCL)
      set_target_properties(_CCCL_CCCL PROPERTIES IMPORTED_NO_SYSTEM ON)
    endif()
  endif()

  # Propagate up variables that CPMFindPackage provide
  set(CCCL_SOURCE_DIR "${CCCL_SOURCE_DIR}" PARENT_SCOPE)
  set(CCCL_BINARY_DIR "${CCCL_BINARY_DIR}" PARENT_SCOPE)
  set(CCCL_ADDED "${CCCL_ADDED}" PARENT_SCOPE)
  set(CCCL_VERSION ${version} PARENT_SCOPE)

endfunction()
