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
rsync -a --delete /var/snap/immich-distribution/common/upload/backups /mnt/storage/backups/immich-db/
# Other immich backups - sort this
rsync -a --delete /var/snap/immich-distribution/common/upload/backups/ /mnt/storage/backups/immich-db2/
rsync -a --delete /var/snap/immich-distribution/common/backups /mnt/storage/backups/immich-db3/

# Backup Jellyfin Snap
if [ ! -d "/mnt/storage/backups/jellyfin" ]; then
  mkdir -p /mnt/storage/backups/jellyfin
fi
# Jellyfin db backups
rsync -a --delete /var/snap/itrue-jellyfin/common/data/data/backups /mnt/storage/backups/jellyfin/

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
if [ ! -d "/mnt/storage/backups/librespot" ]; then
  mkdir -p /mnt/storage/backups/librespot
fi
cp -a /var/cache/librespot/credentials.json /mnt/storage/backups/librespot/


# Sync to Proton Drive

# TEST
RCLONE_ALLOW_OTHER=true
RCLONE_BUFFER_SIZE=0M
RCLONE_STATS=300s
RCLONE_STATS_ONE_LINE=true
RCLONE_SYSLOG=true
RCLONE_ALLOW_NON_EMPTY=true
RCLONE_LOG_LEVEL=INFO
RCLONE_CACHE_INFO_AGE=60m
RCLONE_DIR_CACHE_TIME=30m
RCLONE_VFS_CACHE_MAX_AGE=30m
RCLONE_VFS_CACHE_POLL_INTERVAL=5m
RCLONE_VFS_READ_CHUNK_SIZE=200M
RCLONE_VFS_READ_CHUNK_SIZE_LIMIT=3G
RCLONE_VFS_CACHE_MODE=full
RCLONE_ATTR_TIMEOUT=5m
RCLONE_PROTONDRIVE_REPLACE_EXISTING_DRAFT=true


rclone sync /mnt/storage/backups protondrive:/neo-backups
rclone sync /mnt/storage/immich protondrive:/neo-backups/storage/immich
rclone sync /mnt/storage/home protondrive:/neo-backups/storage/home


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
