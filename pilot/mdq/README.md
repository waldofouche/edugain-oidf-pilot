# MDQ

A tiny local SAML Metadata Query service for the pilot.

- Host: `https://mdq.dev.localhost`
- Entity lookup: `/entities/{url-encoded-entityID}` or `/entities/{sha1(entityID)}`
- Aggregate: `/entities`

Metadata files live in `metadata/` and are the source of truth for local SAML IdP/SP metadata.

## Run

```bash
docker compose up -d --build
```

Examples:

```bash
curl -k 'https://mdq.dev.localhost/entities/https%3A%2F%2Fop1.dev.localhost%2Fidp%2Fshibboleth'
curl -k 'https://mdq.dev.localhost/entities/https%3A%2F%2Fsp1.dev.localhost%2Fmellon'
```

