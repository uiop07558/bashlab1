#!/bin/bash

LOG_DIR=$1
BACKUP_DIR=$2
THRESHOLD=${3:-70}
NUM_FILES=${4:-5}

if [ ! -d "$LOG_DIR" ]; then
  echo "The directory $LOG_DIR does not exist"
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "The directory $BACKUP_DIR does not exist"
  exit 1
fi

LOG_SIZE=$(du -sk "$LOG_DIR" | awk '{print $1}')
DISK_SIZE=$(df -k "$LOG_DIR" | awk 'NR==2 {print $2}')
LOG_USAGE=$(( LOG_SIZE * 100 / DISK_SIZE ))

echo "Folder usage: $LOG_USAGE%"
echo "Threshold: $THRESHOLD%"

if [ "$LOG_USAGE" -gt "$THRESHOLD" ]; then
  TIMESTAMP=$(date +"%s")
  FULL_ARCHIVE_NAME="$BACKUP_DIR/full_backup_$TIMESTAMP.tar.gz"

  tar -czf "$FULL_ARCHIVE_NAME" -C "$LOG_DIR" .
  echo "Archive: $FULL_ARCHIVE_NAME"

  find "$LOG_DIR" -type f -delete
else
  OLDEST_FILES=$(find "$LOG_DIR" -type f -printf "%T@ %p\n" | sort -n | head -n "$NUM_FILES" | awk '{print $2}')

  if [ -z "$OLDEST_FILES" ]; then
    echo "No files in folder"
    return
  fi

  TIMESTAMP=$(date +"%s")
  ARCHIVE_NAME="$BACKUP_DIR/old_files_backup_$TIMESTAMP.tar.gz"

  tar -czf "$ARCHIVE_NAME" $OLDEST_FILES
  echo "Archive: $ARCHIVE_NAME"

  rm -f $OLDEST_FILES
fi