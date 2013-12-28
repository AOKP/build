# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
ARCH_ARM_HAVE_VFP_D32           := true
ARCH_ARM_HAVE_NEON              := true

ifeq ($(strip $(TARGET_CPU_VARIANT)), cortex-a15)
	arch_variant_cflags := -mcpu=cortex-a15
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a9)
	arch_variant_cflags := -mcpu=cortex-a9
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a8)
	arch_variant_cflags := -mcpu=cortex-a8
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a7)
	arch_variant_cflags := -mcpu=cortex-a7
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),cortex-a5)
	arch_variant_cflags := -mcpu=cortex-a5
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),krait)
	arch_variant_cflags := -mcpu=cortex-a9
	TARGET_USE_KRAIT_BIONIC_OPTIMIZATION := true
	TARGET_USE_KRAIT_PLD_SET := true
	TARGET_KRAIT_BIONIC_PLDOFFS := 10
	TARGET_KRAIT_BIONIC_PLDTHRESH := 10
	TARGET_KRAIT_BIONIC_BBTHRESH := 64
	TARGET_KRAIT_BIONIC_PLDSIZE := 64
else
ifeq ($(strip $(TARGET_CPU_VARIANT)),scorpion)
	arch_variant_cflags := -mcpu=cortex-a8
else
	arch_variant_cflags := -march=armv7-a
endif
endif
endif
endif
endif
endif
endif

arch_variant_cflags += \
    -mfloat-abi=softfp \
    -mfpu=neon

arch_variant_ldflags := \
	-Wl,--fix-cortex-a8
