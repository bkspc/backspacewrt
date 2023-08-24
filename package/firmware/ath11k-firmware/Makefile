#
# Copyright (C) 2022 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ath11k-firmware
PKG_SOURCE_DATE:=2024-03-14
PKG_SOURCE_VERSION:=795809c7041582bd51bdfaa1f548b916ae8d4382
PKG_MIRROR_HASH:=d93edc651b641a97ec4f5ed329e15ac110928f863b4afbaae7fcb25953d04544
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/quic/upstream-wifi-fw.git

PKG_LICENSE_FILES:=LICENSE.qca_firmware

PKG_MAINTAINER:=Robert Marko <robimarko@gmail.com>

include $(INCLUDE_DIR)/package.mk

RSTRIP:=:
STRIP:=:

ATH11K_FIRMWARE_IPQ6018_REVISION:=1
ifeq ($(CONFIG_ATH11K_FIRMWARE_IPQ6018_2701_01744),y)
	ATH11K_FIRMWARE_IPQ6018_VERSION=2.7.0.1
	ATH11K_FIRMWARE_IPQ6018_BUILDNO=01744
else ifeq ($(CONFIG_ATH11K_FIRMWARE_IPQ6018_2601_00861),y)
	ATH11K_FIRMWARE_IPQ6018_VERSION=2.6.0.1
	ATH11K_FIRMWARE_IPQ6018_BUILDNO=00861
else ifeq ($(CONFIG_ATH11K_FIRMWARE_IPQ6018_2501_03982),y)
	ATH11K_FIRMWARE_IPQ6018_VERSION=2.5.0.1
	ATH11K_FIRMWARE_IPQ6018_BUILDNO=03982
	ATH11K_FIRMWARE_IPQ6018_REVISION=3
else ifeq ($(CONFIG_ATH11K_FIRMWARE_IPQ6018_2501_01208),y)
	ATH11K_FIRMWARE_IPQ6018_VERSION=2.5.0.1
	ATH11K_FIRMWARE_IPQ6018_BUILDNO=01208
endif

define Package/ath11k-firmware-default
  SECTION:=firmware
  CATEGORY:=Firmware
  URL:=$(PKG_SOURCE_URL)
  DEPENDS:=
endef

define Package/ath11k-firmware-ipq6018
$(Package/ath11k-firmware-default)
  TITLE:=IPQ6018 ath11k firmware
endef

define Package/ath11k-firmware-ipq8074
$(Package/ath11k-firmware-default)
  TITLE:=IPQ8074 ath11k firmware
endef

define Package/ath11k-firmware-qcn9074
$(Package/ath11k-firmware-default)
  TITLE:=QCN9074 ath11k firmware
endef

define Package/ath11k-firmware-ipq6018/config
source "$(SOURCE)/Config.in"
endef

define Build/Compile

endef

QCN9074_BOARD_REV:=8e140c65f36137714b6d8934e09dcd73cb05c2f6
QCN9074_BOARD_FILE:=board-2.bin.$(QCN9074_BOARD_REV)

define Download/qcn9074-board
  URL:=https://git.codelinaro.org/clo/ath-firmware/ath11k-firmware/-/raw/main/QCN9074/hw1.0/
  URL_FILE:=board-2.bin
  FILE:=$(QCN9074_BOARD_FILE)
  HASH:=dbf0ca14aa1229eccd48f26f1026901b9718b143bd30b51b8ea67c84ba6207f1
endef
$(eval $(call Download,qcn9074-board))

define Package/ath11k-firmware-ipq6018/install
	$(INSTALL_DIR) $(1)/lib/firmware/IPQ6018
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath11k-firmware/IPQ6018/hw1.0/$(ATH11K_FIRMWARE_IPQ6018_VERSION)/WLAN.HK.$(ATH11K_FIRMWARE_IPQ6018_VERSION)-$(ATH11K_FIRMWARE_IPQ6018_BUILDNO)-QCAHKSWPL_SILICONZ-$(ATH11K_FIRMWARE_IPQ6018_REVISION)/* \
		$(1)/lib/firmware/IPQ6018/
endef

define Package/ath11k-firmware-ipq8074/install
	$(INSTALL_DIR) $(1)/lib/firmware/IPQ8074
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath11k-firmware/IPQ8074/hw2.0/2.9.0.1/WLAN.HK.2.9.0.1-01977-QCAHKSWPL_SILICONZ-1/* \
		$(1)/lib/firmware/IPQ8074/
endef

define Package/ath11k-firmware-qcn9074/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath11k/QCN9074/hw1.0
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/ath11k-firmware/QCN9074/hw1.0/2.9.0.1/WLAN.HK.2.9.0.1-01977-QCAHKSWPL_SILICONZ-1/* \
		$(1)/lib/firmware/ath11k/QCN9074/hw1.0/
	$(INSTALL_BIN) \
		$(DL_DIR)/$(QCN9074_BOARD_FILE) $(1)/lib/firmware/ath11k/QCN9074/hw1.0/board-2.bin
endef

$(eval $(call BuildPackage,ath11k-firmware-ipq6018))
$(eval $(call BuildPackage,ath11k-firmware-ipq8074))
$(eval $(call BuildPackage,ath11k-firmware-qcn9074))
