# OP1 (Shibboleth IdP)

This folder wires `https://github.com/iay/shibboleth-idp-docker` into the pilot as a Dockerfile-backed OP. The default host is `op1.dev.localhost`, and can be changed at runtime with `IDP_HOST`.

## What this setup uses

- Upstream Shibboleth IdP from `iay/shibboleth-idp-docker`
- `Dockerfile.shib-op1`, which builds the local `edugain-pilot/shib-op1:latest` image
- Local OpenLDAP (`osixia/openldap`) as the user datastore
- OP1 Shibboleth configuration mounted read-only from `config/shibboleth-idp`
- SAML SP metadata loaded from the local MDQ service in `../mdq`
- Runtime IdP hostname/scope configuration through `IDP_HOST` and `IDP_SCOPE`
- Seed users from `ldap/bootstrap.ldif`:
  - `alice` / `alicepw`
  - `bob` / `bobpw`

OIDC/OIDFed plugins and local signing/encryption material are built into the OP1 image. SAML metadata is resolved from the local MDQ service.

## Setup

Run from `pilot/op1`:

```bash
./install-all.sh
```

This performs the complete local setup:

1. Prepare the upstream Shibboleth/Jetty input tree in `shibboleth-idp-docker`.
2. Build `edugain-pilot/shib-op1:latest`.
3. Start the OP1 stack.
4. Reseed LDAP with the demo users.

Equivalent manual sequence:

```bash
./00-bootstrap-op1.sh
docker compose build shibop1
docker compose up -d
./01-seed-op1-ldap.sh --fresh
```

`00-bootstrap-op1.sh` is intentionally small: it only clones/repairs `shibboleth-idp-docker`, fetches Jetty/Shibboleth, and runs the upstream installer. OP1-specific configuration lives outside that vendored tree.

## Start, stop, and logs

```bash
docker compose up -d
docker compose ps
docker compose logs --tail=200 shibop1
docker compose down
```

Seed LDAP users again if needed:

```bash
./01-seed-op1-ldap.sh --fresh
```

Local logs are written to:

- `logs/idp` for IdP logs, including `idp-process.log`
- `logs/jetty` for Jetty logs

## Hostname

Set `IDP_HOST` when starting OP1. `IDP_SCOPE` defaults to `dev.localhost`; override it only if scoped attributes should use a different suffix.

```bash
IDP_HOST=op1-alt.dev.localhost docker compose up -d --build
```

The IdP expects a DNS host name only, not a URL or `host:port` value. The pilot Caddyfile is still outside this folder and must have a matching route for any non-default host.

## Test bilateral OIDC flow (`oidc-test.dev.localhost`)

This verifies the static bilateral client between `oidc-test` (oauth2-proxy) and OP1 (`sp1-oidc-client`).

1. Ensure OP1 stack is up:

   ```bash
   docker compose up -d
   docker compose ps
   ```

2. Open a private/incognito browser window and go to:
   - `https://oidc-test.dev.localhost`

3. Expected redirect chain:
   - `oidc-test.dev.localhost` -> `op1.dev.localhost` login page -> back to `oidc-test.dev.localhost/oauth2/callback`

4. Log in with a seeded LDAP account:
   - `alice` / `alicepw` (or `bob` / `bobpw`)

5. Success criteria:
   - You land on the upstream whoami page (proxied by oauth2-proxy), not an error page.
   - Refreshing `https://oidc-test.dev.localhost` keeps you signed in via oauth2-proxy session cookie.

If login fails, check:

```bash
docker compose logs --tail=200 shibop1
docker compose logs --tail=200 oidc-test
```

Common local issue: stale cookies from earlier runs. Retry in a fresh private window.

## Test SAML flow (`sp1.dev.localhost`)

This verifies SP1 against OP1 using MDQ for metadata and DS for IdP discovery.

1. Ensure MDQ, DS, OP1, SP1, and Caddy are running.
   ```bash
   cd ../mdq
   docker compose up -d --build
   cd ../ds
   docker compose up -d --build
   cd ../sp1
   docker compose up -d --build
   cd ../op1
   ```
2. Open a private/incognito browser window and go to:
   - `https://sp1.dev.localhost`
3. Expected redirect chain:
   - `sp1.dev.localhost` -> `ds.dev.localhost` -> `op1.dev.localhost` login page -> back to `sp1.dev.localhost/mellon/postResponse`
4. Log in with `alice` / `alicepw` or `bob` / `bobpw`.

The SP is an Apache/mod_auth_mellon container. SP and IdP metadata live in `../mdq/metadata`; SP1 keeps only its local Mellon keypair in `../sp1/mellon`.

## Access

IdP via Caddy:

- `https://op1.dev.localhost` by default
- `https://$IDP_HOST` when overridden, if Caddy has a matching route

SAML SP test service:

- `https://sp1.dev.localhost`

LDAP admin UI:

- `https://ldap-ui.dev.localhost`
- Login DN: `cn=admin,dc=op1,dc=dev,dc=localhost`
- Password: `adminpw`

The upstream IdP uses a self-signed cert internally. Caddy terminates external TLS and proxies to IdP over HTTPS with local certificate verification disabled.

