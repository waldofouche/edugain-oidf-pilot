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
    server_version = "pilot-ds/2.0"

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

        body = []

        body.append("""
<!doctype html>
<html lang="en">

<head>

    <meta charset="utf-8">

    <title>Pilot Identity Provider Discovery</title>

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <script src="https://cdn.tailwindcss.com"></script>

    <style>
        body {
            font-family: Inter, system-ui, sans-serif;
        }
    </style>

</head>

<body class="min-h-screen bg-slate-100 flex flex-col">

    <main class="flex-1 flex items-center justify-center px-4 py-10">

        <div class="w-full max-w-xl">

            <!-- Card -->
            <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xl">

                <!-- Header -->
                <div class="bg-slate-900 px-8 py-6 text-white">

                    <div class="flex items-center gap-4">

                        <div class="flex h-14 w-14 items-center justify-center rounded-xl bg-white text-slate-900 shadow">

                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-7 w-7"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="2"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M12 11c0 1.657-1.343 3-3 3S6 12.657 6 11s1.343-3 3-3 3 1.343 3 3zm6 8H6a2 2 0 01-2-2v-1a6 6 0 0112 0v1a2 2 0 01-2 2zm2-8a3 3 0 11-6 0 3 3 0 016 0zm2 8v-1a6 6 0 00-4-5.659"
                                />
                            </svg>

                        </div>

                        <div>

                            <h1 class="text-2xl font-semibold">
                                Identity Provider Discovery
                            </h1>

                            <p class="mt-1 text-sm text-slate-300">
                                Select an identity provider to continue
                            </p>

                        </div>

                    </div>

                </div>

                <!-- Content -->
                <div class="px-8 py-8">

                    <div class="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-4">

                        <p class="text-sm leading-relaxed text-blue-800">
                            Choose the identity provider you would like to use
                            for this authentication session.
                        </p>

                    </div>

                    <div class="space-y-4">
""")

        for entity_id, label in IDPS:

            if return_url:
                return_parts = urllib.parse.urlsplit(return_url)

                return_query = urllib.parse.parse_qsl(
                    return_parts.query,
                    keep_blank_values=True
                )

                return_query.append((return_param, entity_id))

                target = urllib.parse.urlunsplit(
                    return_parts._replace(
                        query=urllib.parse.urlencode(return_query)
                    )
                )
            else:
                target = entity_id

            body.append(f"""
                        <a
                            href="{html.escape(target, quote=True)}"
                            class="group flex items-center justify-between rounded-xl border border-slate-200 bg-white p-5 transition hover:border-slate-300 hover:bg-slate-50 hover:shadow-md"
                        >

                            <div class="flex items-center gap-4">

                                <div class="flex h-12 w-12 items-center justify-center rounded-lg bg-slate-100 text-slate-700">

                                    <svg
                                        xmlns="http://www.w3.org/2000/svg"
                                        class="h-6 w-6"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                        stroke-width="2"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            d="M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0z"
                                        />
                                    </svg>

                                </div>

                                <div>

                                    <h2 class="text-base font-semibold text-slate-900">
                                        {html.escape(label)}
                                    </h2>

                                    <p class="mt-1 text-sm text-slate-500">
                                        Continue with this identity provider
                                    </p>

                                </div>

                            </div>

                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-5 w-5 text-slate-400 transition group-hover:translate-x-1"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="2"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    d="M9 5l7 7-7 7"
                                />
                            </svg>

                        </a>
""")

        body.append("""
                    </div>

                </div>

            </div>

            <!-- Footer -->
            <footer class="mt-8 text-center text-sm text-slate-500">

                <p>
                    © 2026 Pilot Identity Platform
                </p>

            </footer>

        </div>

    </main>

</body>
</html>
""")

        self.respond(
            "".join(body),
            "text/html; charset=utf-8"
        )

    def log_message(self, fmt: str, *args: object) -> None:
        print(
            f"{self.address_string()} - {fmt % args}",
            flush=True
        )

    def respond(self, body: str, content_type: str) -> None:
        data = body.encode("utf-8")

        self.send_response(200)

        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))

        self.end_headers()

        self.wfile.write(data)


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(
        ("0.0.0.0", PORT),
        DSHandler
    ).serve_forever()