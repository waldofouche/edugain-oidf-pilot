#!/usr/bin/env bash

set -euo pipefail

IDP_HOME="${IDP_HOME:-/opt/shibboleth-idp}"
IDP_HOST="${IDP_HOST:-op1.dev.localhost}"
IDP_HOST="$(printf '%s' "${IDP_HOST}" | tr '[:upper:]' '[:lower:]')"

if [[ -z "${IDP_SCOPE:-}" ]]; then
  if [[ "${IDP_HOST}" == *.* ]]; then
    IDP_SCOPE="${IDP_HOST#*.}"
  else
    IDP_SCOPE="${IDP_HOST}"
  fi
fi
IDP_SCOPE="$(printf '%s' "${IDP_SCOPE}" | tr '[:upper:]' '[:lower:]')"

validate_dns_name() {
  local value="$1"
  local name="$2"
  local label

  if [[ -z "${value}" ]]; then
    echo "Error: ${name} must not be empty" >&2
    exit 1
  fi
  if [[ "${value}" == *://* || "${value}" == */* || "${value}" == *:* || ${#value} -gt 253 ]]; then
    echo "Error: ${name} must be a DNS host name, not a URL or host:port value" >&2
    exit 1
  fi

  IFS='.' read -ra labels <<<"${value}"
  for label in "${labels[@]}"; do
    if [[ ! "${label}" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; then
      echo "Error: ${name} contains an invalid DNS label" >&2
      exit 1
    fi
  done
}

validate_dns_name "${IDP_HOST}" IDP_HOST
validate_dns_name "${IDP_SCOPE}" IDP_SCOPE

issuer="https://${IDP_HOST}"
entity_id="${issuer}/idp/shibboleth"

export IDP_HOME IDP_HOST IDP_SCOPE
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Didp.entityID=${entity_id} -Didp.scope=${IDP_SCOPE} -Didp.oidc.issuer=${issuer}"

echo "Configured Shibboleth IdP host=${IDP_HOST} scope=${IDP_SCOPE}"

credentials_dir="${IDP_HOME}/credentials"
mkdir -p "${credentials_dir}"

host_marker="${credentials_dir}/.idp-userfacing.host"
keystore="${credentials_dir}/idp-userfacing.p12"
if [[ ! -s "${keystore}" || "$(cat "${host_marker}" 2>/dev/null || true)" != "${IDP_HOST}" ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT

  openssl req -quiet -new -newkey rsa:4096 -days "${IDP_CERT_DAYS:-365}" -nodes -x509 \
    -keyout "${tmp_dir}/idp-userfacing.key" \
    -out "${tmp_dir}/idp-userfacing.crt" \
    -subj "/C=AA/ST=state/L=locality/O=eduGAIN/OU=OIDF Pilot/CN=${IDP_HOST}/emailAddress=support@${IDP_HOST}" \
    2>"${tmp_dir}/openssl-req.err" || { cat "${tmp_dir}/openssl-req.err" >&2; exit 1; }

  openssl pkcs12 -export \
    -out "${keystore}" \
    -inkey "${tmp_dir}/idp-userfacing.key" \
    -in "${tmp_dir}/idp-userfacing.crt" \
    -passout pass:changeit \
    2>"${tmp_dir}/openssl-pkcs12.err" || { cat "${tmp_dir}/openssl-pkcs12.err" >&2; exit 1; }

  printf '%s\n' "${IDP_HOST}" > "${host_marker}"
fi

exec "$@"

