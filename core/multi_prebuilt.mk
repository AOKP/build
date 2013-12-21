#
# Copyright (C) 2008 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Save these before they get cleared by CLEAR_VARS.
prebuilt_static_libs := $(filter %.a,$(LOCAL_PREBUILT_LIBS))
prebuilt_shared_libs := $(filter-out %.a,$(LOCAL_PREBUILT_LIBS))
prebuilt_executables := $(LOCAL_PREBUILT_EXECUTABLES)
prebuilt_java_libraries := $(LOCAL_PREBUILT_JAVA_LIBRARIES)
prebuilt_static_java_libraries := $(LOCAL_PREBUILT_STATIC_JAVA_LIBRARIES)
prebuilt_is_host := $(LOCAL_IS_HOST_MODULE)
prebuilt_module_tags := $(LOCAL_MODULE_TAGS)
prebuilt_strip_module := $(LOCAL_STRIP_MODULE)


ifndef multi_prebuilt_once
multi_prebuilt_once := true

# $(1): file list
# $(2): IS_HOST_MODULE
# $(3): MODULE_CLASS
# $(4): MODULE_TAGS
# $(5): OVERRIDE_BUILT_MODULE_PATH
# $(6): UNINSTALLABLE_MODULE
# $(7): BUILT_MODULE_STEM
# $(8): LOCAL_STRIP_MODULE
#
# Elements in the file list may be bare filenames,
# or of the form "<modulename>:<filename>".
# If the module name is not specified, the module
# name will be the filename with the suffix removed.
#
define auto-prebuilt-boilerplate
$(if $(filter %: :%,$(1)), \
  $(error $(LOCAL_PATH): Leading or trailing colons in "$(1)")) \
$(foreach t,$(1), \
  $(eval include $(CLEAR_VARS)) \
  $(eval LOCAL_IS_HOST_MODULE := $(2)) \
  $(eval LOCAL_MODULE_CLASS := $(3)) \
  $(eval LOCAL_MODULE_TAGS := $(4)) \
  $(eval OVERRIDE_BUILT_MODULE_PATH := $(5)) \
  $(eval LOCAL_UNINSTALLABLE_MODULE := $(6)) \
  $(eval tw := $(subst :, ,$(strip $(t)))) \
  $(if $(word 3,$(tw)),$(error $(LOCAL_PATH): Bad prebuilt filename '$(t)')) \
  $(if $(word 2,$(tw)), \
    $(eval LOCAL_MODULE := $(word 1,$(tw))) \
    $(eval LOCAL_SRC_FILES := $(word 2,$(tw))) \
   , \
    $(eval LOCAL_MODULE := $(basename $(notdir $(t)))) \
    $(eval LOCAL_SRC_FILES := $(t)) \
   ) \
  $(if $(7), \
    $(eval LOCAL_BUILT_MODULE_STEM := $(7)) \
   , \
    $(eval LOCAL_BUILT_MODULE_STEM := $(notdir $(LOCAL_SRC_FILES))) \
   ) \
  $(eval LOCAL_MODULE_SUFFIX := $(suffix $(LOCAL_SRC_FILES))) \
  $(if $(filter user,$(TARGET_BUILD_VARIANT)), \
    $(eval LOCAL_STRIP_MODULE := $(8))) \
  $(eval include $(BUILD_PREBUILT)) \
 )
endef

endif # multi_prebuilt_once


$(call auto-prebuilt-boilerplate, \
    $(prebuilt_static_libs), \
    $(prebuilt_is_host), \
    STATIC_LIBRARIES, \
    $(prebuilt_module_tags), \
    , \
    true)

$(call auto-prebuilt-boilerplate, \
    $(prebuilt_shared_libs), \
    $(prebuilt_is_host), \
    SHARED_LIBRARIES, \
    $(prebuilt_module_tags), \
    $($(if $(prebuilt_is_host),HOST,TARGET)_OUT_INTERMEDIATE_LIBRARIES), \
    , \
    , \
    $(prebuilt_strip_module))

$(call auto-prebuilt-boilerplate, \
    $(prebuilt_executables), \
    $(prebuilt_is_host), \
    EXECUTABLES, \
    $(prebuilt_module_tags))

$(call auto-prebuilt-boilerplate, \
    $(prebuilt_java_libraries), \
    $(prebuilt_is_host), \
    JAVA_LIBRARIES, \
    $(prebuilt_module_tags), \
    , \
    , \
    javalib.jar)

$(call auto-prebuilt-boilerplate, \
    $(prebuilt_static_java_libraries), \
    $(prebuilt_is_host), \
    JAVA_LIBRARIES, \
    $(prebuilt_module_tags), \
    , \
    true, \
    javalib.jar)

prebuilt_static_libs :=
prebuilt_shared_libs :=
prebuilt_executables :=
prebuilt_java_libraries :=
prebuilt_static_java_libraries :=
prebuilt_is_host :=
prebuilt_module_tags :=
