#!/bin/bash
#
# AMD AMF Runtime Installer for Fedora/Nobara
# This script securely downloads and installs the proprietary AMD Advanced
# Media Framework (AMF) libraries required for hardware acceleration in
# apps like TeamSpeak, without replacing your open-source Mesa drivers.

# Exit immediately if any command fails
set -e

echo "================================================="
echo "   AMD AMF Runtime Installer     "
echo "================================================="

# Step 1: Install required build tools
echo "-> [1/4] Installing build dependencies..."
sudo dnf install -y rpm-build wget cpio

# Step 2: Set up build environments
echo "-> [2/4] Setting up build directories..."
# Fix for "Curl Error 23": Ensure the default rpmbuild source directory exists
mkdir -p ~/rpmbuild/SOURCES

BUILD_DIR="$HOME/amf-installer-tmp"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Step 3: Download the spec file
echo "-> [3/4] Downloading the package spec file..."
SPEC_URL="https://raw.githubusercontent.com/cosmo-minecraft-tests/fedora-amdgpu-pro-maybe/main/x86_64/amdamf-pro-runtime/amdamf-pro-runtime.spec"
wget -qO amdamf-pro-runtime.spec "$SPEC_URL"

# Step 4: Build and Install the RPM
echo "-> [4/4] Compiling and installing the libraries..."

# Compile the RPM (the spec file handles downloading the AMD binaries)
rpmbuild -bb amdamf-pro-runtime.spec

# Install the newly generated RPM package
sudo dnf install -y ~/rpmbuild/RPMS/x86_64/amdamf-pro-runtime-*.rpm

# Cleanup
echo "-> Cleaning up temporary files..."
cd ~
rm -rf "$BUILD_DIR"

echo "================================================="
echo " Installation Complete! "
echo "================================================="
