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

export IDP_HOME IDP_HOST IDP_SCOPE

python3 - <<'PY'
import json
import os
import pathlib
import re


HOST_RE = re.compile(r"^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$")


def validate_dns_name(value: str, name: str) -> str:
    if not value:
        raise SystemExit(f"{name} must not be empty")
    if "://" in value or "/" in value or ":" in value:
        raise SystemExit(f"{name} must be a DNS host name, not a URL or host:port value")
    if len(value) > 253:
        raise SystemExit(f"{name} must be 253 characters or fewer")
    labels = value.split(".")
    if any(not HOST_RE.match(label) for label in labels):
        raise SystemExit(
            f"{name} contains an invalid DNS label; use letters, digits and hyphens only"
        )
    return value


def replace_property(path: pathlib.Path, key: str, value: str) -> None:
    text = path.read_text()
    pattern = re.compile(rf"^\s*{re.escape(key)}\s*=\s*.*$", re.MULTILINE)
    replacement = f"{key}={value}"
    text, count = pattern.subn(replacement, text, count=1)
    if count == 0:
        raise SystemExit(f"Could not find {key} in {path}")
    path.write_text(text)


idp_home = pathlib.Path(os.environ["IDP_HOME"])
idp_host = validate_dns_name(os.environ["IDP_HOST"], "IDP_HOST")
idp_scope = validate_dns_name(os.environ["IDP_SCOPE"], "IDP_SCOPE")
issuer = f"https://{idp_host}"
entity_id = f"{issuer}/idp/shibboleth"

replace_property(idp_home / "conf/idp.properties", "idp.entityID", entity_id)
replace_property(idp_home / "conf/idp.properties", "idp.scope", idp_scope)
replace_property(idp_home / "conf/oidc.properties", "idp.oidc.issuer", issuer)

discovery_file = idp_home / "static/openid-configuration.json"
if discovery_file.exists():
    discovery = json.loads(discovery_file.read_text())
    endpoint_paths = {
        "authorization_endpoint": "/idp/profile/oidc/authorize",
        "registration_endpoint": "/idp/profile/oidc/register",
        "token_endpoint": "/idp/profile/oidc/token",
        "userinfo_endpoint": "/idp/profile/oidc/userinfo",
        "introspection_endpoint": "/idp/profile/oauth2/introspection",
        "revocation_endpoint": "/idp/profile/oauth2/revocation",
        "jwks_uri": "/idp/profile/oidc/keyset",
        "end_session_endpoint": "/idp/profile/oidc/end-session",
        "pushed_authorization_request_endpoint": "/idp/profile/oauth2/pushed-authorization",
    }
    discovery["issuer"] = issuer
    for key, path in endpoint_paths.items():
        if key in discovery:
            discovery[key] = f"{issuer}{path}"
    discovery_file.write_text(json.dumps(discovery, indent=3) + "\n")

metadata_file = idp_home / "metadata/idp-metadata.xml"
if metadata_file.exists():
    metadata = metadata_file.read_text()
    metadata = re.sub(
        r'entityID="https://[^"]+/idp/shibboleth"',
        f'entityID="{entity_id}"',
        metadata,
        count=1,
    )
    metadata = re.sub(r"https://[^\s\"<>]+/idp/", f"{issuer}/idp/", metadata)
    metadata = re.sub(r"at [A-Za-z0-9.-]+", f"at {idp_host}", metadata)
    metadata_file.write_text(metadata)

print(f"Configured Shibboleth IdP host={idp_host} scope={idp_scope}")
PY

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

