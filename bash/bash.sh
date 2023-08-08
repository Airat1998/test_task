#!/bin/bash

disks=($(lsblk -o NAME,SIZE -dn | awk '$2 >= 20G {print $1}'))

smallest_disk="${disks[0]}"
for disk in "${disks[@]}"; do
    if [ "$(lsblk -b -n -o SIZE "/dev/$disk")" -lt "$(lsblk -b -n -o SIZE "/dev/$smallest_disk")" ]; then
        smallest_disk="$disk"
    fi
done

echo "Выбранный диск: /dev/$smallest_disk"

parted "/dev/$smallest_disk" mklabel gpt
parted "/dev/$smallest_disk" mkpart primary ext4 1MiB 512MiB
parted "/dev/$smallest_disk" mkpart primary 512MiB 100%

mkfs.ext4 "/dev/${smallest_disk}1"

pvcreate "/dev/${smallest_disk}2"
vgcreate myvg "/dev/${smallest_disk}2"
lvcreate -L 2G -n swap myvg
lvcreate -l +100%FREE -n root myvg

mkfs.ext4 /dev/myvg/root

mkswap /dev/myvg/swap
swapon /dev/myvg/swap

echo "Настройка диска завершена."
