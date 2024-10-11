#!/bin/bash

TEST_LOG_DIR="/mnt/test_vfs/test_log"
TEST_BACKUP_DIR="/mnt/test_vfs/test_backup"
TEST_MOUNT_POINT="/mnt/test_vfs"
TEST_FILE_SYSTEM_DIR="/tmp/test"
TEST_FILE_SYSTEM="${TEST_FILE_SYSTEM_DIR}vfs.img"
TEST_FILE_SYSTEM_SIZE=1024 # Megabytes

SCRIPT_PATH=$1

mkdir -p "$TEST_FILE_SYSTEM_DIR"
dd if=/dev/zero of="$TEST_FILE_SYSTEM" bs=1M count=$TEST_FILE_SYSTEM_SIZE
mkfs.ext4 "$TEST_FILE_SYSTEM"

mkdir -p "$TEST_MOUNT_POINT"
sudo mount -o loop "$TEST_FILE_SYSTEM" "$TEST_MOUNT_POINT"

mkdir -p "$TEST_LOG_DIR"
mkdir -p "$TEST_BACKUP_DIR"

create_files() {
  local dir=$1
  local num_files=$2
  local file_size=$3
  for i in $(seq 1 $num_files); do
    dd if=/dev/zero of="$dir/file_$i.log" bs=1M count=$file_size status=none
  done
}

echo "Test 1: oldest files"
rm -rf "$TEST_LOG_DIR"/*
rm -rf "$TEST_BACKUP_DIR"/*
create_files "$TEST_LOG_DIR" 10 10  # Create 10 files of 10MB each
bash "$SCRIPT_PATH" "$TEST_LOG_DIR" "$TEST_BACKUP_DIR" 80 3
ARCHIVE_COUNT=$(find "$TEST_BACKUP_DIR" -type f | wc -l)
if [ "$ARCHIVE_COUNT" -gt 0 ]; then
  echo "Test 1 passed"
else
  echo "Test 1 failed"
fi

echo "Test 2: below threshold"
rm -rf "$TEST_LOG_DIR"/*
rm -rf "$TEST_BACKUP_DIR"/*
create_files "$TEST_LOG_DIR" 50 5  # Create 50 files of 5MB each
bash "$SCRIPT_PATH" "$TEST_LOG_DIR" "$TEST_BACKUP_DIR" 90 5
if [ "$(find "$TEST_LOG_DIR" -type f | wc -l)" -gt 0 ]; then
  echo "Test 2 passed"
else
  echo "Test 2 failed"
fi

echo "Test 3: above threshold"
rm -rf "$TEST_LOG_DIR"/*
rm -rf "$TEST_BACKUP_DIR"/*
create_files "$TEST_LOG_DIR" 75 10  # Create 75 files of 10MB each
bash "$SCRIPT_PATH" "$TEST_LOG_DIR" "$TEST_BACKUP_DIR" 50 5
if [ "$(find "$TEST_LOG_DIR" -type f | wc -l)" -eq 0 ]; then
  echo "Test 3 passed"
else
  echo "Test 3 failed"
fi

echo "Test 4: large file"
rm -rf "$TEST_LOG_DIR"/*
rm -rf "$TEST_BACKUP_DIR"/*
create_files "$TEST_LOG_DIR" 1 500  # Create 1 file of 500MB
bash "$SCRIPT_PATH" "$TEST_LOG_DIR" "$TEST_BACKUP_DIR" 70 1
if [ "$(find "$TEST_LOG_DIR" -type f | wc -l)" -eq 0 ]; then
  echo "Test 4 passed"
else
  echo "Test 4 failed"
fi

# Cleanup
rm -rf "$TEST_LOG_DIR"/*
rm -rf "$TEST_BACKUP_DIR"/*
sudo umount "$TEST_MOUNT_POINT"
rm -f "$TEST_FILE_SYSTEM"
