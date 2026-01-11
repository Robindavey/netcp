# FileTransfer-er (netcp)

Simple HTTP-based file transfer toolset: a sender/CLI (`netcp`) and a small receiver HTTP server (`receiverServer.py`).

Overview
- `netcp.py`: CLI sender that streams files to the receiver with a progress bar.
- `receiverServer.py`: lightweight HTTP server that accepts uploads and saves them to the filesystem.

Features
- Send single files or directories recursively.
- Two destination modes:
  - `-d <dest>`: destination is relative (stored under the default bucket on the receiver).
  - `-D <path>`: destination is absolute on the receiver (use with care). The client sends `abs=1` so the server will accept an absolute path.

Security notes
- By default the receiver writes into a `netcp_bucket` directory under `~/Desktop/Programs` for non-absolute uploads.
- Absolute writes are allowed only when the client sets the `-D` flag. The receiver blocks writes to common banned directories like `.git`, `venv`, and `__pycache__`.
- Running the receiver as a service with permission to write arbitrary absolute paths is a security decision — review and restrict access appropriately.

Quick start (developer / single-machine)
1. Create and activate a virtualenv (optional but recommended):
```bash
python3 -m venv venv2
source venv2/bin/activate
pip install -r requeire.txt
```
2. Run receiver locally for quick testing:
```bash
python3 receiverServer.py
# server listens on 0.0.0.0:9100 by default
```
3. Send a file from another machine or same host:
```bash
# send to relative destination stored under default bucket on the receiver
./netcp -f /path/to/file -h <RECEIVER_IP> -d CopyofFt

# send to an absolute path on the receiver (receiver must be trusted):
./netcp -f /path/to/file -h <RECEIVER_IP> -D /full/target/path/filename.txt
```

Installing `netcp` client to `~/bin` or `/usr/local/bin`
1. Make the script executable:
```bash
chmod +x netcp.py
```
2. Install to your `~/bin` (recommended for single user):
```bash
mkdir -p ~/bin
cp netcp.py ~/bin/netcp
# ensure ~/bin is in your PATH
```
3. Or install system-wide (needs root):
```bash
sudo cp netcp.py /usr/local/bin/netcp
sudo chmod +x /usr/local/bin/netcp
```

Running the receiver as a systemd user service (recommended setup)
1. Copy the service file template into your user systemd directory:
```bash
mkdir -p ~/.config/systemd/user
cp packaging/FileTransfer-er-receiver.service ~/.config/systemd/user/FileTransfer-er-receiver.service
# Edit the unit file to point `ExecStart` at your Python executable and the full path to `receiverServer.py`.
systemctl --user daemon-reload
systemctl --user enable --now FileTransfer-er-receiver
journalctl --user -u FileTransfer-er-receiver -f
```

What the service should do
- Start `receiverServer.py` on boot for your user and keep it running.
- If you prefer running system-wide (system service), convert the unit to a system-level unit and install under `/etc/systemd/system/` (requires root). Review permissions before doing this.

Troubleshooting
- If the service fails with "Address already in use" the port (default 9100) is bound by another process. Either stop that process or change `PORT` in `receiverServer.py` and the client.
- If uploads return HTTP 403, check whether you used `-D` for absolute destinations (client) and whether the server's banned directories prevented the write.

Developer notes
- `requeire.txt` lists runtime dependencies (requests, tqdm). Install into the same Python interpreter used to run `netcp`/`receiverServer.py`.
- Adjust `BANNED_DIRS` and `DEFAULT_BUCKET` in `receiverServer.py` to match your environment and security policy.

License
- This repository has no license file. Add a LICENSE if you intend to publish the project.

Contact
- For questions about usage or to propose improvements, edit the README or open an issue in your source control system.


Set-up

# netcp

## Install

```bash
git clone https://github.com/yourorg/netcp.git
cd netcp
chmod +x setup.sh
./setup.sh




serverInstall

curl -fsSL https://raw.githubusercontent.com/Robindavey/netcp/main/install.sh | bash

which netcp
netcp --help
systemctl is-active recieverServer
journalctl -u recieverServer -n 20
