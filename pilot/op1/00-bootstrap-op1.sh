#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="${script_dir}/shibboleth-idp-docker"
repo_url="https://github.com/iay/shibboleth-idp-docker"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required" >&2
  exit 1
fi

if [[ ! -d "${repo_dir}" ]]; then
  git clone --depth 1 "${repo_url}" "${repo_dir}"
elif [[ ! -d "${repo_dir}/.git" || ! -f "${repo_dir}/install-idp" || ! -f "${repo_dir}/install" ]]; then
  echo "Detected incomplete ${repo_dir}; recreating it from ${repo_url}"
  rm -rf "${repo_dir}"
  git clone --depth 1 "${repo_url}" "${repo_dir}"
fi

cd "${repo_dir}"

./fetch-jetty
./fetch-shib
./install

echo "Bootstrap completed. Build OP1 with: docker compose -f ${script_dir}/docker-compose.yaml build shibop1"

