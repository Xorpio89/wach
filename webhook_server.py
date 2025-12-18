#!/usr/bin/env python3
"""Combined webhook + reverse proxy server"""

import subprocess
import json
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler

FLUTTER_APP = "http://localhost:8080"

# Allowed commands
ALLOWED_COMMANDS = {
    "restart": "cd C:/Sources/wach/wach_flutter && taskkill //F //IM dart.exe 2>NUL & start /B flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0",
    "status": "curl -s -o NUL -w %{http_code} http://localhost:8080",
    "git-status": "cd C:/Sources/wach && git status --short",
    "git-log": "cd C:/Sources/wach && git log --oneline -5",
    "commit": "cd C:/Sources/wach && git add -A && git commit -m \"auto-commit from webhook\"",
    "push": "cd C:/Sources/wach && git push",
    "deploy": "cd C:/Sources/wach && git add -A && git commit -m \"auto-commit\" && git push",
}

FEATURE_REQUESTS_FILE = "C:/Sources/wach/feature_requests.txt"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress logs

    def _cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def _json_response(self, status, data):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self._cors_headers()
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode())

    def _proxy_to_flutter(self):
        """Proxy request to Flutter app"""
        try:
            url = f"{FLUTTER_APP}{self.path}"
            req = urllib.request.Request(url)

            # Copy relevant headers
            for header in ['Accept', 'Accept-Language', 'Accept-Encoding']:
                if header in self.headers:
                    req.add_header(header, self.headers[header])

            with urllib.request.urlopen(req, timeout=10) as response:
                self.send_response(response.status)
                for header, value in response.getheaders():
                    if header.lower() not in ['transfer-encoding', 'connection']:
                        self.send_header(header, value)
                self._cors_headers()
                self.end_headers()
                self.wfile.write(response.read())
        except Exception as e:
            self.send_response(502)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(f"Flutter app not reachable: {e}".encode())

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path == '/webhook':
            self._json_response(200, {
                "status": "ok",
                "commands": list(ALLOWED_COMMANDS.keys()) + ["feature"],
                "usage": "POST /webhook with {\"command\": \"restart\"}",
                "feature_usage": "{\"command\": \"feature\", \"text\": \"your request\"}"
            })
        elif self.path == '/webhook/health':
            self._json_response(200, {"status": "healthy", "flutter": FLUTTER_APP})
        else:
            # Proxy to Flutter app
            self._proxy_to_flutter()

    def do_POST(self):
        if self.path != '/webhook':
            self._json_response(404, {"error": "POST only to /webhook"})
            return

        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode()

        try:
            data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            self._json_response(400, {"error": "invalid JSON"})
            return

        cmd_name = data.get('command', '')

        # Handle feature request specially
        if cmd_name == 'feature':
            feature_text = data.get('text', '').strip()
            if not feature_text:
                self._json_response(400, {"error": "missing 'text' field"})
                return
            from datetime import datetime
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M')
            with open(FEATURE_REQUESTS_FILE, 'a', encoding='utf-8') as f:
                f.write(f"[{timestamp}] {feature_text}\n")
            self._json_response(200, {
                "status": "saved",
                "feature": feature_text,
                "note": "Claude will see this in the next session"
            })
            return

        if cmd_name not in ALLOWED_COMMANDS:
            self._json_response(400, {
                "error": f"unknown command: {cmd_name}",
                "allowed": list(ALLOWED_COMMANDS.keys())
            })
            return

        cmd = ALLOWED_COMMANDS[cmd_name]

        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
            self._json_response(200, {
                "command": cmd_name,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "code": result.returncode
            })
        except subprocess.TimeoutExpired:
            self._json_response(200, {"command": cmd_name, "status": "started (background)"})
        except Exception as e:
            self._json_response(500, {"error": str(e)})

if __name__ == '__main__':
    port = 8081
    print(f"Server on port {port}")
    print(f"App: http://localhost:{port}/")
    print(f"Webhook: http://localhost:{port}/webhook")
    print(f"Commands: {list(ALLOWED_COMMANDS.keys())}")
    HTTPServer(('0.0.0.0', port), Handler).serve_forever()
