platform_export_bootpart() {
	local cmdline uuid disk

	if read cmdline < /proc/cmdline; then
		case "$cmdline" in
			*block2mtd=*)
				disk="${cmdline##*block2mtd=}"
				disk="${disk%%,*}"
			;;
			*root=*)
				disk="${cmdline##*root=}"
				disk="${disk%% *}"
			;;
		esac

		case "$disk" in
			PARTUUID=[A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9]-[A-F0-9][A-F0-9][A-F0-9][A-F0-9]-[A-F0-9][A-F0-9][A-F0-9][A-F0-9]-[A-F0-9][A-F0-9][A-F0-9][A-F0-9]-[A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9][A-F0-9]0002)
				uuid="${disk#PARTUUID=}"
				uuid="${uuid%0002}0002"
				for disk in $(find /dev -type b); do
					set -- $(dd if=$disk bs=1 skip=$((2*512+128+16)) count=16 2>/dev/null | hexdump -v -e '4/1 "%02x"' | awk '{ \
							for(i=1;i<9;i=i+2) first=substr($0,i,1) substr($0,i+1,1) first; \
							for(i=9;i<13;i=i+2) second=substr($0,i,1) substr($0,i+1,1) second; \
							for(i=13;i<16;i=i+2) third=substr($0,i,1) substr($0,i+1,1) third; \
							fourth = substr($0,17,4); \
							five = substr($0,21,12); \
						} END { print toupper(first"-"second"-"third"-"fourth"-"five) }')
					if [ "$1" = "$uuid" ]; then
						uevent="/sys/class/block/${disk##*/}/uevent"
						export SAVE_PARTITIONS=0
						break
					fi
				done
			;;
			PARTUUID=[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]-02)
				uuid="${disk#PARTUUID=}"
				uuid="${uuid%-02}"
				for disk in /dev/[hsv]d[a-z]; do
					set -- $(dd if=$disk bs=1 skip=440 count=4 2>/dev/null | hexdump -v -e '4/1 "%02x "')
					if [ "$4$3$2$1" = "$uuid" ]; then
						export BOOTPART="${disk}1"
						return 0
					fi
				done
			;;
			/dev/*)
				export BOOTPART="${disk%[0-9]}1"
				return 0
			;;
		esac
	fi

	return 1
}

platform_check_image() {
	[ "$#" -gt 1 ] && return 1

	case "$(get_magic_word "$1")" in
		eb48|eb63) return 0;;
		*)
			echo "Invalid image type"
			return 1
		;;
	esac
}

platform_copy_config() {
	if [ -b "$BOOTPART" ]; then
		mount -t ext4 -o rw,noatime "$BOOTPART" /mnt
		cp -af "$CONF_TAR" /mnt/
		umount /mnt
	fi
}

platform_do_upgrade() {
	platform_export_bootpart

	if [ -b "${BOOTPART%[0-9]}" ]; then
		sync
		get_image "$@" | dd of="${BOOTPART%[0-9]}" bs=4096 conv=fsync
		sleep 1
	fi
}
