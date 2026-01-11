#!/usr/bin/env python3
"""
Serve a simple HTML page with a centered copyable command over HTTP.
Usage:
    python3 serve_command.py [PORT]
Default PORT is 9101.
"""

import http.server
import socketserver
import sys
PORT = 9101
# ==========================
# Configuration
# ==========================
COMMAND = 'sudo netcp-add-sender Sample-IP'  # Change this to your command

# HTML template
HTML = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Command Page</title>
    <style>
        body {{
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            font-family: monospace;
            background-color: #f0f0f0;
        }}
        .command-box {{
            padding: 2em;
            background-color: #fff;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.2);
            text-align: center;
        }}
        .command {{
            font-size: 1.2em;
            color: #333;
            user-select: all;
        }}
    </style>
</head>
<body>
    <div class="command-box">
        <div class="command">{COMMAND}</div>
    </div>
</body>
</html>"""

# ==========================
# HTTP Handler
# ==========================
class CommandHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(HTML.encode('utf-8'))

    def log_message(self, format, *args):
        # Disable default logging
        return

# ==========================
# Start server
# ==========================
with socketserver.TCPServer(("0.0.0.0", PORT), CommandHandler) as httpd:
    print(f"Serving command on http://0.0.0.0:{PORT}")
    print(f"Command: {COMMAND}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
