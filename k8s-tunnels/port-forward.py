#!/usr/bin/env python3
import json
import os
import sys
import subprocess
import socket
import time
import random
import shutil

def map_process():
    processmap = {}
    process = subprocess.check_output(["ps", "xao", "pid,ppid,command"])
    for line in process.splitlines():
        parts = line.decode().split()
        processmap[parts[0]] = {
            'pid': parts[0],
            'ppid': parts[1],
            'command': parts[2:]
        }
    return processmap

def lookup_parrents(processmap):
    known_shells = ('bash', 'sh', 'zsh', 'fish', 'dash', 'ksh', 'csh', 'tcsh', 'zsh')
    known_shells_prefixes = tuple(f"/{s}" for s in known_shells)
    pid = str(os.getppid())
    terraform_pid = 0
    shell_pid = 0
    while True:
        pid = processmap[pid]['ppid']
        command = processmap[pid]['command']
        if int(pid) < 100:
            print("cant find pid", file=sys.stderr)
            break
        if command[0] == 'terraform' and "apply" in command:
            terraform_pid = pid
        elif command[0] in known_shells or command[0].endswith(known_shells_prefixes):
            shell_pid = pid
            break
    return {
        'terraform_pid': terraform_pid,
        'shell_pid': shell_pid,
    }

def find_free_port():
    random_port = random.randint(10000, 60000)
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('localhost', random_port))
        return random_port

stdinjson = json.load(sys.stdin)
module_dir = stdinjson['module_dir']
tmp_dir = stdinjson['tmp_dir']
forwards_str = stdinjson['forwards']
forwards = json.loads(forwards_str)
kubeconfig = stdinjson['kubeconfig']
instance_id = f"tf-port-forward-{stdinjson['instance_id']}"

cache_file = os.path.join(tmp_dir, "cache.json")
kubeconfig_file = os.path.join(tmp_dir, "kubeconfig.yaml")
forwards_config = os.path.join(tmp_dir, "forwards.json")

if os.path.exists(cache_file):
    print(json.dumps({"forwards": open(cache_file, "r").read()}))
    exit(0)

shell_pid = lookup_parrents(map_process())['shell_pid']

if shell_pid == 0:
    print("cant find shell pid", file=sys.stderr)
    exit(1)

forwards = { k: { **v, 'local_port': find_free_port() } for k, v in forwards.items() }
simpler_forwards = json.dumps({ k: v['local_port'] for k, v in forwards.items() })

def graceful_exit(e):
    print(e, file=sys.stderr)

    try: shutil.rmtree(tmp_dir)
    except Exception as e: print(e, file=sys.stderr)
    
    exit(1)

try:
    os.makedirs(tmp_dir, exist_ok=True)
    open(kubeconfig_file, "w").write(kubeconfig)
    open(forwards_config, "w").write(json.dumps(forwards))
    open(cache_file, "w").write(simpler_forwards)
except Exception as e:
    graceful_exit(e)


try:
    subprocess.run([
        "screen", "-dmS", instance_id, 
        "python3", os.path.join(module_dir, "port-forward-keeper.py"), tmp_dir, shell_pid
    ], env = os.environ)
except Exception as e:
    graceful_exit(e)

print(json.dumps({"forwards": simpler_forwards}))
