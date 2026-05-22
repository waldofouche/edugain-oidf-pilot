# SP1 (SAML SP test service)

SP1 is a small Apache/mod_auth_mellon SAML SP used to test OP1 with local MDQ and DS services.

- Host: `sp1.dev.localhost`
- Entity ID: `https://sp1.dev.localhost/mellon`
- Dev keypair: `mellon/`
- SAML metadata source: `../mdq/metadata`
- Discovery Service: `https://ds.dev.localhost`
- Apache config: `apache/saml-sp.conf`

OP1 and SP1 both consume local SAML metadata from MDQ. SP1 uses DS to select OP1 during login.

## Run

Start from `pilot/sp1` after the shared Caddy network exists:

```bash
docker compose up -d --build
```

Open:

- `https://sp1.dev.localhost`

Expected flow:

1. SP1 redirects to DS.
2. DS returns OP1 as the selected IdP.
3. Log in with `alice` / `alicepw` or `bob` / `bobpw`.
4. OP1 posts the SAML response back to SP1.
5. SP1 displays the protected test page.

The keypair in `mellon/sp.key` and `mellon/sp.crt` is for local development only.

