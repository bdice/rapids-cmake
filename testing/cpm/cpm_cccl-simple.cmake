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
include(${rapids-cmake-dir}/cpm/init.cmake)
include(${rapids-cmake-dir}/cpm/cccl.cmake)

rapids_cpm_init()

if(TARGET test::Thrust)
  message(FATAL_ERROR "Expected test::Thrust not to exist")
endif()
if(TARGET libcudacxx::libcudacxx)
  message(FATAL_ERROR "Expected libcudacxx::libcudacxx not to exist")
endif()

rapids_cpm_cccl(NAMESPACE test)
if(NOT TARGET test::Thrust)
  message(FATAL_ERROR "Expected test::Thrust target to exist")
endif()
if(NOT TARGET libcudacxx::libcudacxx)
  message(FATAL_ERROR "Expected libcudacxx::libcudacxx target to exist")
endif()

rapids_cpm_cccl(NAMESPACE test)

rapids_cpm_cccl(NAMESPACE test2)
if(NOT TARGET test2::Thrust)
  message(FATAL_ERROR "Expected test2::Thrust target to exist")
endif()
