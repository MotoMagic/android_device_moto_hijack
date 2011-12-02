#
# Copyright (C) 2009 The Android Open Source Project
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

# This lists the aspects that are unique to Motorola but shared between all
# Motorola devices. These are specially fine-tuned for devices with a hijacked
# system partition.

# include all of the hijackery
PRODUCT_PACKAGES += \
	hijack \
	hijack_boot_getprop \
	hijack_boot_2nd-init \
	hijack_boot_stop \
	hijack-boot.zip

ifeq ($(BOARD_HIJACK_LOG_ENABLE),true)
PRODUCT_PACKAGES += \
	hijack.log_dump
endif

# Get additional product configuration from the non-open-source
# counterpart to this file, if it exists. This is the most specific
# inheritance, and therefore comes first
$(call inherit-product-if-exists, vendor/motorola/common/common_hijack-vendor.mk)

# Inherit from the non-small variant of this file
$(call inherit-product, device/motorola/common/common.mk)
