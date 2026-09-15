LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),X625D)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
