#!/usr/bin/env python3

import json
import os
import sys

current_module = json.load(sys.stdin)['current_module']

project_base_dir = current_module

while not os.path.exists(os.path.join(project_base_dir, '.git/config')):
    project_base_dir = os.path.dirname(project_base_dir)
    if project_base_dir == os.path.dirname(project_base_dir):
        raise Exception("Could not find git repo")

print(json.dumps({
    "project_base_dir": project_base_dir,
    "module_rel": os.path.relpath(current_module, project_base_dir),
}))
