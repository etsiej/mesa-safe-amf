# AMD AMF Runtime Installer for Fedora/Nobara

Automated script to install AMD's Advanced Media Framework (AMF) runtime on Fedora-based systems. 

This enables hardware acceleration for video encoding/decoding in applications *without* replacing your system's open-source Mesa drivers.

## Why use this?
Normally, getting AMF support requires installing the full proprietary `amdgpu-pro` driver stack from AMD. Doing so overwrites the excellent open-source Mesa drivers built into Linux, 

This script solves that by securely extracting *only* the specific AMF encoding/decoding libraries (`libamfrt64` and `libamdenc64`) from the official Ubuntu packages and injecting them into your system. You get hardware acceleration for your apps, while keeping Mesa untouched for your games.

## How to Use

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/etsiej/mesa-safe-amf/refs/heads/main/amf-runtime-installer.sh
    ```
   
2. Open your terminal and make the script executable by running:

    ```Bash
    chmod +x install-amf.sh
    ```
3. Run the script:
    ```Bash
    ./install-amf.sh
    ```