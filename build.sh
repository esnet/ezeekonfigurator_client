#!/bin/bash

set -e

$2 -m venv scripts/venv
source scripts/venv/bin/activate
pip install --upgrade pip
pip install .

chmod +x brokerd/build.py brokerd/run_brokerd.py brokerd/test.py

brokerd/test.py

deactivate

BROKERD_PORT=$1 URL=$3 brokerd/build.py
