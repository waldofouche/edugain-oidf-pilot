#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./install-all.sh

Runs OP1 setup in this order:
  1) docker compose build shibop1
  2) docker compose up -d
  3) 01-seed-op1-ldap.sh

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

run_step "Building OP1 IdP image" docker compose -f "${script_dir}/docker-compose.yaml" build shibop1
run_step "Starting OP1 containers" docker compose -f "${script_dir}/docker-compose.yaml" up -d

# Always seed from a clean LDAP subtree for deterministic local installs.
run_step "Seeding LDAP users (fresh)" "${script_dir}/01-seed-op1-ldap.sh" --fresh


echo "==> OP1 install-all completed"

