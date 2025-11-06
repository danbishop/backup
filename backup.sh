#!/bin/bash

# Backup SSH Keys/Fingerprints
if [ ! -d "/mnt/storage/backups/ssh" ]; then
  mkdir -p /mnt/storage/backups/ssh
fi
rsync -a --delete /etc/ssh/ssh_host* /mnt/storage/backups/ssh

# Backup home directories


# Backup Immich database
if [ ! -d "/mnt/storage/backups/immich" ]; then
  mkdir -p /mnt/storage/backups/immich
fi
# Immich automated backups (not from the snap, but from Immich itself)
rsync -a --delete /var/snap/immich-distribution/common/upload/backups /mnt/storage/backups/immich/

# Backup Jellyfin Snap
if [ ! -d "/mnt/storage/backups/jellyfin" ]; then
  mkdir -p /mnt/storage/backups/jellyfin
fi
# Backup all the backups... this is a bit crazy, but for now...
rsync -a --delete /var/snap/itrue-jellyfin/common/data/data/backups /mnt/storage/backups/jellyfin/
rsync -a --delete /var/snap/immich-distribution/common/upload/backups/ /mnt/storage/backups/jellyfin/
rsync -a --delete /var/snap/immich-distribution/common/backups /mnt/storage/backups/jellyfin/

# Backup snaps
# if [ ! -d "/mnt/storage/backups/snaps" ]; then
#   mkdir -p /mnt/storage/backups/snaps
# fi
# snap stop sonarr-tak
# snap save sonarr-tak
# snap start sonarr-tak

# Backup Radarr Snap
# snap stop radarr-tak
# snap save radarr-tak
# snap start radarr-tak

# Backup Prowlarr Snap
# snap stop prowlarr-tak
# snap save prowlarr-tak
# snap start prowlarr-tak

# Backup Lidarr Snap
# snap stop lidarr-tak
# snap save lidarr-tak
# snap start lidarr-tak

# rsync -a --delete /var/lib/snapd/snapshots /mnt/storage/backups/snaps/

# Backup Librespot
if [ ! -d "/mnt/storage/backups/immich" ]; then
  mkdir -p /mnt/storage/backups/librespot
fi
cp -a /var/cache/librespot/credentials.json /mnt/storage/backups/librespot/


# Sync to Proton Drive
rclone sync /mnt/storage/backups protondrive:/neo-backups

# Backup Nextcloud - TO REVIEW
# nextcloud.export -abc
# mv /var/snap/nextcloud/common/backups/* /mnt/storage/backups/nextcloud

# # Boot Backup Server
# wakeonlan "0c:9d:92:bf:ba:99"

# # Wait 5 minutes for backup server to boot
# timeout 5m bash -c 'while ! ping -c 1 backups &>/dev/null; do :; done'

# # Do Backups
# rclone sync --copy-links /mnt/storage/music backups:music
# rclone sync --copy-links /mnt/storage/videos backups:videos --exclude=/X*/**
# rclone sync --copy-links /mnt/storage/home backups:home
# rclone sync --copy-links /mnt/storage/backups backups:other

# # Shutdown backups.danbishop.uk
# ssh -t backups@backups.danbishop.uk 'sudo shutdown -h now'
