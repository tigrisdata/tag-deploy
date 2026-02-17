#!/bin/bash
#
# Install TAG binary for the current platform
#

set -euo pipefail

TAG_VERSION="${TAG_VERSION:-v1.7.0}"
TAG_RELEASES_URL="https://tag-releases.t3.storage.dev"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${ARCH}" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
esac

BINARY_NAME="tag-${OS}-${ARCH}"
DOWNLOAD_URL="${TAG_RELEASES_URL}/${TAG_VERSION}/${BINARY_NAME}"
DEST="${INSTALL_DIR}/tag"

echo "Installing TAG ${TAG_VERSION} (${OS}/${ARCH})..."

if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed"
    exit 1
fi

# Create install directory if it doesn't exist
if [ ! -d "${INSTALL_DIR}" ]; then
    echo "Creating ${INSTALL_DIR} (may require sudo)..."
    mkdir -p "${INSTALL_DIR}" 2>/dev/null || sudo mkdir -p "${INSTALL_DIR}"
fi

# Download binary to a temporary file first, then move to destination
echo "Downloading from ${DOWNLOAD_URL}..."
TMPFILE="$(mktemp)"
trap 'rm -f "${TMPFILE}"' EXIT

if ! curl -fsSL "${DOWNLOAD_URL}" -o "${TMPFILE}"; then
    echo "Error: Failed to download TAG from ${DOWNLOAD_URL}"
    exit 1
fi

# Move to destination, using sudo only if needed for permissions
if ! mv "${TMPFILE}" "${DEST}" 2>/dev/null; then
    sudo mv "${TMPFILE}" "${DEST}"
fi

chmod +x "${DEST}" 2>/dev/null || sudo chmod +x "${DEST}"

echo "TAG ${TAG_VERSION} installed to ${DEST}"
echo ""
echo "Verify with:"
echo "  tag --version"
