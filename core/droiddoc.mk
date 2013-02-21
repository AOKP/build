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

##
##
## Common to both droiddoc and javadoc
##
##

LOCAL_IS_HOST_MODULE := $(call true-or-empty,$(LOCAL_IS_HOST_MODULE))
ifeq ($(LOCAL_IS_HOST_MODULE),true)
my_prefix:=HOST_
else
my_prefix:=TARGET_
endif

LOCAL_MODULE_CLASS := $(strip $(LOCAL_MODULE_CLASS))
ifndef LOCAL_MODULE_CLASS
$(error $(LOCAL_PATH): LOCAL_MODULE_CLASS not defined)
endif

full_src_files := $(patsubst %,$(LOCAL_PATH)/%,$(LOCAL_SRC_FILES))
out_dir := $(OUT_DOCS)/$(LOCAL_MODULE)
full_target := $(call doc-timestamp-for,$(LOCAL_MODULE))

ifeq ($(LOCAL_DROIDDOC_SOURCE_PATH),)
LOCAL_DROIDDOC_SOURCE_PATH := $(LOCAL_PATH)
endif

ifeq ($(LOCAL_DROIDDOC_CUSTOM_TEMPLATE_DIR),)
LOCAL_DROIDDOC_CUSTOM_TEMPLATE_DIR := $(SRC_DROIDDOC_DIR)/$(LOCAL_DROIDDOC_CUSTOM_TEMPLATE_DIR)
endif

ifeq ($(LOCAL_DROIDDOC_ASSET_DIR),)
LOCAL_DROIDDOC_ASSET_DIR := assets
endif
ifeq ($(LOCAL_DROIDDOC_CUSTOM_ASSET_DIR),)
LOCAL_DROIDDOC_CUSTOM_ASSET_DIR := assets
endif

$(full_target): PRIVATE_CLASSPATH:=$(LOCAL_CLASSPATH)
full_java_lib_deps :=

$(full_target): PRIVATE_BOOTCLASSPATH :=
ifeq ($(BUILD_OS),linux)
# You have to set bootclasspath for javadoc manually on linux since Java 6.
host_jdk_rt_jar := $(dir $(HOST_JDK_TOOLS_JAR))../jre/lib/rt.jar
$(full_target): PRIVATE_BOOTCLASSPATH := $(host_jdk_rt_jar)
endif

ifneq ($(LOCAL_IS_HOST_MODULE),true)

ifneq ($(LOCAL_SDK_VERSION),)
  ifeq ($(LOCAL_SDK_VERSION)$(TARGET_BUILD_APPS),current)
    # Use android_stubs_current if LOCAL_SDK_VERSION is current and no TARGET_BUILD_APPS.
    LOCAL_JAVA_LIBRARIES := android_stubs_current $(LOCAL_JAVA_LIBRARIES)
  else
    LOCAL_JAVA_LIBRARIES := sdk_v$(LOCAL_SDK_VERSION) $(LOCAL_JAVA_LIBRARIES)
  endif
else
  LOCAL_JAVA_LIBRARIES := core ext framework $(LOCAL_JAVA_LIBRARIES)
endif  # LOCAL_SDK_VERSION
LOCAL_JAVA_LIBRARIES := $(sort $(LOCAL_JAVA_LIBRARIES))

full_java_libs := $(call java-lib-files,$(LOCAL_JAVA_LIBRARIES),$(LOCAL_IS_HOST_MODULE))
full_java_lib_deps := $(call java-lib-deps,$(LOCAL_JAVA_LIBRARIES),$(LOCAL_IS_HOST_MODULE))

# we're not going to generate docs from any of these classes, but we need them
# to build properly.
ifneq ($(strip $(LOCAL_STATIC_JAVA_LIBRARIES)),)
full_java_libs += $(addprefix $(LOCAL_PATH)/,$(LOCAL_STATIC_JAVA_LIBRARIES)) $(LOCAL_CLASSPATH)
full_java_lib_deps += $(addprefix $(LOCAL_PATH)/,$(LOCAL_STATIC_JAVA_LIBRARIES)) $(LOCAL_CLASSPATH)
endif

$(full_target): PRIVATE_CLASSPATH := $(subst $(space),:,$(full_java_libs))

endif # !LOCAL_IS_HOST_MODULE

intermediates.COMMON := $(call local-intermediates-dir,COMMON)

$(full_target): PRIVATE_SOURCE_PATH := $(call normalize-path-list,$(LOCAL_DROIDDOC_SOURCE_PATH))
$(full_target): PRIVATE_JAVA_FILES := $(filter %.java,$(full_src_files))
$(full_target): PRIVATE_JAVA_FILES += $(addprefix $($(my_prefix)OUT_COMMON_INTERMEDIATES)/, $(filter %.java,$(LOCAL_INTERMEDIATE_SOURCES)))
$(full_target): PRIVATE_SOURCE_INTERMEDIATES_DIR := $(intermediates.COMMON)/src
$(full_target): PRIVATE_SRC_LIST_FILE := $(intermediates.COMMON)/droiddoc-src-list

ifneq ($(strip $(LOCAL_ADDITIONAL_JAVA_DIR)),)
$(full_target): PRIVATE_ADDITIONAL_JAVA_DIR := $(LOCAL_ADDITIONAL_JAVA_DIR)
endif

$(full_target): PRIVATE_OUT_DIR := $(out_dir)
$(full_target): PRIVATE_DROIDDOC_OPTIONS := $(LOCAL_DROIDDOC_OPTIONS)

# Lists the input files for the doc build into a text file
# suitable for the @ syntax of javadoc.
# $(1): the file to create
# $(2): files to include
# $(3): list of directories to search for java files in
define prepare-doc-source-list
$(hide) mkdir -p $(dir $(1))
$(call dump-words-to-file, $(2), $(1))
$(hide) for d in $(3) ; do find $$d -name '*.java' >> $(1) 2> /dev/null ; done ; true
endef

ifeq (a,b)
$(full_target): PRIVATE_PROFILING_OPTIONS := \
    -J-agentlib:jprofilerti=port=8849 -J-Xbootclasspath/a:/Applications/jprofiler5/bin/agent.jar
endif


ifneq ($(strip $(LOCAL_DROIDDOC_USE_STANDARD_DOCLET)),true)
##
##
## droiddoc only
##
##

droiddoc_templates := \
    $(shell find $(LOCAL_DROIDDOC_CUSTOM_TEMPLATE_DIR) -type f)

droiddoc := \
	$(HOST_JDK_TOOLS_JAR) \
	$(HOST_OUT_JAVA_LIBRARIES)/doclava$(COMMON_JAVA_PACKAGE_SUFFIX)

$(full_target): PRIVATE_DOCLETPATH := $(HOST_OUT_JAVA_LIBRARIES)/jsilver$(COMMON_JAVA_PACKAGE_SUFFIX):$(HOST_OUT_JAVA_LIBRARIES)/doclava$(COMMON_JAVA_PACKAGE_SUFFIX)
$(full_target): PRIVATE_CURRENT_BUILD := -hdf page.build $(BUILD_ID)-$(BUILD_NUMBER)
$(full_target): PRIVATE_CURRENT_TIME :=  -hdf page.now "$(shell date "+%d %b %Y %k:%M")"
$(full_target): PRIVATE_CUSTOM_TEMPLATE_DIR := $(LOCAL_DROIDDOC_CUSTOM_TEMPLATE_DIR)
$(full_target): PRIVATE_IN_CUSTOM_ASSET_DIR := $(LOCAL_DROIDDOC_CUSTOM_TEMPLATE_DIR)/$(LOCAL_DROIDDOC_CUSTOM_ASSET_DIR)
$(full_target): PRIVATE_OUT_ASSET_DIR := $(out_dir)/$(LOCAL_DROIDDOC_ASSET_DIR)
$(full_target): PRIVATE_OUT_CUSTOM_ASSET_DIR := $(out_dir)/$(LOCAL_DROIDDOC_CUSTOM_ASSET_DIR)
ifneq ($(strip $(LOCAL_DROIDDOC_HTML_DIR)),)
$(full_target): PRIVATE_DROIDDOC_HTML_DIR := -htmldir $(LOCAL_PATH)/$(LOCAL_DROIDDOC_HTML_DIR)
else
$(full_target): PRIVATE_DROIDDOC_HTML_DIR := 
endif
ifneq ($(strip $(LOCAL_ADDITIONAL_HTML_DIR)),)
$(full_target): PRIVATE_ADDITIONAL_HTML_DIR := -htmldir2 $(LOCAL_PATH)/$(LOCAL_ADDITIONAL_HTML_DIR)
else
$(full_target): PRIVATE_ADDITIONAL_HTML_DIR :=
endif

# TODO: not clear if this is used any more
$(full_target): PRIVATE_LOCAL_PATH := $(LOCAL_PATH)

html_dir_files := $(shell find $(LOCAL_PATH)/$(LOCAL_DROIDDOC_HTML_DIR) -type f)

$(full_target): $(full_src_files) $(droiddoc_templates) $(droiddoc) $(html_dir_files) $(full_java_lib_deps) $(LOCAL_ADDITIONAL_DEPENDENCIES)
	@echo Docs droiddoc: $(PRIVATE_OUT_DIR)
	$(hide) mkdir -p $(dir $(full_target))
	$(call prepare-doc-source-list,$(PRIVATE_SRC_LIST_FILE),$(PRIVATE_JAVA_FILES), \
			$(PRIVATE_SOURCE_INTERMEDIATES_DIR) $(PRIVATE_ADDITIONAL_JAVA_DIR))
	$(hide) ( \
		javadoc \
                \@$(PRIVATE_SRC_LIST_FILE) \
                -J-Xmx1280m \
                $(PRIVATE_PROFILING_OPTIONS) \
                -quiet \
                -doclet com.google.doclava.Doclava \
                -docletpath $(PRIVATE_DOCLETPATH) \
                -templatedir $(PRIVATE_CUSTOM_TEMPLATE_DIR) \
                $(PRIVATE_DROIDDOC_HTML_DIR) \
                $(PRIVATE_ADDITIONAL_HTML_DIR) \
                $(addprefix -bootclasspath ,$(PRIVATE_BOOTCLASSPATH)) \
                $(addprefix -classpath ,$(PRIVATE_CLASSPATH)) \
                -sourcepath $(PRIVATE_SOURCE_PATH)$(addprefix :,$(PRIVATE_CLASSPATH)) \
                -d $(PRIVATE_OUT_DIR) \
                $(PRIVATE_CURRENT_BUILD) $(PRIVATE_CURRENT_TIME) \
                $(PRIVATE_DROIDDOC_OPTIONS) \
        && touch -f $@ \
    ) || (rm -rf $(PRIVATE_OUT_DIR) $(PRIVATE_SRC_LIST_FILE); exit 45)



else
##
##
## standard doclet only
##
##
$(full_target): $(full_src_files) $(full_java_lib_deps)
	@echo Docs javadoc: $(PRIVATE_OUT_DIR)
	@mkdir -p $(dir $(full_target))
	$(call prepare-doc-source-list,$(PRIVATE_SRC_LIST_FILE),$(PRIVATE_JAVA_FILES), \
			$(PRIVATE_SOURCE_INTERMEDIATES_DIR) $(PRIVATE_ADDITIONAL_JAVA_DIR))
	$(hide) ( \
		javadoc \
                $(PRIVATE_DROIDDOC_OPTIONS) \
                \@$(PRIVATE_SRC_LIST_FILE) \
                -J-Xmx1024m \
                $(PRIVATE_PROFILING_OPTIONS) \
                $(addprefix -classpath ,$(PRIVATE_CLASSPATH)) \
                -sourcepath $(PRIVATE_SOURCE_PATH)$(addprefix :,$(PRIVATE_CLASSPATH)) \
                -d $(PRIVATE_OUT_DIR) \
                -quiet \
        && touch -f $@ \
    ) || (rm -rf $(PRIVATE_OUT_DIR) $(PRIVATE_SRC_LIST_FILE); exit 45)


endif
##
##
## Common to both droiddoc and javadoc
##
##


ALL_DOCS += $(full_target)

.PHONY: $(LOCAL_MODULE)-docs
$(LOCAL_MODULE)-docs : $(full_target)

ifeq ($(strip $(LOCAL_UNINSTALLABLE_MODULE)),)

# Define a rule to create a zip of these docs.
out_zip := $(OUT_DOCS)/$(LOCAL_MODULE)-docs.zip
$(out_zip): PRIVATE_DOCS_DIR := $(out_dir)
$(out_zip): $(full_target)
	@echo Package docs: $@
	@rm -f $@
	@mkdir -p $(dir $@)
	$(hide) ( F=$$(pwd)/$@ ; cd $(PRIVATE_DOCS_DIR) && zip -rq $$F * )

$(call dist-for-goals,docs,$(out_zip))

endif
