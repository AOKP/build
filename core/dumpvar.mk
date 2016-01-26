# ---------------------------------------------------------------
# the setpath shell function in envsetup.sh uses this to figure out
# what to add to the path given the config we have chosen.
ifeq ($(CALLED_FROM_SETUP),true)

ifneq ($(filter /%,$(HOST_OUT_EXECUTABLES)),)
ABP:=$(HOST_OUT_EXECUTABLES)
else
ABP:=$(PWD)/$(HOST_OUT_EXECUTABLES)
endif

ANDROID_BUILD_PATHS := $(ABP)
ANDROID_PREBUILTS := prebuilt/$(HOST_PREBUILT_TAG)
ANDROID_GCC_PREBUILTS := prebuilts/gcc/$(HOST_PREBUILT_TAG)

# The "dumpvar" stuff lets you say something like
#
#     CALLED_FROM_SETUP=true \
#       make -f config/envsetup.make dumpvar-TARGET_OUT
# or
#     CALLED_FROM_SETUP=true \
#       make -f config/envsetup.make dumpvar-abs-HOST_OUT_EXECUTABLES
#
# The plain (non-abs) version just dumps the value of the named variable.
# The "abs" version will treat the variable as a path, and dumps an
# absolute path to it.
#
dumpvar_goals := \
	$(strip $(patsubst dumpvar-%,%,$(filter dumpvar-%,$(MAKECMDGOALS))))
ifdef dumpvar_goals

  ifneq ($(words $(dumpvar_goals)),1)
    $(error Only one "dumpvar-" goal allowed. Saw "$(MAKECMDGOALS)")
  endif

  # If the goal is of the form "dumpvar-abs-VARNAME", then
  # treat VARNAME as a path and return the absolute path to it.
  absolute_dumpvar := $(strip $(filter abs-%,$(dumpvar_goals)))
  ifdef absolute_dumpvar
    dumpvar_goals := $(patsubst abs-%,%,$(dumpvar_goals))
    ifneq ($(filter /%,$($(dumpvar_goals))),)
      DUMPVAR_VALUE := $($(dumpvar_goals))
    else
      DUMPVAR_VALUE := $(PWD)/$($(dumpvar_goals))
    endif
    dumpvar_target := dumpvar-abs-$(dumpvar_goals)
  else
    DUMPVAR_VALUE := $($(dumpvar_goals))
    dumpvar_target := dumpvar-$(dumpvar_goals)
  endif

.PHONY: $(dumpvar_target)
$(dumpvar_target):
	@echo $(DUMPVAR_VALUE)

endif # dumpvar_goals

ifneq ($(dumpvar_goals),report_config)
PRINT_BUILD_CONFIG:=
endif

endif # CALLED_FROM_SETUP


ifneq ($(PRINT_BUILD_CONFIG),)
HOST_OS_EXTRA:=$(shell python -c "import platform; print(platform.platform())")
ifneq ($(BUILD_WITH_COLORS),0)
    include $(TOP_DIR)build/core/colors.mk
endif

$(info  $(CLR_CYN)============================================)
$(info   $(CLR_BLU)PLATFORM_VERSION_CODENAME = $(CLR_CYN)$(PLATFORM_VERSION_CODENAME))
$(info   $(CLR_BLU)PLATFORM_VERSION = $(CLR_CYN)$(PLATFORM_VERSION))
$(info   $(CLR_BOLD)$(CLR_BLU)AOKP_VERSION = $(CLR_CYN)$(AOKP_VERSION)$(CLR_RST))
$(info   $(CLR_BLU)TARGET_PRODUCT = $(CLR_CYN)$(TARGET_PRODUCT))
$(info   $(CLR_BLU)TARGET_BUILD_VARIANT = $(CLR_CYN)$(TARGET_BUILD_VARIANT))
$(info   $(CLR_BLU)TARGET_BUILD_TYPE = $(CLR_CYN)$(TARGET_BUILD_TYPE))
$(info   $(CLR_BLU)TARGET_BUILD_APPS = $(CLR_CYN)$(TARGET_BUILD_APPS))
$(info   $(CLR_BLU)TARGET_ARCH = $(CLR_CYN)$(TARGET_ARCH))
$(info   $(CLR_BLU)TARGET_ARCH_VARIANT = $(CLR_CYN)$(TARGET_ARCH_VARIANT))
$(info   $(CLR_BLU)TARGET_CPU_VARIANT = $(CLR_CYN)$(TARGET_CPU_VARIANT))
$(info   $(CLR_BLU)TARGET_2ND_ARCH = $(CLR_CYN)$(TARGET_2ND_ARCH))
$(info   $(CLR_BLU)TARGET_2ND_ARCH_VARIANT = $(CLR_CYN)$(TARGET_2ND_ARCH_VARIANT))
$(info   $(CLR_BLU)TARGET_2ND_CPU_VARIANT = $(CLR_CYN)$(TARGET_2ND_CPU_VARIANT))
$(info   $(CLR_BLU)HOST_ARCH = $(CLR_CYN)$(HOST_ARCH))
$(info   $(CLR_BLU)HOST_OS = $(CLR_CYN)$(HOST_OS))
$(info   $(CLR_BLU)HOST_OS_EXTRA = $(CLR_CYN)$(HOST_OS_EXTRA))
$(info   $(CLR_BLU)HOST_BUILD_TYPE = $(CLR_CYN)$(HOST_BUILD_TYPE))
$(info   $(CLR_BLU)BUILD_ID = $(CLR_CYN)$(BUILD_ID))
$(info   $(CLR_BLU)OUT_DIR = $(CLR_CYN)$(OUT_DIR))
ifeq ($(CYNGN_TARGET),true)
$(info   $(CLR_BLU)CYNGN_TARGET = $(CLR_CYN)$(CYNGN_TARGET))
$(info   $(CLR_BLU)CYNGN_FEATURES = $(CLR_CYN)$(CYNGN_FEATURES))
endif
ifneq ($(USE_CCACHE),)
$(info   $(CLR_BLU)CCACHE_DIR = $(CLR_CYN)$(CCACHE_DIR))
$(info   $(CLR_BLU)CCACHE_BASEDIR = $(CLR_CYN)$(CCACHE_BASEDIR))
endif
$(info   $(CLR_CYN)============================================$(CLR_RST))
endif
