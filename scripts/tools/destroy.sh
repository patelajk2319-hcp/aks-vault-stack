#!/bin/bash

# =============================================================================
# Cleanup Script - Destroy All Infrastructure (Legacy)
#
# WARNING: This script is deprecated. Please use the new workflow:
#   task rm   - Clear cluster resources (keeps AKS running)
#   task nuke - Destroy ALL infrastructure (requires confirmation)
#
# This script redirects to nuke.sh for backward compatibility
# =============================================================================

# Source centralised colour configuration
source "$(dirname "$0")/../lib/colors.sh"

echo -e "${YELLOW}Warning: This script is deprecated. Redirecting to nuke.sh...${NC}"
echo ""

# Redirect to the new nuke script
exec "$(dirname "$0")/nuke.sh"
