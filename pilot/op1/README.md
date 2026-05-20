# OP1 (Shibboleth IdP)

This folder wires `https://github.com/iay/shibboleth-idp-docker` into the pilot as `op1.dev.localhost`.

## What this setup uses

- Upstream Shibboleth IdP from `iay/shibboleth-idp-docker` (cloned and built locally)
- Local OpenLDAP (`osixia/openldap`) as the simplest local user datastore
- Two seeded users from `ldap/bootstrap.ldif`:
  - `alice` / `alicepw`
  - `bob` / `bobpw`

## Setup order

Run from `pilot/op1`:

```bash
./install-all.sh
```

`install-all.sh` always runs LDAP seeding in fresh mode (`01-seed-op1-ldap.sh --fresh`).

Equivalent manual sequence:

```bash
./00-bootstrap-op1.sh
docker compose up -d
./01-seed-op1-ldap.sh
./02-install-shib-oidc-oidfed-snapshot-plugins.sh
./03-configure-shib-oidc-oidfed-snapshot-op.sh
```

The bootstrap script will:
- clone the upstream repository into `op1/shibboleth-idp-docker`
- fetch Jetty and Shibboleth distributions
- install IdP config for `op1.dev.localhost`
- generate a local self-signed browser-facing credential
- configure IdP password authn to use local LDAP
- build image `shibboleth-idp:12.1.9`

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
- `https://op1.dev.localhost`

LDAP admin UI:
- `https://ldap-ui.dev.localhost`
- Login DN: `cn=admin,dc=op1,dc=dev,dc=localhost`
- Password: `adminpw`

The upstream IdP uses a self-signed cert internally. Caddy terminates external TLS and proxies to IdP over HTTPS with local certificate verification disabled.

