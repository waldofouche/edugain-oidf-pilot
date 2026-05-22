#!/usr/bin/env bash

printf 'Content-Type: text/plain\n\n'
printf 'OP1 SAML SP Test\n\n'
env | sort | grep -E '^(MELLON_|REMOTE_USER|AUTH_TYPE|HTTP_)' || true

