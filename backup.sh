#!/bin/bash

# Backup Nextcloud
nextcloud.export -abc
mv /var/snap/nextcloud/common/backups/* /mnt/storage/backups/nextcloud

# Boot Backup Server
wakeonlan "0c:9d:92:bf:ba:99"

# Wait 5 minutes for backup server to boot
timeout 5m bash -c 'while ! ping -c 1 backups &>/dev/null; do :; done'

# Do Backups
rclone sync --copy-links /mnt/storage/music backups:music
rclone sync --copy-links /mnt/storage/videos backups:videos --exclude=/X*/**
rclone sync --copy-links /mnt/storage/home backups:home
rclone sync --copy-links /mnt/storage/backups backups:other

# Shutdown backups.danbishop.uk
ssh -t backups@backups.danbishop.uk 'sudo shutdown -h now'
