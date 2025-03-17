#!/usr/bin/env python3

import json
import sys
import subprocess
import time
import socket

conn = json.loads(json.load(sys.stdin)["connection"])

user = conn['user']
host = conn['host']
port = conn['port']
private_key = conn['private_key']

ssh_command = ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=10", "-p", str(port)]

if private_key != None:
    ssh_command += ["-i", private_key]

ssh_command += [f"{user}@{host}"]

ssh_exec = lambda command: subprocess.check_output(" ".join(ssh_command + command), shell=True, text=True)

endtime = time.time() + 60 * 10

while time.time() < endtime:
    try:
        socket.create_connection((host, 6443), timeout=10).close()
        socket.create_connection((host, port), timeout=10).close()
        ssh_exec(["sudo", "systemctl", "is-active", "--quiet", "k3s"])
        print(json.dumps({
            "kubeconfig": ssh_exec(["sudo", "cat", "/etc/rancher/k3s/k3s.yaml"]).replace("https://127.0.0.1:6443", f"https://{host}:6443"),
            "k3sconfig": ssh_exec(["sudo", "cat", "/etc/rancher/k3s/config.yaml"]),
        }))
        exit(0)
    except Exception as e:
        print(e, file=sys.stderr)
        time.sleep(5)

print("error: timeout")
exit(1)
