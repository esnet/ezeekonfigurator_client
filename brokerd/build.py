#!/usr/bin/env python3

import os
import uuid

from jinja2 import Template

data = {
    'brokerd_port': os.environ.get("BROKERD_PORT", "47000"),
    'brokerd_address': os.environ.get("BROKERD_ADDRESS", "127.0.0.1"),
    'uuid': os.environ.get("UUID", uuid.uuid4()),
    'url': os.environ.get("URL", "http://localhost:8000"),
}


def render(filename):
    with open("scripts/communication.zeek.j2", 'r') as f:
        template = Template(f.read())

    with open(filename, 'w') as f:
        f.write(template.render(**data))


if __name__ == "__main__":
    render("scripts/communication.zeek")
