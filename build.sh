#!/bin/bash

set -e

BIND_PORT=$1
URL=$2
PYTHON=$3

$PYTHON -m venv scripts/venv
source scripts/venv/bin/activate
pip install --upgrade pip
pip install .

chmod +x brokerd/build.py brokerd/run_brokerd.py brokerd/test.py

brokerd/test.py

BROKERD_PORT=$BIND_PORT URL=$URL brokerd/build.py


