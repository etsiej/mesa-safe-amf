#!/bin/bash
#
# AMD AMF Runtime Installer for Fedora/Nobara
# This script securely downloads and installs the proprietary AMD Advanced
# Media Framework (AMF) libraries required for hardware acceleration in
# apps like OBS Studio and DaVinci Resolve, without replacing your open-source Mesa drivers.

set -eo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log helpers
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Print Banner
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}        AMD AMF Runtime Installer                ${NC}"
echo -e "${CYAN}=================================================${NC}"

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    log_error "This installer only supports x86_64 systems (detected: $ARCH)."
fi

# Check for package manager
if ! command -v dnf &>/dev/null; then
    log_error "dnf package manager not found. This installer is designed for Fedora/Nobara."
fi

# Check if running as root or has sudo access
if ! command -v sudo &>/dev/null; then
    log_error "sudo is required to install dependencies and the RPM package."
fi

# Helper functions
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -u, --uninstall  Uninstall the AMD AMF runtime package"
    exit 0
}

uninstall() {
    log_info "Checking for installed amdamf-pro-runtime..."
    if rpm -q amdamf-pro-runtime &>/dev/null; then
        log_info "Uninstalling amdamf-pro-runtime package..."
        sudo dnf remove -y amdamf-pro-runtime
        log_success "AMD AMF runtime has been successfully uninstalled!"
    else
        log_warn "amdamf-pro-runtime is not currently installed."
    fi
    exit 0
}

# Parse options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--uninstall)
            uninstall
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1. Run with --help for options."
            ;;
    esac
done

# Pre-flight Check: Detect AMD GPU
if ! lspci | grep -iE 'vga|display' | grep -i 'amd' &>/dev/null; then
    log_warn "No AMD GPU detected on this system via lspci."
    read -p "Do you want to continue with the installation anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi
fi

# Pre-flight Check: Detect if already installed
if rpm -q amdamf-pro-runtime &>/dev/null; then
    log_info "amdamf-pro-runtime is already installed."
    read -p "Would you like to reinstall or upgrade? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Exiting without changes."
        exit 0
    fi
fi

# Step 1: Install required build tools
log_info "[1/4] Installing build dependencies (rpm-build, wget, cpio, binutils)..."
sudo dnf install -y rpm-build wget cpio binutils

# Step 2: Set up build environments and download sources
log_info "[2/4] Setting up build directories and downloading AMD packages..."

# Ensure standard rpmbuild directories exist
mkdir -p "$HOME/rpmbuild/SOURCES"
mkdir -p "$HOME/rpmbuild/SPECS"

# Spec version info (must match files we download)
MAJOR="25.30"
MINOR="422"
PATCH="1"

DEB1="amf-amdgpu-pro_${MAJOR}.${MINOR}-${PATCH}_amd64.deb"
DEB2="libamdenc-amdgpu-pro_${MAJOR}.${MINOR}-${PATCH}_amd64.deb"

URL1="https://repo.radeon.com/amf/${MAJOR}/ubuntu/pool/main/questing/${DEB1}"
URL2="https://repo.radeon.com/amf/${MAJOR}/ubuntu/pool/main/questing/${DEB2}"

# Download source packages directly using wget
if [ ! -f "$HOME/rpmbuild/SOURCES/$DEB1" ]; then
    log_info "Downloading proprietary AMD AMF package: $DEB1..."
    wget -P "$HOME/rpmbuild/SOURCES" "$URL1"
else
    log_info "$DEB1 already exists in ~/rpmbuild/SOURCES, skipping download."
fi

if [ ! -f "$HOME/rpmbuild/SOURCES/$DEB2" ]; then
    log_info "Downloading proprietary AMD encoder package: $DEB2..."
    wget -P "$HOME/rpmbuild/SOURCES" "$URL2"
else
    log_info "$DEB2 already exists in ~/rpmbuild/SOURCES, skipping download."
fi

# Setup a clean workspace for the spec and compilation
BUILD_DIR=$(mktemp -d -t amf-installer-XXXXXX)
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

cd "$BUILD_DIR"

# Step 3: Generate the SPEC file
log_info "[3/4] Generating package spec file..."

cat << 'EOF' > amdamf-pro-runtime.spec
%define _build_id_links none

# global info
%global major 25.30
%global minor 422
%global patch 1

Name:     amdamf-pro-runtime
Version:  %{major}
Release:  1%{?dist}
License:       AMDGPU PRO EULA NON-REDISTRIBUTABLE
Group:         System Environment/Libraries
Summary:       System runtime for AMD Advanced Media Framework
URL:      http://repo.radeon.com/amdgpu

%undefine _disable_source_fetch
Source0:  https://repo.radeon.com/amf/%{major}/ubuntu/pool/main/questing/amf-amdgpu-pro_%{major}.%{minor}-%{patch}_amd64.deb
Source1:  https://repo.radeon.com/amf/%{major}/ubuntu/pool/main/questing/libamdenc-amdgpu-pro_%{major}.%{minor}-%{patch}_amd64.deb

Provides:      amf-runtime = %{major}-%{release}
Provides:      amf-runtime(x86_64) = %{major}-%{release}
Provides:      amf-amdgpu-pro = %{major}-%{minor}
Provides:      amf-amdgpu-pro(x86_64) = %{major}-%{minor}
Provides:      libamfrt64.so.1()(64bit) 
Provides:      libamdenc-amdgpu-pro = %{major}-%{minor}
Provides:      libamdenc-amdgpu-pro(x86_64) = %{major}-%{minor}
Provides:      libamdenc64.so.1.0()(64bit)  

Recommends:    rocm-opencl
BuildRequires: wget 
BuildRequires: cpio

Requires(post): /sbin/ldconfig  
Requires(postun): /sbin/ldconfig 
Requires:      opencl-filesystem
Recommends:    rocm-opencl-runtime  

%description
System runtime for AMD Advanced Media Framework

%prep
mkdir -p files

ar x --output . %{SOURCE0}
tar -xJC files -f data.tar.xz || tar -xC files -f data.tar.gz

ar x --output . %{SOURCE1}
tar -xJC files -f data.tar.xz || tar -xC files -f data.tar.gz

%install
mkdir -p %{buildroot}/usr/%{_lib}
mkdir -p %{buildroot}/usr/share/licenses/amf-amdgpu-pro
mkdir -p %{buildroot}/usr/share/licenses/libamdenc-amdgpu-pro

cp -r files/opt/amf/lib/x86_64-linux-gnu/* %{buildroot}/usr/%{_lib}/
cp -r files/usr/share/doc/amf-amdgpu-pro/copyright %{buildroot}/usr/share/licenses/amf-amdgpu-pro/LICENSE
cp -r files/usr/share/doc/libamdenc-amdgpu-pro/copyright %{buildroot}/usr/share/licenses/libamdenc-amdgpu-pro/LICENSE

%files
/usr/lib64/libamf*
/usr/lib64/libamdenc*
/usr/share/*

%post
/sbin/ldconfig

%postun
/sbin/ldconfig
EOF

# Step 4: Build and Install the RPM
log_info "[4/4] Compiling and installing the libraries..."

# Build the RPM
rpmbuild -bb amdamf-pro-runtime.spec

# Find built RPM package
RPM_FILE=$(find "$HOME/rpmbuild/RPMS/x86_64" -name "amdamf-pro-runtime-${MAJOR}*.rpm" | head -n 1)

if [ -z "$RPM_FILE" ]; then
    log_error "Could not locate the compiled RPM package in ~/rpmbuild/RPMS/x86_64."
fi

# Install RPM package
log_info "Installing compiled RPM: $(basename "$RPM_FILE")..."
sudo dnf install -y "$RPM_FILE"

log_success "================================================="
log_success " Installation Complete! "
log_success " AMD AMF runtime has been successfully injected. "
log_success "================================================="
