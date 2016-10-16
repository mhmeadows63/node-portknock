#! /usr/bin/env node-strict
var chain = require('scope-chain');
//var debug = exports.debug = require('debug-repl')(module);
var dgram = require('dgram');
var dns = require('dns');
var getopt = exports.getopt = require("node-getopt");
var ipaddr = exports.ipaddr = require('ipaddr.js');
var net = require('net');

var opts = exports.opts = getopt.create([
    ['h', 'help', 'show this help message and exit'],
    ['d', 'delay=ARG', 'milliseconds to wait between each knock (200ms)'],
    ['e', 'errors', 'display network errors'],
    ['t', 'timeout=ARG', 'milliseconds to wait on hanging connection (200ms)'],
    ['u', 'udp', 'use UDP instead of TCP'],
    ['4', '', 'limit to IPv4 only'],
    ['6', '', 'limit to IPv6 only'],
]).setHelp(
    "Usage: portknock [-h] [-d DELAY] [-e] [-t TIMEOUT] [-u] host port [port ...]\n" +
    "\n" +
    "[[OPTIONS]]\n" +
    "\n" +
    "Simple port-knocking client written in Node.js. See more at\n" +
    "    https://github.com/mhmeadows63/node-portknock\n"
).bindHelp();

var o = opts.parseSystem(), addr, proto = o.options.udp ? udp : tcp;

var error = o.options.errors ? console.error : Function.prototype;
!o.argv.length ? opts.showHelp() : chain(function cleanup(err) {
    udp.socket && udp.socket.close();
    exports.debug ? err && console.error(err.stack || err) : process.exit(!!err);
}, function () {
    try { addr = ipaddr.parse(o.argv[0]) } catch (ex) { } // attempt to parse hostname as an IP address
    if (addr || o.options['6']) return this(); // skip on if we have an address or only want IPv6
    dns.resolve4(o.argv[0], this.noerror);

}, function (err, addrs) {
    addr = addr || (addrs && addrs.length && ipaddr.parse(addrs[0])); // parse IPv4 address
    if (addr || o.options['4']) return this(); // skip on if we have an address or only want IPv4
    dns.resolve6(o.argv[0], this.noerror);

}, function (err, addrs) {
    addr = addr || (addrs && addrs.length && ipaddr.parse(addrs[0])); // parse IPv6 address
    if (!addr) console.error('cannot resolve hostname:', o.argv[0]); // report address failure
    this(null, o.argv.slice(1));

}, function callee(ports, err) {
    err && error(err.stack); // show errors from udp() or tcp()
    if (!addr || !ports.length) return this(); // skip on if no address or not more ports
    proto(addr, ports.shift(), o.options.timeout, o.options.delay, callee.bind(this, ports)); // action the each knock

});

function udp(addr, port, timeo, delay, next) {
    udp.socket = udp.socket || dgram.createSocket('udp' + addr.kind()[3]);
    chain(next, function () {
        udp.socket.send(Buffer(''), 0, 0, port, addr.toString(), this);

    }, function () {
        setTimeout(this, delay || 200);

    });
}

function tcp(addr, port, timeo, delay, next) {
    tcp.sockets = tcp.sockets || [];
    var timeout, socket;
    chain(next, function () {
        socket = net.connect(port, addr.toString(), this.noerror).on('error', this.noerror);
        timeout = setTimeout(this.noerror, timeo || 200);

    }, function (err) {
        socket.destroy();
        timeout = clearTimeout(timeout);
        setTimeout(this.bind(null, err), delay || 200);

    });
}
