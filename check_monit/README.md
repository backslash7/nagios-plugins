# check\_monit

Nagios plugin to monitor running Monit instance and report running/not running/not monitored services

## Requirements

 - Python 3.x
 - [Requests](https://docs.python-requests.org/en/master/)
 - [LXML](https://lxml.de/)

## Usage

### CLI

```
Usage: check_monit.py [options]

Options:
  -h, --help            show this help message and exit
  -H HOST, --host=HOST  IP address or hostname of monit instance.
  -p PORT, --port=PORT  Port where monit instance is running. Defaults to 2812.
  -U USERNAME, --username=USERNAME
                        User name for monit HTTP interface.
  -P PASSWORD, --password=PASSWORD
                        Password for monit HTTP interface.

```

For example:

```
./check_monit.py -H server1.example1 -p 2812 -U admin -P passw0rd
OK: 28/28 monitored services are OK.
```

### Nagios

Place the `check_monit.py` script file into your desired location with all 
other plugins.

Define the command:

```
define command {
    command_name    check_monit
    command_line    $USER1$/check_monit.py -H $HOSTADDRESS$ -P $_HOSTMONIT_PORT$ -U $_HOSTMONIT_USER$ -P $_HOSTMONIT_PASSWORD$
}
```

Specify required parameters in host definition:

```
define host {
    host_name       server1
    alias           Server 1
    address         192.168.1.1
    use             generic-host
    _monit_port     2812
    _monit_user     admin
    _monit_password passw0rd
}
```

Define service:

```
define service {
    host_name           server1
    service_description Monit services
    check_command       check_monit
    use                 generic-service
}
```

Season according to your taste and your Nagios deployment preferences.
