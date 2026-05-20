#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./install-all.sh

Runs OP1 setup in this order:
  1) 00-bootstrap-op1.sh
  2) docker compose up -d
  3) 01-seed-op1-ldap.sh
  4) 02-install-shib-oidc-oidfed-snapshot-plugins.sh
  5) 03-configure-shib-oidc-oidfed-snapshot-op.sh

Flags:
  --help, -h    Show this help
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: ${arg}" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required" >&2
  exit 1
fi

run_step() {
  local description="$1"
  shift
  echo "==> ${description}"
  "$@"
}

run_step "Bootstrapping OP1 IdP image/config" "${script_dir}/00-bootstrap-op1.sh"
run_step "Starting OP1 containers" docker compose -f "${script_dir}/docker-compose.yaml" up -d

# Always seed from a clean LDAP subtree for deterministic local installs.
run_step "Seeding LDAP users (fresh)" "${script_dir}/01-seed-op1-ldap.sh" --fresh

run_step "Installing OIDC/OIDFed snapshot plugins" "${script_dir}/02-install-shib-oidc-oidfed-snapshot-plugins.sh"
run_step "Configuring OIDC/OIDFed snapshot OP" "${script_dir}/03-configure-shib-oidc-oidfed-snapshot-op.sh"

echo "==> OP1 install-all completed"

