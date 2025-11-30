#!/bin/bash
set -e

echo "======================================"
echo "Cleanup Old Directory Structure"
echo "======================================"
echo ""
echo "This script will remove old service directories after migration."
echo "Make sure the new structure is working before proceeding!"
echo ""
read -p "Have you verified the new structure is working? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled. Please verify the new structure first."
  exit 1
fi

echo ""
echo "The following directories will be removed:"
echo "  - adguard-home/"
echo "  - emby/"
echo "  - home-assistant/"
echo "  - minecraft-mscs/"
echo "  - microk8s-setup/"
echo ""
read -p "Continue with cleanup? (yes/no): " confirm2

if [ "$confirm2" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 1
fi

echo ""
echo "Removing old directories..."

# Create a backup of old structure first
BACKUP_DIR="old-structure-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."
cp -r adguard-home "$BACKUP_DIR/" 2>/dev/null || true
cp -r emby "$BACKUP_DIR/" 2>/dev/null || true
cp -r home-assistant "$BACKUP_DIR/" 2>/dev/null || true
cp -r minecraft-mscs "$BACKUP_DIR/" 2>/dev/null || true
cp -r microk8s-setup "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup created."
echo ""
echo "Removing old directories..."

rm -rf adguard-home
rm -rf emby
rm -rf home-assistant
rm -rf minecraft-mscs
rm -rf microk8s-setup

echo ""
echo "======================================"
echo "Cleanup complete!"
echo "======================================"
echo ""
echo "Old structure backed up to: $BACKUP_DIR"
echo "New structure is now active."
echo ""
echo "If you need to restore, the backup is available."
echo "After confirming everything works, you can remove the backup:"
echo "  rm -rf $BACKUP_DIR"
