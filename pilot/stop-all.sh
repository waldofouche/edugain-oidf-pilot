#!/usr/bin/env bash

cd rp1 && docker compose down && cd ..
cd sp1 && docker compose down && cd ..
cd op1 && docker compose down && cd ..
cd ia1 && docker compose down && cd ..
cd ia2 && docker compose down && cd ..
cd ta && docker compose down && cd ..
cd ds && docker compose down && cd ..
cd mdq && docker compose down && cd ..
cd caddy && docker compose down && cd ..
