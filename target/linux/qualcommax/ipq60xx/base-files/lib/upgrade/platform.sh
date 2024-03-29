PART_NAME=firmware
REQUIRE_IMAGE_METADATA=1

RAMFS_COPY_BIN='fw_printenv fw_setenv head'
RAMFS_COPY_DATA='/etc/fw_env.config /var/lock/fw_printenv.lock'

remove_oem_ubi_volume() {
	local oem_volume_name="$1"
	local oem_ubivol
	local mtdnum
	local ubidev

	mtdnum=$(find_mtd_index "$CI_UBIPART")
	if [ ! "$mtdnum" ]; then
		return
	fi

	ubidev=$(nand_find_ubi "$CI_UBIPART")
	if [ ! "$ubidev" ]; then
		ubiattach --mtdn="$mtdnum"
		ubidev=$(nand_find_ubi "$CI_UBIPART")
	fi

	if [ "$ubidev" ]; then
		oem_ubivol=$(nand_find_volume "$ubidev" "$oem_volume_name")
		[ "$oem_ubivol" ] && ubirmvol "/dev/$ubidev" --name="$oem_volume_name"
	fi
}

linksys_get_boot_part() {
	local cur_boot_part
	local args

	# Try to find rootfs from kernel arguments
	read -r args < /proc/cmdline
	for arg in $args; do
		local ubi_mtd_arg=${arg#ubi.mtd=}
		case "$ubi_mtd_arg" in
		rootfs|alt_rootfs)
			echo "$ubi_mtd_arg"
			return
		;;
		esac
	done

	# Fallback to u-boot env (e.g. when running sysfs)
	cur_boot_part="$(/usr/sbin/fw_printenv -n boot_part)"
	case $cur_boot_part in
	1)
		echo rootfs
		;;
	2|*)
		echo alt_rootfs
		;;
	esac
}

linksys_do_upgrade() {
	local new_boot_part

	case $(linksys_get_boot_part) in
	rootfs)
		CI_UBIPART="alt_rootfs"
		CI_KERNPART="alt_kernel"
		new_boot_part=2
	;;
	alt_rootfs)
		CI_UBIPART="rootfs"
		CI_KERNPART="kernel"
		new_boot_part=1
	;;
	esac
	echo "Updating mtd=$CI_UBIPART, boot_part=$new_boot_part"

	fw_setenv -s - <<-EOF
		boot_part $new_boot_part
		auto_recovery yes
	EOF

	remove_oem_ubi_volume squashfs
	nand_do_upgrade "$1"
}

platform_check_image() {
	return 0;
}

platform_do_upgrade() {
	case "$(board_name)" in
	linksys,mr7350)
		linksys_do_upgrade "$1"
		;;
	netgear,wax214)
		nand_do_upgrade "$1"
		;;
	*)
		default_do_upgrade "$1"
		;;
	esac
}
