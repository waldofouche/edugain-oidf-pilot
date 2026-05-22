#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import http.server
import os
import pathlib
import urllib.parse
import xml.etree.ElementTree as ET

METADATA_DIR = pathlib.Path(os.environ.get("MDQ_METADATA_DIR", "/metadata"))
PORT = int(os.environ.get("MDQ_PORT", "8080"))


def metadata_body(path: pathlib.Path) -> str:
    lines = path.read_text().splitlines()
    if lines and lines[0].lstrip().startswith("<?xml"):
        lines = lines[1:]
    return "\n".join(lines).strip()


def load_entities() -> dict[str, pathlib.Path]:
    entities: dict[str, pathlib.Path] = {}
    for path in sorted(METADATA_DIR.glob("*.xml")):
        root = ET.parse(path).getroot()
        entity_id = root.attrib.get("entityID")
        if entity_id:
            entities[entity_id] = path
            entities[hashlib.sha1(entity_id.encode("utf-8")).hexdigest()] = path
    return entities


class MDQHandler(http.server.BaseHTTPRequestHandler):
    server_version = "pilot-mdq/1.0"

    def do_GET(self) -> None:
        entities = load_entities()
        parsed = urllib.parse.urlsplit(self.path)

        if parsed.path in {"/", "/healthz"}:
            self.respond_text("ok\n")
            return

        if parsed.path == "/entities":
            aggregate = "<EntitiesDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\" Name=\"pilot-mdq\">\n"
            seen: set[pathlib.Path] = set()
            for path in sorted(set(entities.values())):
                if path in seen:
                    continue
                seen.add(path)
                aggregate += metadata_body(path) + "\n"
            aggregate += "</EntitiesDescriptor>\n"
            self.respond_xml(aggregate)
            return

        prefix = "/entities/"
        if not parsed.path.startswith(prefix):
            self.send_error(404, "Not found")
            return

        key = urllib.parse.unquote(parsed.path[len(prefix):])
        path = entities.get(key)
        if path is None:
            self.send_error(404, "Metadata not found")
            return

        self.respond_xml(path.read_text())

    def log_message(self, fmt: str, *args: object) -> None:
        print(f"{self.address_string()} - {fmt % args}", flush=True)

    def respond_text(self, body: str) -> None:
        data = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def respond_xml(self, body: str) -> None:
        data = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/samlmetadata+xml; charset=utf-8")
        self.send_header("Cache-Control", "max-age=60")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("0.0.0.0", PORT), MDQHandler).serve_forever()

