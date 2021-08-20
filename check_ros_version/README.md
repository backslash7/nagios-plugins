# check\_ros\_version

Nagios plugin to monitor current running version of Mikrotik's RouterOS.

## Requirements

 - `snmpget`, usually included in `net-snmp` package. Check your package manager.

## Usage

### CLI

```
Usage: check_ros_version.sh [options]

Checks the RouterOS version running on the device.

Options:
  -h, --help                            Print this help and exit.
  -d, --debug                           Print debugging information.
  -H HOST, --host HOST                  IP address or hostname of the device
  -c COMMUNITY, --community COMMUNITY   SNMPv2 read community.
  -l VERSION, --latest VERSION          Latest RouterOS version.

```

For example:

```
./check_ros_version.sh -H 192.168.1.1 -c public -l 6.48.3
OK: Running latest version 6.48.3
```

### Nagios

Place the `check_ros_version.sh` script file into your desired location with all 
other plugins.

Define the command:

```
define command {
    command_name    check_ros_version
    command_line    $USER1$/check_ros_version.sh -H $HOSTADDRESS$ -c $_HOSTSNMP_COMMUNITY$ -l 6.48.3
}
```

Specify required parameters in host definition:

```
define host {
    host_name       router1
    alias           MikroTik router 1
    address         192.168.1.1
    use             generic-host
    _snmp_community public
}
```

Define service:

```
define service {
    host_name           router1
    service_description RouterOS version
    check_command       check_ros_version
    use                 generic-service
}
```

Season according to your taste and your Nagios deployment preferences. Possibly
define the latest version as a global macro, or fetch independently. You could
also define event handler to automatically connect to your router and schedule 
an RouterOS upgrade.
