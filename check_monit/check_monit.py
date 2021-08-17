#!/usr/bin/env python3

import sys
from optparse import OptionParser

import requests as r
from lxml import etree

NAGIOS_EXITCODES = {"OK": 0, "WARNING": 1, "CRITICAL": 2, "UNKNOWN": 3}


def nagios_output(status, status_text):
    print(f"{status}: {status_text}")
    sys.exit(NAGIOS_EXITCODES[status])


def main():
    parser = OptionParser()
    parser.add_option(
        "-H",
        "--host",
        dest="host",
        help="IP address or hostname of monit instance.",
        metavar="HOST",
    )
    parser.add_option(
        "-p",
        "--port",
        dest="port",
        help="Port where monit instance is running. Defaults to 2812.",
        metavar="PORT",
        default=2812,
    )
    parser.add_option(
        "-U",
        "--username",
        dest="username",
        help="User name for monit HTTP interface.",
        metavar="USERNAME",
    )
    parser.add_option(
        "-P",
        "--password",
        dest="password",
        help="Password for monit HTTP interface.",
        metavar="PASSWORD",
    )
    (options, args) = parser.parse_args()

    if not options.host:
        parser.error("Host IP or hostname is required")
    if not options.username:
        parser.error("Username is required")
    if not options.password:
        parser.error("Password is required")

    status = "UNKNOWN"
    status_text = "Unknown result"

    auth = r.auth.HTTPBasicAuth(options.username, options.password)
    url = f"http://{options.host}:{options.port}/_status"

    try:
        monit_raw_xml = r.get(url, auth=auth, params={"format": "xml"})
    except r.exceptions.ConnectionError:
        nagios_output(status, f"Connection error to {url}")

    if monit_raw_xml.status_code != r.codes.ok:
        nagios_output(
            status, f"Got HTTP Response Code {monit_raw_xml.status_code} from {url}"
        )

    monit_tree = etree.XML(monit_raw_xml.content)

    monit_services = monit_tree.findall("service[@type='3']")

    monitored_services = []
    unmonitored_services = []

    ok_services = []
    nok_services = []

    monitored_services_count = 0
    unmonitored_services_count = 0

    ok_services_count = 0
    nok_services_count = 0

    for s in monit_services:
        service_name = s.find("name").text
        service_status = int(s.find("status").text)
        monitor_status = int(s.find("monitor").text)

        if service_status != 0:
            nok_services.append(service_name)
            nok_services_count += 1
        elif monitor_status == 1:
            ok_services.append(service_name)
            ok_services_count += 1

        if monitor_status != 1:
            unmonitored_services.append(service_name)
            unmonitored_services_count += 1
        else:
            monitored_services.append(service_name)
            monitored_services_count += 1

    status_text = (
        f"{ok_services_count}/{monitored_services_count} monitored services are OK."
    )

    if nok_services_count > 0:
        status = "CRITICAL"
        status_text += (
            f' {nok_services_count} services NOT OK: {",".join(nok_services)}.'
        )
    elif unmonitored_services_count > 0:
        status = "WARNING"
        status_text += f' {unmonitored_services_count} services UNMONITORED: {",".join(unmonitored_services)}.'
    else:
        status = "OK"

    nagios_output(status, status_text)


if __name__ == "__main__":
    main()
