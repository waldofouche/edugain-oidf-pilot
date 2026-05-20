#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="${script_dir}/shibboleth-idp-docker"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required" >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "Error: openssl is required" >&2
  exit 1
fi

if [[ ! -d "${repo_dir}" ]]; then
  git clone --depth 1 https://github.com/iay/shibboleth-idp-docker "${repo_dir}"
fi

cd "${repo_dir}"

# Configure a local entity ID and host for this pilot deployment.
sed -i.bak 's/^SCOPE=.*/SCOPE=dev.localhost/' install-idp
sed -i.bak 's/^HOST=.*/HOST=op1.dev.localhost/' install-idp
sed -i.bak 's#^ENTITYID=.*#ENTITYID=https://op1.dev.localhost/idp/shibboleth#' install-idp

./fetch-jetty
./fetch-shib
./install

mkdir -p shibboleth-idp/credentials

# Generate a local self-signed browser-facing credential used by Jetty.
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -keyout /tmp/op1-userfacing.key \
  -out /tmp/op1-userfacing.crt \
  -subj "/C=AA/ST=state/L=locality/O=eduGAIN/OU=OIDF Pilot/CN=op1.dev.localhost/emailAddress=support@op1.dev.localhost"

openssl pkcs12 -export \
  -out shibboleth-idp/credentials/idp-userfacing.p12 \
  -inkey /tmp/op1-userfacing.key \
  -in /tmp/op1-userfacing.crt \
  -passout pass:changeit

rm -f /tmp/op1-userfacing.key /tmp/op1-userfacing.crt

# Configure password authn against local OpenLDAP service.
cat > shibboleth-idp/conf/ldap.properties <<'EOF'
idp.authn.LDAP.ldapURL = ldap://ldap:389
idp.authn.LDAP.useStartTLS = false
idp.authn.LDAP.useSSL = false
idp.authn.LDAP.baseDN = ou=people,dc=op1,dc=dev,dc=localhost
idp.authn.LDAP.bindDN = cn=admin,dc=op1,dc=dev,dc=localhost
idp.authn.LDAP.bindDNCredential = adminpw
idp.authn.LDAP.userFilter = (uid={user})
idp.authn.LDAP.dnFormat = uid=%s,ou=people,dc=op1,dc=dev,dc=localhost
idp.authn.LDAP.returnAttributes = uid mail givenName sn cn
EOF

cat > shibboleth-idp/conf/authn/password-authn.properties <<'EOF'
idp.authn.Password.validateAsExpression = LDAP
EOF

./build

echo "Bootstrap completed. Start OP1 with: docker compose -f ${script_dir}/docker-compose.yaml up -d"

