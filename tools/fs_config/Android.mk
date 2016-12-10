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

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := fs_config.c
LOCAL_MODULE := fs_config
LOCAL_SHARED_LIBRARIES := libcutils libselinux
LOCAL_CFLAGS := -Werror

include $(BUILD_HOST_EXECUTABLE)

# One can override the default android_filesystem_config.h file in one of two ways:
#
# 1. The old way:
#   To Build the custom target binary for the host to generate the fs_config
#   override files. The executable is hard coded to include the
#   $(TARGET_ANDROID_FILESYSTEM_CONFIG_H) file if it exists.
#   Expectations:
#      device/<vendor>/<device>/android_filesystem_config.h
#          fills in struct fs_path_config android_device_dirs[] and
#                   struct fs_path_config android_device_files[]
#      device/<vendor>/<device>/device.mk
#          PRODUCT_PACKAGES += fs_config_dirs fs_config_files
#   If not specified, check if default one to be found
#
# 2. The new way:
#   set TARGET_FS_CONFIG_GEN to contain a list of intermediate format files
#   for generating the android_filesystem_config.h file.
#
# More information can be found in the README
ANDROID_FS_CONFIG_H := android_filesystem_config.h

ifneq ($(TARGET_ANDROID_FILESYSTEM_CONFIG_H),)
ifneq ($(TARGET_FS_CONFIG_GEN),)
$(error Cannot set TARGET_ANDROID_FILESYSTEM_CONFIG_H and TARGET_FS_CONFIG_GEN simultaneously)
endif

# One and only one file can be specified.
ifneq ($(words $(TARGET_ANDROID_FILESYSTEM_CONFIG_H)),1)
$(error Multiple fs_config files specified, \
 see "$(TARGET_ANDROID_FILESYSTEM_CONFIG_H)".)
endif

ifeq ($(filter %/$(ANDROID_FS_CONFIG_H),$(TARGET_ANDROID_FILESYSTEM_CONFIG_H)),)
$(error TARGET_ANDROID_FILESYSTEM_CONFIG_H file name must be $(ANDROID_FS_CONFIG_H), \
 see "$(notdir $(TARGET_ANDROID_FILESYSTEM_CONFIG_H))".)
endif

my_fs_config_h := $(TARGET_ANDROID_FILESYSTEM_CONFIG_H)
else ifneq ($(wildcard $(TARGET_DEVICE_DIR)/$(ANDROID_FS_CONFIG_H)),)

ifneq ($(TARGET_FS_CONFIG_GEN),)
$(error Cannot provide $(TARGET_DEVICE_DIR)/$(ANDROID_FS_CONFIG_H) and set TARGET_FS_CONFIG_GEN simultaneously)
endif
my_fs_config_h := $(TARGET_DEVICE_DIR)/$(ANDROID_FS_CONFIG_H)

else
my_fs_config_h := $(LOCAL_PATH)/default/$(ANDROID_FS_CONFIG_H)
endif

##################################
include $(CLEAR_VARS)
LOCAL_SRC_FILES := fs_config_generate.c
LOCAL_MODULE := fs_config_generate_$(TARGET_DEVICE)
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SHARED_LIBRARIES := libcutils
LOCAL_CFLAGS := -Werror -Wno-error=\#warnings

ifneq ($(TARGET_FS_CONFIG_GEN),)
system_android_filesystem_config := system/core/include/private/android_filesystem_config.h

# Generate the "generated_oem_aid.h" file
oem := $(local-generated-sources-dir)/generated_oem_aid.h
$(oem): PRIVATE_LOCAL_PATH := $(LOCAL_PATH)
$(oem): PRIVATE_TARGET_FS_CONFIG_GEN := $(TARGET_FS_CONFIG_GEN)
$(oem): PRIVATE_ANDROID_FS_HDR := $(system_android_filesystem_config)
$(oem): PRIVATE_CUSTOM_TOOL = $(PRIVATE_LOCAL_PATH)/fs_config_generator.py oemaid --aid-header=$(PRIVATE_ANDROID_FS_HDR) $(PRIVATE_TARGET_FS_CONFIG_GEN) > $@
$(oem): $(TARGET_FS_CONFIG_GEN) $(LOCAL_PATH)/fs_config_generator.py
	$(transform-generated-source)

# Generate the fs_config header
gen := $(local-generated-sources-dir)/$(ANDROID_FS_CONFIG_H)
$(gen): PRIVATE_LOCAL_PATH := $(LOCAL_PATH)
$(gen): PRIVATE_TARGET_FS_CONFIG_GEN := $(TARGET_FS_CONFIG_GEN)
$(gen): PRIVATE_ANDROID_FS_HDR := $(system_android_filesystem_config)
$(gen): PRIVATE_CUSTOM_TOOL = $(PRIVATE_LOCAL_PATH)/fs_config_generator.py fsconfig --aid-header=$(PRIVATE_ANDROID_FS_HDR) $(PRIVATE_TARGET_FS_CONFIG_GEN) > $@
$(gen): $(TARGET_FS_CONFIG_GEN) $(system_android_filesystem_config) $(LOCAL_PATH)/fs_config_generator.py
	$(transform-generated-source)

LOCAL_GENERATED_SOURCES := $(oem) $(gen)

my_fs_config_h := $(gen)
my_gen_oem_aid := $(oem)
gen :=
oem :=
endif

LOCAL_C_INCLUDES := $(dir $(my_fs_config_h)) $(dir $(my_gen_oem_aid))

include $(BUILD_HOST_EXECUTABLE)
fs_config_generate_bin := $(LOCAL_INSTALLED_MODULE)

##################################
# Generate the system/etc/fs_config_dirs binary file for the target
# Add fs_config_dirs to PRODUCT_PACKAGES in the device make file to enable
include $(CLEAR_VARS)

LOCAL_MODULE := fs_config_dirs
LOCAL_MODULE_CLASS := ETC
include $(BUILD_SYSTEM)/base_rules.mk
$(LOCAL_BUILT_MODULE): $(fs_config_generate_bin)
	@mkdir -p $(dir $@)
	$< -D -o $@

##################################
# Generate the system/etc/fs_config_files binary file for the target
# Add fs_config_files to PRODUCT_PACKAGES in the device make file to enable
include $(CLEAR_VARS)

LOCAL_MODULE := fs_config_files
LOCAL_MODULE_CLASS := ETC
include $(BUILD_SYSTEM)/base_rules.mk
$(LOCAL_BUILT_MODULE): $(fs_config_generate_bin)
	@mkdir -p $(dir $@)
	$< -F -o $@

ifneq ($(TARGET_FS_CONFIG_GEN),)

##################################
# Build the oemaid library when fs config files are present.
# Intentionally break build if you require generated AIDS
# header file, but are not using any fs config files.
include $(CLEAR_VARS)
LOCAL_MODULE := liboemaids
LOCAL_EXPORT_C_INCLUDE_DIRS := $(dir $(my_gen_oem_aid))
LOCAL_EXPORT_C_INCLUDE_DEPS := $(my_gen_oem_aid)
include $(BUILD_STATIC_LIBRARY)

##################################
# Generate the system/etc/passwd text file for the target
# This file may be empty if no AIDs are defined in
# TARGET_FS_CONFIG_GEN files.
include $(CLEAR_VARS)

LOCAL_MODULE := passwd
LOCAL_MODULE_CLASS := ETC

include $(BUILD_SYSTEM)/base_rules.mk

$(LOCAL_BUILT_MODULE): PRIVATE_LOCAL_PATH := $(LOCAL_PATH)
$(LOCAL_BUILT_MODULE): PRIVATE_TARGET_FS_CONFIG_GEN := $(TARGET_FS_CONFIG_GEN)
$(LOCAL_BUILT_MODULE): PRIVATE_ANDROID_FS_HDR := $(system_android_filesystem_config)
$(LOCAL_BUILT_MODULE): $(LOCAL_PATH)/fs_config_generator.py $(TARGET_FS_CONFIG_GEN) $(system_android_filesystem_config)
	@mkdir -p $(dir $@)
	$(hide) $< passwd --aid-header=$(PRIVATE_ANDROID_FS_HDR) $(PRIVATE_TARGET_FS_CONFIG_GEN) > $@

##################################
# Generate the system/etc/group text file for the target
# This file may be empty if no AIDs are defined in
# TARGET_FS_CONFIG_GEN files.
include $(CLEAR_VARS)

LOCAL_MODULE := group
LOCAL_MODULE_CLASS := ETC

include $(BUILD_SYSTEM)/base_rules.mk

$(LOCAL_BUILT_MODULE): PRIVATE_LOCAL_PATH := $(LOCAL_PATH)
$(LOCAL_BUILT_MODULE): PRIVATE_TARGET_FS_CONFIG_GEN := $(TARGET_FS_CONFIG_GEN)
$(LOCAL_BUILT_MODULE): PRIVATE_ANDROID_FS_HDR := $(system_android_filesystem_config)
$(LOCAL_BUILT_MODULE): $(LOCAL_PATH)/fs_config_generator.py $(TARGET_FS_CONFIG_GEN) $(system_android_filesystem_config)
	@mkdir -p $(dir $@)
	$(hide) $< group --aid-header=$(PRIVATE_ANDROID_FS_HDR) $(PRIVATE_TARGET_FS_CONFIG_GEN) > $@

system_android_filesystem_config :=
endif

ANDROID_FS_CONFIG_H :=
my_fs_config_h :=
fs_config_generate_bin :=
my_gen_oem_aid :=
