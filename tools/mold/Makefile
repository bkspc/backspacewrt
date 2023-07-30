# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

PKG_NAME:=mold
PKG_VERSION:=2.0.0

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL_FILE:=v$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/rui314/mold/archive/refs/tags
PKG_HASH:=2ae8a22db09cbff626df74c945079fa29c1e5f60bbe02502dcf69191cf43527b

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_HOST_OPTIONS += \
	-DMOLD_LTO=ON \
	-DMOLD_MOSTLY_STATIC=ON \
	-DMOLD_USE_SYSTEM_MIMALLOC=OFF \
	-DMOLD_USE_SYSTEM_TBB=OFF

$(eval $(call HostBuild))
