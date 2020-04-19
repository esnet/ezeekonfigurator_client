#!/usr/bin/env python3

from jinja2 import Template
import os
import uuid

data = {
    'brokerd_port': os.environ.get("BROKERD_PORT", "47000"),
    'brokerd_address': os.environ.get("BROKERD_ADDRESS", "127.0.0.1"),
    'uuid': os.environ.get("UUID", uuid.uuid4()),
    'url': os.environ.get("URL", "http://localhost:8000"),
    }

with open("scripts/communication.zeek.j2", 'r') as f:
    template = Template(f.read())

with open("scripts/communication.zeek", 'w') as f:
    f.write(template.render(**data)

