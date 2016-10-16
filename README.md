# portknock

Simple utility for port knocking written in Node.js

If you find it useful but you think it lacks some functionality please let me know by creating an issue. Thank you! 

## Installation

```bash
$ npm install -g portknock
$ (cd /usr/local/bin ; ln -sf ../lib/node_modules/portknock/portknock.js portknock)
```

## Basic usage

`portknock your.server.com 1234 8521 4785`

## Options

`portknock --help` will tell you everything you need. Here is the output to save you a few seconds:

```
Usage: portknock [-h] [-t TIMEOUT] [-d DELAY] [-u] host port [port ...]

positional arguments:
  host                  Hostname or IP address of the host to knock on.
                        Supports IPv6.
  port                  Port(s) to knock on.

optional arguments:
  -h, --help            show this help message and exit
  -t TIMEOUT, --timeout TIMEOUT
                        How many milliseconds to wait on hanging connection.
                        Default is 200 ms.
  -d DELAY, --delay DELAY
                        How many milliseconds to wait between each knock.
                        Default is 200 ms.
  -u, --udp             Use UDP instead of TCP.

Simple port-knocking client written in Node.js. See more at
https://github.com/mhmeadows63/node-portknock
```

# Acknowledgements

This implementation is a heavy plagiarisation of the Python3 work by Gronger 
[here](https://github.com/grongor/knock), many thanks.