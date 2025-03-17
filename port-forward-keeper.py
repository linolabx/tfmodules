#!/usr/bin/env python3
import json
import os
import sys
import time
import subprocess
import shutil
import signal

tmp_dir = sys.argv[1]
shell_pid = int(sys.argv[2])

kubeconfig_file = os.path.join(tmp_dir, "kubeconfig.yaml")
forwards_config = os.path.join(tmp_dir, "forwards.json")
cache_file = os.path.join(tmp_dir, "cache.json")

forwards = json.loads(open(forwards_config, "r").read())

def forward(fw):
    return subprocess.Popen(
        [
            "kubectl", "port-forward",
            f"{fw['type']}/{fw['name']}",
            f"{fw['local_port']}:{fw['port']}"
        ], 
        env = { "KUBECONFIG": kubeconfig_file }
    )

forwards = { k: { **v, 'process': forward(v) } for k, v in forwards.items() }

def graceful_exit(*args):
    for _, f in forwards.items(): f['process'].kill()

    try: shutil.rmtree(tmp_dir)
    except Exception as e: print(e)

    exit(0)

signal.signal(signal.SIGINT, graceful_exit)
signal.signal(signal.SIGTERM, graceful_exit)

while True:
    for _, f in forwards.items():
        if f['process'].poll() is not None:
            print(f"port-forward {f['type']}/{f['name']} died, restarting")
            f['process'] = forward(f)

    if not os.path.isdir('/proc/{}'.format(shell_pid)): graceful_exit()
    if not os.path.exists(cache_file): graceful_exit()
    time.sleep(10)
