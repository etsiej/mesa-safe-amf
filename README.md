# AMD AMF Runtime Installer for Fedora/Nobara

Automated script to install AMD's Advanced Media Framework (AMF) runtime on Fedora-based systems. 

This enables hardware acceleration for video encoding/decoding in applications (like OBS Studio, DaVinci Resolve, or Moonlight) *without* replacing your system's open-source Mesa drivers.

## Why use this?
Normally, getting AMF support requires installing the full proprietary `amdgpu-pro` driver stack from AMD. Doing so overwrites the excellent open-source Mesa drivers built into Linux, which can lead to display issues or lower performance in 3D gaming.

This script solves that by securely extracting *only* the specific AMF encoding/decoding libraries (`libamfrt64` and `libamdenc64`) from the official AMD Ubuntu packages, compiling them into a local RPM package, and injecting them into your system. You get hardware acceleration for your apps, while keeping Mesa untouched for your games.

## Features
- **Self-contained**: Automatically generates the RPM spec file and manages download URLs inline.
- **Pre-flight Checks**: Verifies CPU architecture (`x86_64`), package manager compatibility (`dnf`), and checks for the presence of an AMD GPU.
- **Robust Downloading**: Uses `wget` to download packages directly with clear visual progress feedback.
- **Cleanups**: Utilizes Bash traps to clean up all temporary directories even if the script is interrupted or fails.
- **Aesthetics**: Color-coded, clear steps for a professional CLI experience.
- **Lifecycle Management**: Support for installation, reinstallation/upgrades, and uninstallation.

## How to Use

### 1. Download and Prepare the Script
```bash
wget https://raw.githubusercontent.com/etsiej/mesa-safe-amf/refs/heads/main/amf-runtime-installer.sh
chmod +x amf-runtime-installer.sh
```

### 2. Run the Installation
```bash
./amf-runtime-installer.sh
```

### 3. Uninstalling the AMF Runtime
If you ever need to clean up and remove the AMF runtime from your system, simply run the script with the `--uninstall` flag:
```bash
./amf-runtime-installer.sh --uninstall
```

## How It Works
1. Installs the necessary packaging tools: `rpm-build`, `cpio`, `binutils`, and `wget`.
2. Downloads official AMD Debian packages (`amf-amdgpu-pro` and `libamdenc-amdgpu-pro`) directly to your `~/rpmbuild/SOURCES/` directory.
3. Generates a custom local RPM SPEC file to build the package.
4. Compiles a clean RPM that packages the `opt/amf/lib/` libraries directly into `/usr/lib64/`.
5. Installs the custom RPM via DNF, making it manageable directly via your package manager.