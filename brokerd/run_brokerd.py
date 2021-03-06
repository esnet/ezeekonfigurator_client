#!/usr/bin/env python3

import asyncio
import datetime
import hashlib
import json
import logging
import os

import aiohttp
import broker
import requests
from aiohttp_sse_client import client as sse_client
from broker_json import from_json, to_json

debug = True
if debug:
    default_loglevel = "DEBUG"
else:
    default_loglevel = "INFO"

loglevel = os.environ.get("LOGLEVEL", default_loglevel)
logging.basicConfig(filename="run_brokerd.log", level=loglevel)
log = logging.getLogger(__name__)

batch_size = 0
client_version = "1"

topic = "/ezeekonfigurator/control"

bind_address = os.environ.get("BROKERD_BIND_ADDR", "")
bind_port = os.environ.get("BROKERD_BIND_PORT", None)
ez_url = os.environ.get("URL", "http://localhost:8000/")
asgi_url = os.environ.get("ASGI_URL", ez_url + "events/")

endpoint = subscriber = None


def dump_to_file(name, data):
    os.makedirs("brokerd_errors", exist_ok=True)

    filename = os.path.join("brokerd_errors", "%s.json" % name)
    try:
        json_data = json.dumps(data)
    except TypeError as e:
        json_data = str(e) + "\n" + str(data)
    with open(filename, 'w') as f:
        f.write(json_data)
    log.debug("Dumped %s to %s", name, filename)


def send_to_server(path, data):
    url = ez_url + "brokerd_api/v%s/%s/" % (client_version, path)
    log.debug("Sending %s", data)
    try:
        r = requests.post(url, json=data)
    except:
        if debug and data.get('options'):
            for o in data['options']:
                dump_to_file(o['name'], o['val'])
        return
    else:
        if r.status_code == 200:
            log.debug("Successfully sent POST to eZeeKonfigurator server")
        else:
            log.warning("Error sending POST to eZeeKonfigurator server: Got %d", r.status_code)
            if debug:
                name = hashlib.md5(str(data).encode('utf-8')).hexdigest()
                dump_to_file(name, data)


def setup():
    global endpoint, subscriber, port

    endpoint = broker.Endpoint()
    subscriber = endpoint.make_subscriber(topic)

    if not bind_port:
        port = endpoint.listen(bind_address, 0)
    else:
        port = int(bind_port)
        endpoint.listen(bind_address, port)

    log.info("Broker server started on TCP %d", port)


# noinspection PyUnresolvedReferences
async def broker_loop():
    while True:
        result = subscriber.get(1, 1)
        if not result:
            await asyncio.sleep(1)
            continue
        else:
            t, msg = result[0]
        log.info("Connected to Zeek server")

        uuid = t.rsplit("/", 1)[1]

        ev = broker.zeek.Event(msg)
        if ev.name() == "eZeeKonfigurator::sensor_info_reply":
            fqdn, cur_time, net_time, pid, is_live, is_traces, version = ev.args()[0]
            log.info("Received sensor_info_reply from %ls", fqdn)

            send_to_server("sensor_info", {'sensor_uuid': uuid, 'zeek_version': version, 'hostname': fqdn})

            endpoint.publish(topic + "/" + uuid,
                             broker.zeek.Event("eZeeKonfigurator::option_list_request", datetime.datetime.now()))

        elif ev.name() == "eZeeKonfigurator::option_list_reply":
            opt_list = []
            for option in ev.args()[0]:
                for var_name, var_data in option.items():
                    type_name, value, doc = var_data
                    opt_list.append({'name': var_name, 'type': type_name, 'doc': doc, 'val': to_json(value)})
                    if len(opt_list) > batch_size:
                        log.info("Sending %d options to eZeeKonfigurator server" % len(opt_list))
                        send_to_server("sensor_option", {'sensor_uuid': uuid, 'options': opt_list})
                        opt_list = []

            if opt_list:
                send_to_server("sensor_option", {'sensor_uuid': uuid, 'options': opt_list})

        elif ev.name() == "eZeeKonfigurator::heartbeat":
            send_to_server("sensor_hb", {'sensor_uuid': uuid})

        elif ev.name() == "eZeeKonfigurator::last_gasp":
            send_to_server("sensor_last_gasp", {'sensor_uuid': uuid, 'event': ev.args()[0]})

        else:
            log.info("Received unhandled event: %s", ev.name())


# noinspection PyUnresolvedReferences
async def server_loop():
    while True:
        async with sse_client.EventSource(asgi_url) as event_source:
            try:
                async for event in event_source:
                    if event.type == "stream-open":
                        log.info("Connected to eZeeKonfigurator ASGI")
                    elif event.type == "message" and event.data:
                        data = json.loads(event.data)
                        if data.get('type') == "change":
                            name = data['option']
                            uuid = data['uuid']
                            val = from_json(data['val'], data['zeek_type'])
                            endpoint.publish(topic + "/" + uuid,
                                             broker.zeek.Event("eZeeKonfigurator::option_change_request", name, val))
                            log.debug("Received change event from eZeeKonfigurator: %s", data)

            except (ConnectionError, aiohttp.ClientPayloadError, asyncio.TimeoutError):
                pass


async def main():
    setup()

    for f in asyncio.as_completed((server_loop(), broker_loop())):
        await f

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
    loop.close()
