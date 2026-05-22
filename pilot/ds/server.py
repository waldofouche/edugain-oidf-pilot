#!/usr/bin/env python3

from __future__ import annotations

import html
import http.server
import os
import urllib.parse

PORT = int(os.environ.get("DS_PORT", "8080"))
IDPS = [
    ("https://op1.dev.localhost/idp/shibboleth", "OP1 Shibboleth IdP"),
]


class DSHandler(http.server.BaseHTTPRequestHandler):
    server_version = "pilot-ds/1.0"

    def do_GET(self) -> None:
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == "/healthz":
            self.respond("ok\n", "text/plain; charset=utf-8")
            return
        if parsed.path not in {"/", "/WAYF"}:
            self.send_error(404, "Not found")
            return

        query = urllib.parse.parse_qs(parsed.query)
        return_url = query.get("return", [""])[0]
        return_param = query.get("returnIDParam", ["entityID"])[0]

        body = ["<!doctype html><html lang='en'><head><meta charset='utf-8'><title>Pilot SAML Discovery</title></head><body>"]
        body.append("<h1>Pilot SAML Discovery</h1>")
        body.append("<p>Select an Identity Provider for this local SAML test.</p><ul>")
        for entity_id, label in IDPS:
            if return_url:
                return_parts = urllib.parse.urlsplit(return_url)
                return_query = urllib.parse.parse_qsl(return_parts.query, keep_blank_values=True)
                return_query.append((return_param, entity_id))
                target = urllib.parse.urlunsplit(
                    return_parts._replace(query=urllib.parse.urlencode(return_query))
                )
            else:
                target = entity_id
            body.append(f"<li><a href='{html.escape(target, quote=True)}'>{html.escape(label)}</a></li>")
        body.append("</ul></body></html>\n")
        self.respond("".join(body), "text/html; charset=utf-8")

    def log_message(self, fmt: str, *args: object) -> None:
        print(f"{self.address_string()} - {fmt % args}", flush=True)

    def respond(self, body: str, content_type: str) -> None:
        data = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("0.0.0.0", PORT), DSHandler).serve_forever()

