SUBTARGET:=ipq60xx
FEATURES += source-only
BOARDNAME:=Qualcomm Atheros IPQ60xx
CPU_TYPE:=cortex-a73
ARCH_PACKAGES:=aarch64_cortex-a53
DEFAULT_PACKAGES += ath11k-firmware-ipq6018

define Target/Description
	Build firmware images for Qualcomm Atheros IPQ60xx based boards.
endef
