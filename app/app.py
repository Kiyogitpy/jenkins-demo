import json
from http.server import BaseHTTPRequestHandler, HTTPServer


def greet(name="world"):
    return {"message": f"Hello, {name}!"}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(greet()).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 5000), Handler).serve_forever()
