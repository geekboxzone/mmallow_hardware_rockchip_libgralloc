# 
# Copyright (C) 2010 ARM Limited. All rights reserved.
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

LOCAL_PATH := $(call my-dir)


ifneq ($(strip $(TARGET_BOARD_PLATFORM)), rk3368)		# .R : 3368 的 gralloc 的源码和这里 完全无关.

# Include platform specific makefiles
include $(if $(wildcard $(LOCAL_PATH)/Android.$(TARGET_BOARD_PLATFORM).mk), $(LOCAL_PATH)/Android.$(TARGET_BOARD_PLATFORM).mk,)

MALI_ARCHITECTURE_UTGARD?=0
MALI_ION?=1
GRALLOC_VSYNC_BACKEND?=default
DISABLE_FRAMEBUFFER_HAL?=0
MALI_SUPPORT_AFBC_WIDEBLK?=0
MALI_USE_YUV_AFBC_WIDEBLK?=0
GRALLOC_USE_ION_DMA_HEAP?=0
GRALLOC_USE_ION_COMPOUND_PAGE_HEAP?=0
# AFBC buffers should be initialised after allocation in all rk platforms.
GRALLOC_INIT_AFBC?=1

# HAL module implemenation, not prelinked and stored in
# hw/<OVERLAY_HARDWARE_MODULE_ID>.<ro.product.board>.so
include $(CLEAR_VARS)
include $(BUILD_SYSTEM)/version_defaults.mk

ifeq ($(TARGET_BOARD_PLATFORM), juno)
ifeq ($(MALI_MMSS), 1)
        GRALLOC_FB_SWAP_RED_BLUE = 0
	GRALLOC_DEPTH = GRALLOC_32_BITS
	MALI_ION = 1
	MALI_AFBC_GRALLOC = 1
	MALI_DISPLAY_VERSION = 550
	AFBC_YUV420_EXTRA_MB_ROW_NEEDED = 1
	GRALLOC_USE_ION_DMA_HEAP = 1
endif
endif

ifeq ($(TARGET_BOARD_PLATFORM), armboard_v7a)
ifeq ($(GRALLOC_MALI_DP),true)
	GRALLOC_FB_SWAP_RED_BLUE = 0
	MALI_ION = 1
	DISABLE_FRAMEBUFFER_HAL=1
	MALI_AFBC_GRALLOC = 1
	MALI_DISPLAY_VERSION = 550
	GRALLOC_USE_ION_DMA_HEAP=1
endif
endif

ifeq ($(MALI_ARCHITECTURE_UTGARD),1)
	# Utgard build settings
	MALI_LOCAL_PATH?=hardware/arm/mali
	GRALLOC_DEPTH?=GRALLOC_32_BITS
	GRALLOC_FB_SWAP_RED_BLUE?=1
	MALI_DDK_INCLUDES=$(MALI_LOCAL_PATH)/include $(MALI_LOCAL_PATH)/src/ump/include
	LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw
	ifeq ($(MALI_ION),1)
		ALLOCATION_LIB := libion
		ALLOCATOR_SPECIFIC_FILES := alloc_ion.cpp gralloc_module_ion.cpp
	else
		ALLOCATION_LIB := libUMP
		ALLOCATOR_SPECIFIC_FILES := alloc_ump.cpp gralloc_module_ump.cpp
	endif
else
	# Midgard build settings
	MALI_LOCAL_PATH?=vendor/arm/mali6xx
	# GRALLOC_DEPTH?=GRALLOC_16_BITS
	GRALLOC_FB_SWAP_RED_BLUE?=0
	MALI_DDK_INCLUDES=$(MALI_LOCAL_PATH)/include $(MALI_LOCAL_PATH)/kernel/include
	LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw
	ifeq ($(MALI_ION),1)
		ALLOCATION_LIB := libion
		ALLOCATOR_SPECIFIC_FILES := alloc_ion.cpp gralloc_module_ion.cpp
	else
		ALLOCATION_LIB := libGLES_mali
		ALLOCATOR_SPECIFIC_FILES := alloc_ump.cpp gralloc_module_ump.cpp
	endif
endif	# ifeq ($(MALI_ARCHITECTURE_UTGARD),1)

$(info TARGET_BOARD_PLATFORM : $(TARGET_BOARD_PLATFORM) )
ifeq ($(TARGET_BOARD_PLATFORM), rk3288)
GRALLOC_DEPTH = GRALLOC_32_BITS
MALI_ION = 1
# MALI_DISPLAY_VERSION = 550
AFBC_YUV420_EXTRA_MB_ROW_NEEDED = 0
GRALLOC_USE_ION_DMA_HEAP = 1
USE_RK_ION=1
USE_RK_FB=1
endif 

ifeq ($(strip $(TARGET_BOARD_PLATFORM_GPU)), mali-t720)
MALI_AFBC_GRALLOC := 0
LOCAL_CFLAGS += -DMALI_PRODUCT_ID_T72X=1
endif

ifeq ($(strip $(TARGET_BOARD_PLATFORM_GPU)), mali-t760)
MALI_AFBC_GRALLOC := 1
LOCAL_CFLAGS += -DMALI_PRODUCT_ID_T76X=1
endif

ifeq ($(strip $(TARGET_BOARD_PLATFORM_GPU)), mali-t860)
MALI_AFBC_GRALLOC := 1
LOCAL_CFLAGS += -DMALI_PRODUCT_ID_T86X=1
endif

ifeq ($(MALI_AFBC_GRALLOC), 1)
AFBC_FILES = gralloc_buffer_priv.cpp
else
MALI_AFBC_GRALLOC := 0
AFBC_FILES =
endif

#If cropping should be enabled for AFBC YUV420 buffers
AFBC_YUV420_EXTRA_MB_ROW_NEEDED = 0

ifdef MALI_DISPLAY_VERSION
#if Mali display is available, should disable framebuffer HAL
DISABLE_FRAMEBUFFER_HAL := 1
#if Mali display is available, AFBC buffers should be initialised after allocation
GRALLOC_INIT_AFBC := 1
endif

LOCAL_PRELINK_MODULE := false


LOCAL_SHARED_LIBRARIES := libhardware liblog libcutils libGLESv1_CM $(ALLOCATION_LIB)

LOCAL_C_INCLUDES := $(MALI_LOCAL_PATH) $(MALI_DDK_INCLUDES) system/core/include
LOCAL_C_INCLUDES += \
        system/core/libion/include \
        system/core/libion/kernel-headers

LOCAL_CFLAGS += -DLOG_TAG=\"gralloc\" -DMALI_ION=$(MALI_ION) -DMALI_AFBC_GRALLOC=$(MALI_AFBC_GRALLOC) -D$(GRALLOC_DEPTH) -DMALI_ARCHITECTURE_UTGARD=$(MALI_ARCHITECTURE_UTGARD) -DPLATFORM_SDK_VERSION=$(PLATFORM_SDK_VERSION) -DDISABLE_FRAMEBUFFER_HAL=$(DISABLE_FRAMEBUFFER_HAL) -DMALI_SUPPORT_AFBC_WIDEBLK=$(MALI_SUPPORT_AFBC_WIDEBLK) -DMALI_USE_YUV_AFBC_WIDEBLK=$(MALI_USE_YUV_AFBC_WIDEBLK) -DAFBC_YUV420_EXTRA_MB_ROW_NEEDED=$(AFBC_YUV420_EXTRA_MB_ROW_NEEDED) -DGRALLOC_USE_ION_DMA_HEAP=$(GRALLOC_USE_ION_DMA_HEAP) -DGRALLOC_USE_ION_COMPOUND_PAGE_HEAP=$(GRALLOC_USE_ION_COMPOUND_PAGE_HEAP) -DGRALLOC_INIT_AFBC=$(GRALLOC_INIT_AFBC)
#-DSTANDARD_LINUX_SCREEN 

ifdef GRALLOC_DISP_W
LOCAL_CFLAGS += -DGRALLOC_DISP_W=$(GRALLOC_DISP_W)
endif
ifdef GRALLOC_DISP_H
LOCAL_CFLAGS += -DGRALLOC_DISP_H=$(GRALLOC_DISP_H)
endif

ifdef MALI_DISPLAY_VERSION
LOCAL_CFLAGS += -DMALI_DISPLAY_VERSION=$(MALI_DISPLAY_VERSION)
endif

ifeq ($(wildcard system/core/libion/include/ion/ion.h),)
LOCAL_C_INCLUDES += system/core/include
LOCAL_CFLAGS += -DGRALLOC_OLD_ION_API
else
LOCAL_C_INCLUDES += system/core/libion/include
endif

ifeq ($(GRALLOC_FB_SWAP_RED_BLUE),1)
LOCAL_CFLAGS += -DGRALLOC_FB_SWAP_RED_BLUE
endif

ifeq ($(GRALLOC_ARM_NO_EXTERNAL_AFBC),1)
LOCAL_CFLAGS += -DGRALLOC_ARM_NO_EXTERNAL_AFBC=1
endif

ifdef PLATFORM_CFLAGS
LOCAL_CFLAGS += $(PLATFORM_CFLAGS)
endif

ifeq ($(USE_RK_ION), 1)
LOCAL_CFLAGS += -DUSE_RK_ION 
endif
ifeq ($(USE_RK_FB), 1)
LOCAL_CFLAGS += -DUSE_RK_FB
endif

# disable arm_format_selection on rk platforms, by default.
LOCAL_CFLAGS += -DGRALLOC_ARM_FORMAT_SELECTION_DISABLE

# not in install to system/vendor/lib/hw/gralloc.rk30board.so
# LOCAL_MODULE_PATH_32 := $(TARGET_OUT_VENDOR)/lib/hw
# LOCAL_MODULE_PATH_64 := $(TARGET_OUT_VENDOR)/lib64/hw

ifeq ($(TARGET_BOARD_PLATFORM),)
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_MODULE := gralloc.default
else 
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_MODULE := gralloc.$(TARGET_BOARD_HARDWARE)
endif
# $(info LOCAL_MODULE_PATH : $(LOCAL_MODULE_PATH) )

LOCAL_MODULE_TAGS := optional
LOCAL_MULTILIB := both

LOCAL_SRC_FILES := \
	gralloc_module.cpp \
	alloc_device.cpp \
	$(ALLOCATOR_SPECIFIC_FILES) \
	framebuffer_device.cpp \
	format_chooser.cpp \
	format_chooser_blockinit.cpp \
	$(AFBC_FILES) \
	gralloc_vsync_${GRALLOC_VSYNC_BACKEND}.cpp

# LOCAL_MODULE_OWNER := arm

include $(BUILD_SHARED_LIBRARY)

endif		# ifneq ($(strip $(TARGET_BOARD_PLATFORM)), rk3368)
