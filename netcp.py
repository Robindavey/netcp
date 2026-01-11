#!/home/robin/Desktop/Programs/FileTransfer-er/venv2/bin/python

import os
from sys import argv
from tqdm import tqdm

class TqdmFileReader:
    def __init__(self, file_path, chunk_size=1024 * 1024):
        self.file = open(file_path, "rb")
        self.total = os.path.getsize(file_path)
        self.tqdm = tqdm(
            total=self.total,
            unit="B",
            unit_scale=True,
            unit_divisor=1024,
            desc=os.path.basename(file_path),
            leave=True,
        )
        self.chunk_size = chunk_size

    def read(self, size=-1):
        chunk = self.file.read(self.chunk_size if size == -1 else size)
        if chunk:
            self.tqdm.update(len(chunk))
        else:
            self.tqdm.close()
            self.file.close()
        return chunk

    def __len__(self):
        return self.total


PORT = 9100 #Custom port number
from pathlib import Path
bannedDirs = {".git", "__pycache__","venv", "venv2", ".venv"}
def validate_path(path):
    p = Path(path).expanduser().resolve()

    if not p.exists():
        raise FileNotFoundError(f"The path '{p}' does not exist.")

    if p.is_file():
        return str(p), p.name, "file"
    elif p.is_dir():
        return str(p), p.name, "directory"
    else:
        raise ValueError(f"The path '{p}' is neither a file nor a directory.")

import subprocess

import requests

def send_file(local_path, dest, ip="127.0.0.1", port=PORT, absolute=False):
    if not os.path.isfile(local_path):
        raise FileNotFoundError(local_path)

    url = f"http://{ip}:{port}/send?file={dest}"
    if absolute:
        url += "&abs=1"

    reader = TqdmFileReader(local_path)

    response = requests.post(
        url,
        data=reader,
        headers={"Content-Length": str(len(reader))}
    )

    try:
        response.raise_for_status()
    except requests.exceptions.HTTPError:
        # Print server-provided error message to help the user diagnose failures
        try:
            body = response.text
        except Exception:
            body = "(no response body)"
        print(f"Server returned {response.status_code} {response.reason}:\n{body}")
        raise

import sys
    
def get_file_size(path):
    return os.path.getsize(path)

def send_directory(path, dest="", ip="127.0.0.1", port=PORT, absolute=False):
    """
    Recursively send files from 'path' to the server.
    dest: root folder on server (-d argument) or default bucket if empty
    Preserves top-level folder only once.
    """
    parent_folder = os.path.dirname(path)     # parent of FileTransfer-er
    for root, dirs, files in os.walk(path):
        # skip banned directories
        dirs[:] = [d for d in dirs if d not in bannedDirs]
        # compute relative path from parent folder (includes top folder once)
        rel_root = os.path.relpath(root, parent_folder)  # 'FileTransfer-er' or 'FileTransfer-er/subdir'
        for file_name in files:
            # combine with -D (absolute) or -d (relative) if provided
            if absolute:
                # if dest ends with separator, treat as directory and append rel_root and filename
                if dest and dest.endswith(os.sep):
                    server_dest = os.path.join(dest, rel_root, file_name)
                elif dest:
                    # treat dest as base directory (append rel_root and filename)
                    server_dest = os.path.join(dest, rel_root, file_name)
                else:
                    server_dest = os.path.join(rel_root, file_name)
            else:
                server_dest = os.path.join(dest, file_name) if dest else os.path.join(rel_root, file_name)
            local_file = os.path.join(root, file_name)

            if any(banned in local_file for banned in bannedDirs):
                        continue
            send_file(local_file, server_dest, ip=ip, port=port, absolute=absolute)
            #print(f"Sent: {local_file} -> {server_dest}")

import socket
def collect_files(path):
    files = []
    for root, dirs, filenames in os.walk(path):
        dirs[:] = [d for d in dirs if d not in bannedDirs]
        for name in filenames:
            files.append(os.path.join(root, name))
    return files

DEFAULT_BUCKET = ""  # empty string indicates default bucket on Desktop

def validate_args():
    """
    Parses command line arguments for:
    -f <path> : file or directory to send
    -d <dest> : destination relative to Desktop (optional, default bucket if empty)
    -h <ip>   : server IP address
    Returns (path, dest, ip)
    """

    args = sys.argv[1:]
    path = dest = ip = None
    absolute = False

    # Simple parsing loop
    i = 0
    while i < len(args):
        if args[i] == "-f":
            i += 1
            if i >= len(args):
                print("Error: Missing value for -f (path).")
                sys.exit(1)
            path = args[i]
        elif args[i] == "-d":
            i += 1
            if i >= len(args):
                dest = DEFAULT_BUCKET  # allow empty destination
            else:
                dest = args[i]
        elif args[i] == "-D":
            # Absolute destination (server will treat file value as absolute path when abs=1)
            i += 1
            if i >= len(args):
                print("Error: Missing value for -D (absolute destination).")
                sys.exit(1)
            dest = args[i]
            absolute = True
        elif args[i] == "-h":
            i += 1
            if i >= len(args):
                print("Error: Missing value for -h (host/IP).")
                sys.exit(1)
            ip = args[i]
        else:
            print(f"Error: Unknown argument '{args[i]}'")
            sys.exit(1)
        i += 1

    # Validate path
    if not path:
        print("Error: -f <path> is required.")
        sys.exit(1)
    if not os.path.exists(path):
        print(f"Error: The path '{path}' does not exist.")
        sys.exit(1)
    if not (os.path.isfile(path) or os.path.isdir(path)):
        print(f"Error: '{path}' is neither a file nor a directory.")
        sys.exit(1)

    # Validate dest (optional, empty allowed)
    if dest is None:
        dest = DEFAULT_BUCKET
    else:
        # Strip surrounding quotes
        dest = dest.strip()
        # Check for illegal characters in filenames
        if any(char in dest for char in "<>:\"|?*"):
            print(f"Error: Destination '{dest}' contains illegal characters.")
            sys.exit(1)
        # If user supplied an absolute path to -d, require using -D instead
        if dest and os.path.isabs(dest) and not absolute:
            print("Error: Destination appears to be an absolute path. Use -D for absolute destinations.")
            sys.exit(1)

    # Validate IP
    if not ip:
        print("Error: -h <host/IP> is required.")
        sys.exit(1)
    try:
        socket.inet_aton(ip)
    except socket.error:
        print(f"Error: '{ip}' is not a valid IP address.")
        sys.exit(1)

    return path, dest, ip, absolute

def decide_dest(dest):
    if dest == DEFAULT_BUCKET:
        return ""
    return dest + "/"


def main():
    path, dest, ip, absolute = validate_args()
    ab_path, file_name, file_type = validate_path(path)
    if file_type == "directory":
        size = get_file_size(ab_path)
        if absolute:
            base = dest if dest else ""
            send_directory(ab_path, base, ip=ip, port=PORT, absolute=True)
        else:
            send_directory(ab_path, decide_dest(dest) + file_name, ip=ip, port=PORT, absolute=False)
        pass
    else:
        if absolute:
            # if dest ends with '/' or appears to be a directory (no extension), append filename
            if dest:
                last = os.path.basename(dest)
                looks_like_dir = dest.endswith(os.sep) or ("." not in last)
                if looks_like_dir:
                    server_dest = os.path.join(dest, file_name)
                else:
                    server_dest = dest
            else:
                server_dest = file_name
            send_file(ab_path, server_dest, ip=ip, port=PORT, absolute=True)
        else:
            send_file(ab_path, decide_dest(dest)  + file_name, ip=ip, port=PORT, absolute=False)
if __name__ == "__main__":
    main()