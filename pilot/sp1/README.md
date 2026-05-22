# SP1 (SAML SP test service)

SP1 is a small Apache/mod_auth_mellon SAML SP used to test OP1 without a CDS.

- Host: `sp1.dev.localhost`
- Entity ID: `https://sp1.dev.localhost/mellon`
- Config and dev keypair: `mellon/`
- Apache config: `apache/saml-sp.conf`

OP1 registers SP1 bilaterally by mounting `sp1/mellon/sp.xml` as local SAML metadata.

## Run

Start from `pilot/sp1` after the shared Caddy network exists:

```bash
docker compose up -d --build
```

Open:

- `https://sp1.dev.localhost`

Expected flow:

1. SP1 redirects to OP1.
2. Log in with `alice` / `alicepw` or `bob` / `bobpw`.
3. OP1 posts the SAML response back to SP1.
4. SP1 displays the protected test page.

The keypair in `mellon/sp.key` and `mellon/sp.crt` is for local development only.

