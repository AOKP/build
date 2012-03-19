#
# Set up product-global definitions and include product-specific rules.
#

ifneq ($(strip $(TARGET_NO_BOOTLOADER)),true)
  INSTALLED_BOOTLOADER_MODULE := $(PRODUCT_OUT)/bootloader
  ifeq ($(strip $(TARGET_BOOTLOADER_IS_2ND)),true)
    INSTALLED_2NDBOOTLOADER_TARGET := $(PRODUCT_OUT)/2ndbootloader
  else
    INSTALLED_2NDBOOTLOADER_TARGET :=
  endif
else
  ifneq ($(strip $(BOARD_HAS_LOCKED_BOOTLOADER)), true)
    INSTALLED_BOOTLOADER_MODULE :=
    INSTALLED_2NDBOOTLOADER_TARGET :=
  endif
endif	# TARGET_NO_BOOTLOADER

ifneq ($(strip $(TARGET_NO_KERNEL)),true)
  INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
else
  INSTALLED_KERNEL_TARGET :=
endif

-include $(TARGET_DEVICE_DIR)/AndroidBoard.mk

# Generate a file that contains various information about the
# device we're building for.  This file is typically packaged up
# with everything else.
#
# If the file "board-info.txt" appears in $(TARGET_DEVICE_DIR),
# it will be used; otherwise TARGET_BOARD_INFO_FILE is used, which
# can be set in BoardConfig.mk.
#
INSTALLED_ANDROID_INFO_TXT_TARGET := $(PRODUCT_OUT)/android-info.txt
board_info_txt := $(wildcard $(TARGET_DEVICE_DIR)/board-info.txt)
ifndef board_info_txt
board_info_txt := $(TARGET_BOARD_INFO_FILE)
endif
$(INSTALLED_ANDROID_INFO_TXT_TARGET): $(board_info_txt)
	$(call pretty,"Generated: ($@)")
ifdef board_info_txt
	$(hide) cat $< > $@
else
	$(hide) echo "board=$(TARGET_BOOTLOADER_BOARD_NAME)" > $@
endif
