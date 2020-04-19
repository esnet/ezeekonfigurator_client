#!/bin/bash

/usr/bin/env python3 -m venv brokerd/venv
source brokerd/venv/bin/activate
pip install --upgrade pip
pip install ./brokerd

chmod +x brokerd/build.py brokerd/run_brokerd.py

deactivate

brokerd/build.py "$1" "$2"

zeek scripts/install
