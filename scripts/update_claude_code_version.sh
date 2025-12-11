#!/usr/bin/env sh
# update-claude-code.sh - Updates default.nix with latest claude-code version

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get latest version from npm
VERSION=$(curl -s https://registry.npmjs.org/@anthropic-ai/claude-code | grep -o '"latest":"[^"]*"' | cut -d'"' -f4)
echo "Latest version: $VERSION"

# Get SHA256 hash
SHA256=$(curl -sL "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${VERSION}.tgz" | sha256sum | cut -d' ' -f1)
echo "SHA256: $SHA256"

# Update default.nix
sed -i "s/version = \"[^\"]*\";/version = \"${VERSION}\";/" default.nix
sed -i "s/sha256 = \"[^\"]*\";/sha256 = \"${SHA256}\";/" default.nix

echo "Updated default.nix to version $VERSION"

