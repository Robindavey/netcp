#!/usr/bin/env python3
from sys import argv
import sys
import re
import os
def writeIP(ip):
    if ip == None:
        return
    try:
        with open("allowedIP", "a") as file:
            file.write(ip + "\n")
        print(f"{ip} added to allowed Ip's")
        return
    except FileNotFoundError as e:
        print(e)
        return
def validate_args():
    if len(argv) < 2:
        print("Enter an IP to add")
        return
    
    ip = argv[1]
    ip_regex = r"\b(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\b"    
    if not re.match(ip_regex, ip):
        print("Enter a VALID Ip")
        return None
    return ip
if __name__ == "__main__":
    if os.geteuid() != 0:
        print("This script must be run with sudo")
        sys.exit(1)
    writeIP(validate_args())