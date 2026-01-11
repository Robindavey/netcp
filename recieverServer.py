#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import socketserver
import socket
from urllib.parse import urlparse, parse_qs
import os
from pathlib import Path

# ==========================
# Configuration
# ==========================
PORT = 9100
HOST = "0.0.0.0"
DESKTOP = os.path.expanduser("~/Desktop/Programs")
DEFAULT_BUCKET = os.path.join(DESKTOP, "netcp_bucket")
os.makedirs(DEFAULT_BUCKET, exist_ok=True)  # ensure bucket exists
# Load allowed IPs from the repository `allowedIP` file (one per line).
try:
    with open("allowedIP", "r") as f:
        allowedIP = [line.strip() for line in f if line.strip()]
except FileNotFoundError:
    allowedIP = []
# Banned directories for safety
BANNED_DIRS = {".git", "__pycache__", "venv", "venv2", ".venv"}
# Allowed absolute destination prefixes (one per line) can be listed in `allowedPaths`.
try:
    with open("allowedPaths", "r") as f:
        ALLOWED_ABS_PREFIXES = [line.strip() for line in f if line.strip()]
except FileNotFoundError:
    ALLOWED_ABS_PREFIXES = []

# Always allow paths under the receiver user's home directory
HOME_DIR = os.path.expanduser("~")
def getLocalIP():
    import socket

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))  # doesn't actually send data
        local_ip = s.getsockname()[0]
    finally:
        s.close()

    return local_ip
CONFIGPORT = PORT +1
# ==========================
# HTTP Request Handler
# ==========================
class FileReceiverHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        try:
            # Parse query parameters
            parsed_url = urlparse(self.path)
            params = parse_qs(parsed_url.query)

            # Determine client IP from the socket (parsed_url.hostname is None)
            client_ip = self.client_address[0]
            if client_ip not in allowedIP:
                self.send_response(403)
                self.end_headers()
                self.wfile.write(f"Forbidden: IP {client_ip} not allowed\nTry using {getLocalIP()}:{CONFIGPORT} to add".encode())
                return

            relative_path = os.path.normpath(params.get("file", ["uploaded_file"])[0].strip())
            abs_flag = params.get("abs", ["0"])[0]
            is_absolute = str(abs_flag).lower() in ("1", "true", "yes")

            if is_absolute:
                # treat provided value as an absolute path (or make absolute)
                dest_path = os.path.abspath(relative_path)
                # Allow anything under any user's /home directory (e.g. /home/serv1user/...)
                if dest_path == "/home" or dest_path.startswith(os.path.join("/home", "")):
                    allowed = True
                else:
                    # If absolute destinations are restricted, require they start with an allowed prefix
                    if ALLOWED_ABS_PREFIXES:
                        allowed = any(dest_path.startswith(os.path.abspath(p)) for p in ALLOWED_ABS_PREFIXES)
                    else:
                        allowed = False

                    if not allowed:
                        # Log rejection for diagnosis
                        print(f"Rejected absolute destination: {dest_path}; allowed_prefixes={ALLOWED_ABS_PREFIXES} home_dir={HOME_DIR}")
                        self.send_response(403)
                        self.end_headers()
                        msg = f"Forbidden path: absolute destination not permitted\nAllowed prefixes: {ALLOWED_ABS_PREFIXES}\nHome directory allowed: {HOME_DIR}\n"
                        self.wfile.write(msg.encode())
                        return
            else:
                # Destination inside DEFAULT_BUCKET
                dest_path = os.path.abspath(os.path.join(DEFAULT_BUCKET, relative_path))

            # Safety checks
            if not is_absolute:
                # for non-absolute destinations, require they stay inside DEFAULT_BUCKET
                if not dest_path.startswith(DEFAULT_BUCKET):
                    self.send_response(403)
                    self.end_headers()
                    self.wfile.write(b"Forbidden path")
                    return

            # banned dirs check applies in both cases
            if any(part in BANNED_DIRS for part in dest_path.split(os.sep)):
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"Forbidden path")
                return

            # Ensure destination directory exists
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)

            # Read incoming file data
            content_length = self.headers.get("Content-Length")
            with open(dest_path, "wb") as f:
                if content_length is not None:
                    remaining = int(content_length)
                    while remaining > 0:
                        chunk = self.rfile.read(min(8192, remaining))
                        if not chunk:
                            break
                        f.write(chunk)
                        remaining -= len(chunk)
                else:
                    # fallback for unknown content length
                    while True:
                        chunk = self.rfile.read(8192)
                        if not chunk:
                            break
                        f.write(chunk)

            # Send success response
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"OK. File saved to {dest_path}\n".encode())
            print(f"File saved to {dest_path}")

        except Exception as e:
            # Send error response if something goes wrong
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f"Error: {str(e)}\n".encode())
            print("Error handling request:", e)

# ==========================
# Run server
# ==========================
if __name__ == "__main__":
    # Allow quick restarts by reusing the address if possible
    socketserver.TCPServer.allow_reuse_address = True

    try:
        server = HTTPServer((HOST, PORT), FileReceiverHandler)
    except OSError as e:
        print(f"Failed to bind {HOST}:{PORT}: {e}")
        # Try to give hints to the operator
        try:
            # show which process is listening (requires ss)
            import subprocess
            out = subprocess.check_output(["ss", "-ltnp"]).decode()
            print("Listening sockets (ss -ltnp):\n", out)
        except Exception:
            pass
        raise

    print(f"Server listening on {HOST}:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer shutting down...")
        server.server_close()
