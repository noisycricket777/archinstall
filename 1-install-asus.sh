#!/bin/bash
clear
echo "    _             _       ___           _        _ _ "
echo "   / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | |"
echo "  / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _' | | |"
echo " / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |"
echo "/_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|"
echo ""
echo "by Stephan Raabe (2023)"
echo "-----------------------------------------------------"
echo ""
echo "Important: Please make sure that you have followed the "
echo "manual steps in the README to partition the harddisc!"
echo "Warning: Run this script at your own risk."
echo ""

# ------------------------------------------------------
# Enter partition names
# ------------------------------------------------------
lsblk
read -p "Enter the name of the EFI partition (eg. sda1): " sdb1
read -p "Enter the name of the ROOT partition (eg. sda2): " sdb2
read -p "Enter the name of the VM partition (keep it empty if not required): " sdb3

# ------------------------------------------------------
# Sync time
# ------------------------------------------------------
timedatectl set-ntp true

# ------------------------------------------------------
# Format partitions
# ------------------------------------------------------
mkfs.fat -F 32 /dev/$nvme0n1p1;
mkfs.btrfs -f /dev/$nvme0n1p2
mkfs.btrfs -f /dev/$nvme0n1p3

# ------------------------------------------------------
# Mount points for btrfs
# ------------------------------------------------------
mount /dev/$nvme0n1p2 /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@home
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@log
umount /mnt

mount -o compress=zstd:1,noatime,subvol=@ /dev/$nvme0n1p2 /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@cache /dev/$nvme0n1p2 /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@home /dev/$nvme0n1p2 /mnt/home
mount -o compress=zstd:1,noatime,subvol=@log /dev/$nvme0n1p2 /mnt/var/log
mount -o compress=zstd:1,noatime,subvol=@snapshots /dev/$nvme0n1p2 /mnt/.snapshots
mount /dev/$nvme0n1p1 /mnt/boot/efi
mkdir /mnt/vm
mount /dev/$nvme0n1p3 /mnt/vm

# ------------------------------------------------------
# Install base packages
# ------------------------------------------------------
pacstrap -K /mnt base base-devel git linux linux-firmware vim openssh reflector rsync intel-ucode

# ------------------------------------------------------
# Generate fstab
# ------------------------------------------------------
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# ------------------------------------------------------
# Install configuration scripts
# ------------------------------------------------------
mkdir /mnt/archinstall
cp 2-configuration.sh /mnt/archinstall/
cp 3-yay.sh /mnt/archinstall/
cp 4-zram.sh /mnt/archinstall/
cp 5-timeshift.sh /mnt/archinstall/
cp 6-preload.sh /mnt/archinstall/
cp 7-kvm.sh /mnt/archinstall/
cp snapshot.sh /mnt/archinstall/

# ------------------------------------------------------
# Chroot to installed sytem
# ------------------------------------------------------
arch-chroot /mnt ./archinstall/2-configuration.sh
