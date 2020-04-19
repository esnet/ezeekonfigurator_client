#!/bin/bash

/usr/bin/env python3 -m venv scripts/venv
source scripts/venv/bin/activate
pip install --upgrade pip
pip install .

chmod +x brokerd/build.py brokerd/run_brokerd.py

deactivate

brokerd/build.py "$1" "$2"
