#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
seed_file="${script_dir}/ldap/bootstrap.ldif"
ldap_container="op1-ldap-1"
fresh="false"

usage() {
  cat <<'EOF'
Usage:
  ./01-seed-op1-ldap.sh [--fresh]

Flags:
  --fresh   Remove existing LDAP people/groups subtrees before seeding
  --help    Show this help
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --fresh)
      fresh="true"
      ;;
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

if [[ ! -f "${seed_file}" ]]; then
  echo "Error: seed file not found at ${seed_file}" >&2
  exit 1
fi

if [[ -z "$(docker ps --filter "name=^${ldap_container}$" --format '{{.Names}}')" ]]; then
  echo "Error: ${ldap_container} is not running" >&2
  exit 1
fi

if [[ "${fresh}" == "true" ]]; then
  echo "Fresh mode: deleting existing LDAP subtrees..."
  docker exec "${ldap_container}" ldapdelete -r -x \
    -H ldap://127.0.0.1:389 \
    -D "cn=admin,dc=op1,dc=dev,dc=localhost" \
    -w adminpw \
    "ou=people,dc=op1,dc=dev,dc=localhost" >/dev/null 2>&1 || true

  docker exec "${ldap_container}" ldapdelete -r -x \
    -H ldap://127.0.0.1:389 \
    -D "cn=admin,dc=op1,dc=dev,dc=localhost" \
    -w adminpw \
    "ou=groups,dc=op1,dc=dev,dc=localhost" >/dev/null 2>&1 || true
fi

ldap_query() {
  local filter="$1"
  docker exec "${ldap_container}" ldapsearch -x \
    -H ldap://127.0.0.1:389 \
    -D "cn=admin,dc=op1,dc=dev,dc=localhost" \
    -w adminpw \
    -b "ou=people,dc=op1,dc=dev,dc=localhost" \
    "${filter}" uid 2>/dev/null || true
}

alice_lookup="$(ldap_query "(uid=alice)")"
if [[ "${fresh}" != "true" ]] && grep -q "^uid: alice$" <<<"${alice_lookup}"; then
  echo "LDAP already seeded (alice exists), nothing to do."
  exit 0
fi

docker exec -i "${ldap_container}" ldapadd -c -x \
  -H ldap://127.0.0.1:389 \
  -D "cn=admin,dc=op1,dc=dev,dc=localhost" \
  -w adminpw < "${seed_file}" || true

alice_lookup="$(ldap_query "(uid=alice)")"
bob_lookup="$(ldap_query "(uid=bob)")"

if grep -q "^uid: alice$" <<<"${alice_lookup}" && grep -q "^uid: bob$" <<<"${bob_lookup}"; then
  echo "LDAP seeding completed (alice, bob)."
  exit 0
fi

echo "Error: LDAP seeding verification failed" >&2
exit 1

