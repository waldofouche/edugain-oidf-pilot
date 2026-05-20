#!/usr/bin/env bash

set -euo pipefail

# Installs latest snapshot builds for:
# - OIDC common
# - OIDC config
# - OIDC OP
# - OIDFed OP plugin

idp_container="${IDP_CONTAINER:-op1-shibop1-1}"
plugin_bin="/opt/shibboleth-idp/bin/plugin.sh"
snapshot_keys_url="${SNAPSHOT_KEYS_URL:-https://shibboleth.net/downloads/SHIBBOLETH_SNAPSHOT_PGP_KEYS}"
snapshot_keys_file="${SNAPSHOT_KEYS_FILE:-/tmp/SHIBBOLETH_SNAPSHOT_PGP_KEYS}"
dry_run="false"

oidc_common_base="${OIDC_COMMON_BASE_URL:-https://build.shibboleth.net/maven/snapshots/net/shibboleth/oidc/oidc-common-dist/3.4.0-SNAPSHOT/}"
oidc_config_base="${OIDC_CONFIG_BASE_URL:-https://build.shibboleth.net/maven/snapshots/net/shibboleth/idp/plugin/config/oidc/idp-plugin-oidc-config-dist/3.1.0-SNAPSHOT/}"
oidc_op_base="${OIDC_OP_BASE_URL:-https://build.shibboleth.net/maven/snapshots/net/shibboleth/idp/plugin/oidc/idp-plugin-oidc-op-distribution/4.4.0-SNAPSHOT/}"
oidfed_op_base="${OIDFED_OP_BASE_URL:-https://build.shibboleth.net/nexus-proxy/content/repositories/snapshots/net/shibboleth/idp/plugin/oidfed/idp-plugin-oidfed-op-dist/1.0.0-SNAPSHOT/}"

declare -a install_urls=()

url_join() {
  local base="$1"
  local file="$2"

  if [[ "${file}" =~ ^https?:// ]]; then
    echo "${file}"
    return
  fi

  if [[ "${base}" == */ ]]; then
    echo "${base}${file}"
  else
    echo "${base}/${file}"
  fi
}

resolve_latest_tarball() {
  local base_url="$1"
  local listing
  local latest

  listing="$(curl -fsSL "${base_url}")"

  latest="$(grep -Eo 'href="[^"]+\.tar\.gz"' <<<"${listing}" \
    | sed -E 's/^href="(.*)"$/\1/' \
    | grep -vE '\.(asc|sha1|sha256)\.tar\.gz$' \
    | sort \
    | tail -n 1)"

  if [[ -z "${latest}" ]]; then
    echo "Error: failed to resolve snapshot tarball from ${base_url}" >&2
    exit 1
  fi

  url_join "${base_url}" "${latest}"
}

usage() {
  cat <<'EOF'
Usage:
  ./02-install-shib-oidc-op-snapshot.sh

Optional:
  IDP_CONTAINER=<container-name>   (default: op1-shibop1-1)
  SNAPSHOT_KEYS_URL=<url>
  SNAPSHOT_KEYS_FILE=<path-inside-container>   (default: /tmp/SHIBBOLETH_SNAPSHOT_PGP_KEYS)

Override snapshot directories:
  OIDC_COMMON_BASE_URL=<url>
  OIDC_CONFIG_BASE_URL=<url>
  OIDC_OP_BASE_URL=<url>
  OIDFED_OP_BASE_URL=<url>

Flags:
  --dry-run   Resolve and print URLs only; do not install
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run="true"
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required" >&2
  exit 1
fi

if [[ -z "$(docker ps --filter "name=^${idp_container}$" --format '{{.Names}}')" ]]; then
  echo "Error: IdP container ${idp_container} is not running" >&2
  exit 1
fi

run_plugin() {
  docker exec "${idp_container}" "${plugin_bin}" "$@"
}

install_urls+=("$(resolve_latest_tarball "${oidc_common_base}")")
install_urls+=("$(resolve_latest_tarball "${oidc_config_base}")")
install_urls+=("$(resolve_latest_tarball "${oidc_op_base}")")
install_urls+=("$(resolve_latest_tarball "${oidfed_op_base}")")

echo "Resolved snapshot artifacts:"
for url in "${install_urls[@]}"; do
  echo " - ${url}"
done

if [[ "${dry_run}" == "true" ]]; then
  echo "Dry run requested; skipping installation."
  exit 0
fi

echo "Downloading snapshot PGP key bundle inside ${idp_container}..."
docker exec "${idp_container}" /bin/sh -c "set -e; if command -v curl >/dev/null 2>&1; then curl -fsSL '${snapshot_keys_url}' -o '${snapshot_keys_file}'; else wget -q -O '${snapshot_keys_file}' '${snapshot_keys_url}'; fi"

echo "Installing plugins..."
for url in "${install_urls[@]}"; do
  echo " -> ${url}"
  run_plugin --noCheck --truststore "${snapshot_keys_file}" -i "${url}" --noPrompt

done

echo "Installed plugins:"
run_plugin -fl

echo "Done. Restart ${idp_container} to ensure all plugin changes are active."

