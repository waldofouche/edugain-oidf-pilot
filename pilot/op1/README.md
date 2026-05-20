# OP1 (Shibboleth IdP)

This folder wires `https://github.com/iay/shibboleth-idp-docker` into the pilot as `op1.dev.localhost`.

## What this setup uses

- Upstream Shibboleth IdP from `iay/shibboleth-idp-docker` (cloned and built locally)
- Local OpenLDAP (`osixia/openldap`) as the simplest local user datastore
- Two seeded users from `ldap/bootstrap.ldif`:
  - `alice` / `alicepw`
  - `bob` / `bobpw`
- Automatic one-shot LDAP seeding (`ldap-seed` service) on `docker compose up`

## Bootstrap once

Run from `pilot/op1`:

```bash
./bootstrap-op1.sh
```

This script will:
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

Check seed status:

```bash
docker compose ps
docker compose logs ldap-seed
```

## Access

Use the existing Caddy route:
- `https://op1.dev.localhost`

The upstream IdP uses a self-signed cert internally. Caddy terminates external TLS and proxies to IdP over HTTPS with local certificate verification disabled.

