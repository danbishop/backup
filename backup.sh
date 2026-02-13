#!/bin/bash

# Load secrets if the file exists
if [ -f "/root/secrets" ]; then
    source "/root/secrets"
else
    echo "Error: secrets file not found!"
    exit 1
fi

# Backup SSH Keys/Fingerprints
if [ ! -d "/mnt/storage/backups/ssh" ]; then
  mkdir -p /mnt/storage/backups/ssh
fi
rsync -a --delete /etc/ssh/ssh_host* /mnt/storage/backups/ssh

# Backup home directories


# Backup Immich database
if [ ! -d "/mnt/storage/backups/immich" ]; then
  mkdir -p /mnt/storage/backups/immich/snap-db-backups
fi
if [ ! -d "/mnt/storage/backups/immich" ]; then
  mkdir -p /mnt/storage/backups/immich/immich-db-backups
fi
# Immich automated backups (not from the snap, but from Immich itself)
rsync -a --delete /var/snap/immich-distribution/common/upload/backups/ /mnt/storage/backups/immich/snap-db-backups
# Immich backups from the image snap backup system
rsync -a --delete /var/snap/immich-distribution/common/backups/ /mnt/storage/backups/immich/immich-db-backups


# Backup Jellyfin database
# Trigger Backup
echo "Starting Jellyfin database backup..."

response=$(curl -s -o /dev/null -w "%{http_code}" \
    "$JELLYFIN_URL/Backup/Create" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: MediaBrowser Token=$JELLYFIN_API_KEY" \
    -d '{
        "Metadata": true,
        "Trickplay": false,
        "Subtitles": false,
        "Database": true
    }')

if [ "$response" == "200" ] || [ "$response" == "204" ]; then
    echo "Successfully created Jellyfin backup."
else
    echo "Failed to trigger Jellyfin backup. HTTP Status: $response"
fi

if [ ! -d "/mnt/storage/backups/jellyfin" ]; then
  mkdir -p /mnt/storage/backups/jellyfin
fi
# Jellyfin db backups
rsync -a --delete /var/snap/itrue-jellyfin/common/data/data/backups /mnt/storage/backups/jellyfin/



# Backup snaps
if [ ! -d "/mnt/storage/backups/snaps" ]; then
  mkdir -p /mnt/storage/backups/snaps
fi

create_snapshot() {
  local snap_name="$1"

  # Check if the argument is missing or empty
  if [[ -z "$snap_name" ]]; then
    echo "Usage: get_latest_snapshot(snapname)"
    return 1
  fi

  snap save $snap_name
  snapshot_data=$(snap saved --abs-time "$snap_name" | awk 'NR>1')
  
  # Get latest snapshot ID
  # 1. Sort by the 3rd column (Timestamp)
  # 2. Take the last line
  # 3. Print the 1st column (ID)
  latest_save_id=$(echo "$snapshot_data" | sort -k3,3 | tail -n 1 | awk '{print $1}')
  echo "Snapshot ID: $latest_save_id"


  # Get filename for export
  export_filename=$(echo "$snapshot_data" | sort -k3,3 | tail -n 1 | awk '{
      for(i=1; i<=NF-2; i++) {
        printf "%s%s", $i, (i==NF-2 ? "" : "_")
      }
      print "" 
    }' | sed 's/[^a-zA-Z0-9_-]\+/-/g')

  # Export snapshot
  snap export-snapshot $latest_save_id "/mnt/storage/backups/snaps/$snap_name_$export_filename.zip"
}

# Backup Sonarr snap
snap stop sonarr-tak
create_snapshot "sonarr-tak"
snap start sonarr-tak

# # Backup Radarr Snap
snap stop radarr-tak
create_snapshot "radarr-tak"
snap start radarr-tak

# Backup Prowlarr Snap
snap stop prowlarr-tak
create_snapshot "prowlarr-tak"
snap start prowlarr-tak

# Backup Lidarr Snap
snap stop lidarr-tak
create_snapshot "lidarr-tak"
snap start lidarr-tak

# Backup Jellyfin Snap
# snap stop itrue-jellyfin
# create_snapshot "itrue-jellyfin"
# snap start itrue-jellyfin

# Backup Nextcloud Snap
snap stop nextcloud
create_snapshot "nextcloud"
snap start nextcloud

# Backup Booklore Snap
snap stop booklore
create_snapshot "booklore"
snap start booklore

# Backup Immich Snap - Don't do this... entire photo library is mounted inside the snap
# snap stop immich-distribution
# create_snapshot "immich-distribution"
# snap start immich-distribution

# rsync -a --delete /var/lib/snapd/snapshots /mnt/storage/backups/snaps/
 # Backup Librespot
if [ ! -d "/mnt/storage/backups/librespot" ]; then
  mkdir -p /mnt/storage/backups/librespot
fi
cp -a /var/cache/librespot/credentials.json /mnt/storage/backups/librespot/


# Clean up
# Cleanup old snap snapshots

# 1. Get a list of all unique snap names that have saved snapshots
# We skip the header and grab the second column
snaps=$(snap saved | awk 'NR>1 {print $2}' | sort -u)

for s in $snaps; do
  echo "Processing snap: $s"

  # 2. Get the snapshot IDs (Set IDs) for this specific snap
  # We sort them numerically so the newest (highest ID) is at the bottom
  ids=$(snap saved | awk -v name="$s" '$2 == name {print $1}' | sort -n)

  # 3. Count how many snapshots exist for this snap
  total=$(echo "$ids" | wc -l)

  if [ "$total" -le 3 ]; then
    echo "  - only $total snapshots found. Keeping them all."
    continue
  fi

  # 4. Determine how many to forget (Total - 3)
  to_forget_count=$((total - 3))
  
  # 5. Grab the oldest IDs to be deleted
  # 'head' picks from the top (the oldest ones)
  forget_ids=$(echo "$ids" | head -n "$to_forget_count")

  for id in $forget_ids; do
    echo "  - forgetting snapshot set $id for $s..."
    snap forget "$id"
  done
done

# Cleanup Jellyfin Backups (Keep 3)
ls -1 /var/snap/itrue-jellyfin/common/data/data/backups/jellyfin-backup-*.zip 2>/dev/null | sort | head -n -3 | xargs -I {} rm -f {}

echo "Cleanup complete."

# # Cleanup exported snap backups
# # 1. Get a unique list of service names by:
# #    - Listing .zip files
# #    - Cutting the string at the underscores to get the second field
# #    - Sorting and getting unique values
# snaps=$(ls /mnt/storage/backups/snaps/*.zip | cut -d'_' -f2 | sort | uniq)

# echo "Found backups for: $(echo $snaps | xargs)"
# echo "----------------------------------------"

# for service in $snaps; do
#     echo "Processing $service..."
    
#     # List files for this service, sort newest first, skip top 3, delete rest
#     ls -1 /mnt/storage/backups/snaps/*_${service}_*.zip 2>/dev/null | sort -r | tail -n +4 | xargs -I {} rm -v {}
# done


# echo "Cleanup complete."




# Sync to Proton Drive

# TEST
# RCLONE_ALLOW_OTHER=true
# RCLONE_BUFFER_SIZE=0M
# RCLONE_STATS=300s
# RCLONE_STATS_ONE_LINE=true
# RCLONE_SYSLOG=true
# RCLONE_ALLOW_NON_EMPTY=true
# RCLONE_LOG_LEVEL=INFO
# RCLONE_CACHE_INFO_AGE=60m
# RCLONE_DIR_CACHE_TIME=30m
# RCLONE_VFS_CACHE_MAX_AGE=30m
# RCLONE_VFS_CACHE_POLL_INTERVAL=5m
# RCLONE_VFS_READ_CHUNK_SIZE=200M
# RCLONE_VFS_READ_CHUNK_SIZE_LIMIT=3G
# RCLONE_VFS_CACHE_MODE=full
# RCLONE_ATTR_TIMEOUT=5m
# RCLONE_PROTONDRIVE_REPLACE_EXISTING_DRAFT=true


# rclone sync /mnt/storage/backups protondrive:/neo-backups
# rclone sync /mnt/storage/immich protondrive:/neo-backups/storage/immich
# rclone sync /mnt/storage/home protondrive:/neo-backups/storage/home


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
