define Device/linksys_mr7350
       $(call Device/FitImage)
       $(call Device/UbiFit)
       DEVICE_VENDOR := Linksys
       DEVICE_MODEL := MR7350
       BLOCKSIZE := 128k
       PAGESIZE := 2048
       SOC := ipq6018
       DEVICE_PACKAGES := ipq-wifi-linksys_mr7350
endef
TARGET_DEVICES += linksys_mr7350
