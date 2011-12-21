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

ifeq ($(TARGET_NEEDS_MOTOROLA_HIJACK), true)

# store the path of this makefile for use later
MY_PATH := $(call my-dir)

# set our local path
LOCAL_PATH := $(MY_PATH)

# output for hijack_boot
HIJACK_BOOT_OUT := $(PRODUCT_OUT)/hijack-boot
HIJACK_BOOT_OUT_UNSTRIPPED := $(TARGET_OUT_UNSTRIPPED)/hijack-boot

# prerequisites for building hijack-boot.zip are defined in HIJACK_BOOT_PREREQS

# we require the a copy of the root directory, so to get that we wait until
# INSTALLED_BOOTIMAGE_TARGET (which is not set in this file, so we reference
# it explicitly) is available.
HIJACK_BOOT_PREREQS := $(PRODUCT_OUT)/boot.img

# we require the recovery.fstab file, so to get that we wait until
# INSTALLED_RECOVERYIMAGE_TARGET (which is not set in this file, so we reference
# it explicitly) is available.
HIJACK_BOOT_PREREQS += $(PRODUCT_OUT)/recovery.img

# copy the hijack file
file := $(HIJACK_BOOT_OUT)/sbin/hijack
$(file) : $(call intermediates-dir-for,EXECUTABLES,hijack)/hijack
	@echo "Copy hijack -> $@"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) cp -a $(call intermediates-dir-for,EXECUTABLES,hijack)/hijack $@
HIJACK_BOOT_PREREQS += $(file)

# copy hijack log dump if we must (we use a custom one for the chroot environment)
ifeq ($(BOARD_HIJACK_LOG_ENABLE),true)
file := $(HIJACK_BOOT_OUT)/sbin/hijack.log_dump
$(file) : device/motorola/common/hijack-boot/hijack.log_dump
	@echo "Copy hijack.log_dump -> $@"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) cp -a device/motorola/common/hijack-boot/hijack.log_dump $@
HIJACK_BOOT_PREREQS += $(file)
endif

# copy hijack kill script
file := $(HIJACK_BOOT_OUT)/sbin/hijack.killall
$(file) : device/motorola/common/hijack-boot/hijack.killall
	@echo "Copy hijack.killall -> $@"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) cp -a device/motorola/common/hijack-boot/hijack.killall $@
HIJACK_BOOT_PREREQS += $(file)

# set the local path for toolbox functions
LOCAL_PATH := $(ANDROID_BUILD_TOP)/system/core/toolbox

include $(CLEAR_VARS)
LOCAL_SRC_FILES := getprop.c dynarray.c
LOCAL_CFLAGS := -Dgetprop_main=main
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE := hijack_boot_getprop
LOCAL_MODULE_TAGS := optional
LOCAL_STATIC_LIBRARIES += libcutils libc
LOCAL_MODULE_CLASS := HIJACK_BOOT_EXECUTABLES
LOCAL_MODULE_PATH := $(HIJACK_BOOT_OUT)/sbin
LOCAL_UNSTRIPPED_PATH := $(HIJACK_BOOT_OUT_UNSTRIPPED)
LOCAL_MODULE_STEM := getprop
HIJACK_BOOT_PREREQS += $(LOCAL_MODULE_PATH)/$(LOCAL_MODULE_STEM)
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := stop.c
LOCAL_CFLAGS := -Dstop_main=main
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MODULE := hijack_boot_stop
LOCAL_MODULE_TAGS := optional
LOCAL_STATIC_LIBRARIES += libcutils libc
LOCAL_MODULE_CLASS := HIJACK_BOOT_EXECUTABLES
LOCAL_MODULE_PATH := $(HIJACK_BOOT_OUT)/sbin
LOCAL_UNSTRIPPED_PATH := $(HIJACK_BOOT_OUT_UNSTRIPPED)
LOCAL_MODULE_STEM := stop
HIJACK_BOOT_PREREQS += $(LOCAL_MODULE_PATH)/$(LOCAL_MODULE_STEM)
include $(BUILD_EXECUTABLE)

# reset our local path
LOCAL_PATH := $(MY_PATH)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := 2nd-init.c
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_CFLAGS := -Os
LOCAL_MODULE := hijack_boot_2nd-init
LOCAL_MODULE_TAGS := optional
LOCAL_STATIC_LIBRARIES += libc
LOCAL_MODULE_CLASS := HIJACK_BOOT_EXECUTABLES
LOCAL_MODULE_PATH := $(HIJACK_BOOT_OUT)/sbin
LOCAL_UNSTRIPPED_PATH := $(HIJACK_BOOT_OUT_UNSTRIPPED)
LOCAL_MODULE_STEM := 2nd-init

ifeq ($(BOARD_USES_BOOTMENU),true)
        LOCAL_MODULE_PATH := $(PRODUCT_OUT)/system/bootmenu/binary
endif

HIJACK_BOOT_PREREQS += $(LOCAL_MODULE_PATH)/$(LOCAL_MODULE_STEM)
include $(BUILD_EXECUTABLE)

# now we make the hijack-boot target files package
name := $(TARGET_PRODUCT)-hijack_boot_files
intermediates := $(call intermediates-dir-for,PACKAGING,hijack_boot_files)
BUILT_HIJACK_BOOT_FILES_PACKAGE := $(intermediates)/$(name).zip
$(BUILT_HIJACK_BOOT_FILES_PACKAGE) : intermediates := $(intermediates)
$(BUILT_HIJACK_BOOT_FILES_PACKAGE) : \
		zip_root := $(intermediates)/$(name)

built_ota_tools := \
	$(call intermediates-dir-for,EXECUTABLES,applypatch)/applypatch \
	$(call intermediates-dir-for,EXECUTABLES,applypatch_static)/applypatch_static \
	$(call intermediates-dir-for,EXECUTABLES,check_prereq)/check_prereq \
	$(call intermediates-dir-for,EXECUTABLES,sqlite3)/sqlite3 \
	$(call intermediates-dir-for,EXECUTABLES,updater)/updater

$(BUILT_HIJACK_BOOT_FILES_PACKAGE) : PRIVATE_OTA_TOOLS := $(built_ota_tools)
$(BUILT_HIJACK_BOOT_FILES_PACKAGE) : PRIVATE_RECOVERY_API_VERSION := $(RECOVERY_API_VERSION)
$(BUILT_HIJACK_BOOT_FILES_PACKAGE) : \
		$(HIJACK_BOOT_PREREQS) \
		$(INSTALLED_ANDROID_INFO_TXT_TARGET) \
		$(built_ota_tools) \
		$(HOST_OUT_EXECUTABLES)/fs_config \
		| $(ACP)
	@echo "Package hijack-boot files: $@"
	$(hide) rm -rf $@ $(zip_root)
	$(hide) mkdir -p $(dir $@) $(zip_root)
	@# Copy the recovery fstab
	$(hide) mkdir -p $(zip_root)/RECOVERY/RAMDISK/etc
	$(hide) $(ACP) $(TARGET_RECOVERY_ROOT_OUT)/etc/recovery.fstab \
		$(zip_root)/RECOVERY/RAMDISK/etc
	@# Components of the boot section
	$(hide) mkdir -p $(zip_root)/NEWBOOT
	$(hide) $(call package_files-copy-root, \
		$(TARGET_ROOT_OUT),$(zip_root)/NEWBOOT)
	$(hide) $(call package_files-copy-root, \
		$(HIJACK_BOOT_OUT),$(zip_root)/NEWBOOT)
	@# Contents of the OTA package
	$(hide) mkdir -p $(zip_root)/OTA/bin
	$(hide) $(ACP) $(INSTALLED_ANDROID_INFO_TXT_TARGET) $(zip_root)/OTA/
	$(hide) $(ACP) $(PRIVATE_OTA_TOOLS) $(zip_root)/OTA/bin/
	@# Files required to build an update.zip
	$(hide) mkdir -p $(zip_root)/META
	$(hide) echo "recovery_api_version=$(PRIVATE_RECOVERY_API_VERSION)" > $(zip_root)/META/misc_info.txt
	@# Zip everything up, preserving symlinks
	$(hide) (cd $(zip_root) && zip -qry ../$(notdir $@) .)
	@# Run fs_config on all the boot files in the zip and save the output
	$(hide) echo "newboot 0 0 755" > $(zip_root)/META/filesystem_config.txt
	$(hide) zipinfo -1 $@ \
		| awk -F/ 'BEGIN { OFS="/" } /^NEWBOOT\/./' \
		| sed -r 's/^NEWBOOT\///' \
		| $(HOST_OUT_EXECUTABLES)/fs_config \
		| sed -r 's/^/newboot\//' >> $(zip_root)/META/filesystem_config.txt
	$(hide) (cd $(zip_root) && zip -q ../$(notdir $@) META/filesystem_config.txt)

# next it's the OTA target
otatools := \
	$(HOST_OUT_JAVA_LIBRARIES)/signapk.jar

HIJACK_BOOT_OTA_PACKAGE_TARGET := $(PRODUCT_OUT)/hijack-boot.zip
$(HIJACK_BOOT_OTA_PACKAGE_TARGET) : KEY_CERT_PAIR := build/target/product/security/testkey
$(HIJACK_BOOT_OTA_PACKAGE_TARGET) : $(BUILT_HIJACK_BOOT_FILES_PACKAGE) $(otatools)
	@echo "Package hijack-boot OTA: $@"
	$(hide) PYTHONPATH="${PYTHONPATH}:build/tools/releasetools" \
	   device/motorola/common/hijack-boot/ota_from_target_files -v \
	       -p $(HOST_OUT) \
	       -k $(KEY_CERT_PAIR) \
	       $(BUILT_HIJACK_BOOT_FILES_PACKAGE) $@

# we specify HIJACK_BOOT_OTA_PACKAGE_TARGET as a prebuilt ETC file so that if we
# include hijack-boot.zip, then it pulls in all the crap above here
include $(CLEAR_VARS)
# override LOCAL_PATH to . so that our OTA target is picked up
LOCAL_PATH := .
LOCAL_MODULE := hijack-boot.zip
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_ETC)
LOCAL_SRC_FILES := $(HIJACK_BOOT_OTA_PACKAGE_TARGET)
include $(BUILD_PREBUILT)

endif
