#!/bin/bash

# Centralised colour configuration for all scripts
# Source this file in other scripts with: source "$(dirname "$0")/colors.sh"

# Define colour codes for coloured terminal output
export GREEN='\033[0;32m'    # Green text for success messages
export YELLOW='\033[1;33m'   # Yellow text for warnings
export BLUE='\033[0;34m'     # Blue text for informational messages
export RED='\033[0;31m'      # Red text for error messages and critical warnings
export NC='\033[0m'          # No Colour - resets text colour to default
