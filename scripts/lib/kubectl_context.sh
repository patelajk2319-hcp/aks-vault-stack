#!/bin/bash

# Ensures correct kubectl context is set based on AKS_CLUSTER_NAME from .env

ensure_correct_kubectl_context() {
  local script_dir="$1"

  if [ ! -f "${script_dir}/../.env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Run 'task infra' first to deploy infrastructure"
    return 1
  fi

  source "${script_dir}/../.env"

  if [ -n "${AKS_CLUSTER_NAME:-}" ]; then
    EXPECTED_CONTEXT="${AKS_CLUSTER_NAME}-admin"
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")

    if [ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]; then
      echo -e "${BLUE}Switching to kubectl context: $EXPECTED_CONTEXT${NC}"
      if ! kubectl config use-context "$EXPECTED_CONTEXT" 2>/dev/null; then
        echo -e "${RED}Error: Could not switch to context $EXPECTED_CONTEXT${NC}"
        echo -e "${YELLOW}Available contexts:${NC}"
        kubectl config get-contexts
        return 1
      fi
      echo -e "${GREEN}✓ Switched to context: $EXPECTED_CONTEXT${NC}"
    else
      echo -e "${GREEN}✓ Using kubectl context: $EXPECTED_CONTEXT${NC}"
    fi
  else
    echo -e "${YELLOW}Warning: AKS_CLUSTER_NAME not set in .env${NC}"
  fi

  return 0
}
