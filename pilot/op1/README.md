# OP1 (Shibboleth IdP)

This folder wires `https://github.com/iay/shibboleth-idp-docker` into the pilot as a Dockerfile-backed OP. The default host is `op1.dev.localhost`, and can be changed at runtime with `IDP_HOST`.

## What this setup uses

- Upstream Shibboleth IdP from `iay/shibboleth-idp-docker`, baked into `edugain-pilot/shib-op1:latest` by `Dockerfile.shib-op1`
- Local OpenLDAP (`osixia/openldap`) as the simplest local user datastore
- OP1 Shibboleth configuration mounted from `config/shibboleth-idp`
- Runtime hostname configuration through `IDP_HOST` and `IDP_SCOPE`
- Two seeded users from `ldap/bootstrap.ldif`:
  - `alice` / `alicepw`
  - `bob` / `bobpw`

## Setup order

Run from `pilot/op1`:

```bash
./install-all.sh
```

`install-all.sh` prepares the upstream Shibboleth/Jetty input tree, builds the OP1 image, starts the stack, and always runs LDAP seeding in fresh mode (`01-seed-op1-ldap.sh --fresh`).

Equivalent manual sequence:

```bash
./00-bootstrap-op1.sh
docker compose build shibop1
docker compose up -d
./01-seed-op1-ldap.sh --fresh
```

The bootstrap script is intentionally small. It only clones/repairs `shibboleth-idp-docker`, fetches Jetty/Shibboleth, and runs the upstream installer.

The OP1 Dockerfile will:
- package Jetty and the prepared Shibboleth IdP home into `edugain-pilot/shib-op1:latest`
- install OIDC/OIDFed snapshot plugins during image build
- generate local OIDC JWKs and the default browser-facing Jetty credential
- start with `op1.dev.localhost` by default
- take OP1-specific Shibboleth config from read-only compose mounts under `config/shibboleth-idp`
- pass hostname-derived IdP/OIDC properties at container startup from `IDP_HOST`
- regenerate the local self-signed browser-facing credential if `IDP_HOST` changes

The old post-start plugin/configuration scripts have been removed. Plugin installation is folded into `Dockerfile.shib-op1`, and OP configuration is mounted from `config/shibboleth-idp`.

## Changing the OP host

Set `IDP_HOST` when starting OP1. `IDP_SCOPE` defaults to `dev.localhost`; override it only if scoped attributes should use a different suffix.

```bash
IDP_HOST=op1-alt.dev.localhost docker compose up -d --build
```

The IdP expects a DNS host name only, not a URL or `host:port` value. The pilot Caddyfile is still outside this folder and must have a matching route for any non-default host.

## Start/stop

```bash
docker compose up -d
docker compose down
```

Seed LDAP users manually:

```bash
./01-seed-op1-ldap.sh
```

Check status:

```bash
docker compose ps
```

Local logs are available at:

- `logs/idp` for IdP logs (including `idp-process.log`)
- `logs/jetty` for Jetty logs

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

## Access

Use the existing Caddy route:
- `https://op1.dev.localhost` by default, or `https://$IDP_HOST` when overridden

LDAP admin UI:
- `https://ldap-ui.dev.localhost`
- Login DN: `cn=admin,dc=op1,dc=dev,dc=localhost`
- Password: `adminpw`

The upstream IdP uses a self-signed cert internally. Caddy terminates external TLS and proxies to IdP over HTTPS with local certificate verification disabled.

