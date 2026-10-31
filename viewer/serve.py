#!/usr/bin/env python3
"""Development server for the replay viewer (see `just view`)"""

import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        if "v=" in self.path:
            self.send_header("Cache-Control", "public, max-age=31536000, immutable")
        elif self.path.endswith(".pb"):
            self.send_header("Cache-Control", "public, max-age=2592000")
        else:
            self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    directory = sys.argv[1]
    port = int(sys.argv[2])
    ThreadingHTTPServer(("", port), partial(Handler, directory=directory)).serve_forever()


if __name__ == "__main__":
    main()
