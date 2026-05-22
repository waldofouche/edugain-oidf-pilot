#!/usr/bin/env bash

cd caddy && docker compose up -d && cd ..
cd mdq && docker compose up -d && cd ..
cd ds && docker compose up -d && cd ..
cd ta && docker compose up -d && cd ..
cd ia1 && docker compose up -d && cd ..
cd ia2 && docker compose up -d && cd ..
cd op1 && docker compose up -d && cd ..
cd sp1 && docker compose up -d && cd ..
cd rp1 && docker compose up -d && cd ..
