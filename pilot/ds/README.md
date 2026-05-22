# DS

A minimal SAML Discovery Service for the local pilot.

- Host: `https://ds.dev.localhost`
- Currently lists OP1 only: `https://op1.dev.localhost/idp/shibboleth`

SP1 uses this service for IdP selection instead of hard-coding OP1 in the SP config.

## Run

```bash
docker compose up -d --build
```

