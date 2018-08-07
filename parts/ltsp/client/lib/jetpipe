#!/usr/bin/python
#
# Minimal Printserver, forwards a printer device to a tcp port (usually 9100)
#
# TODO:
#   * add read for bidirectional comm ?
#   * add writeonly opts
#
# Copyright 2006, Canonical Ltd.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, you can find it on the World Wide
#  Web at http://www.gnu.org/copyleft/gpl.html, or write to the Free
#  Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
#Serial redirection code adapted from work by:
#(C)2002-2003 Chris Liechti <cliechti@gmx.net>
#redirect data from a TCP/IP connection to a serial port and vice versa
#requires Python 2.2 'cause socket.sendall is used
#

"""
usage: jetpipe [options] <device> <port>
Note: no security measures are implemeted. Anyone can remotely connect
to this service over the network.
Only one connection at once is supported. If the connection is terminaed
it waits for the next connect.
"""

import os
import sys
import socket
import serial
import getopt


class Redirector:
    def __init__(self, devicename, socket):
        self.socket = socket

        # This should catch regular serial and USB serial
        if devicename[:8] == '/dev/tty':
            self.device = serial.Serial(devicename)
            self.device.baudrate = 9600
            self.device.bytesize = 8
            self.device.parity = 'N'
            self.device.stopbits = 1
            # Required so that the reader thread can exit
            self.device.timeout = 1
            self.device.rtscts = False
            self.device.xonxoff = False
            self.devicetype = 'S'
        else:
            self.device = open(devicename, 'wb')
            self.devicetype = 'P'

    def shortcut(self):
        """connect the serial port to the tcp port by copying everything
           from one side to the other"""
        self.writer()

    def writer(self):
        """loop forever and copy socket->serial"""

        print 'in writer loop'
        self.alive = True

        while self.alive:
            try:
                data = self.socket.recv(1024)
                if not data:
                    break
                self.device.write(data)
            except socket.error, msg:
                print "error receiving from socket: ", msg

            try:
                if self.devicetype == 'P':
                    # parallel device
                    self.device.flush()
            except:
                pass
        self.device.close()
        self.alive = False


def run_server(devicename, port):
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.bind(('', int(port)))
    srv.listen(1)

    while 1:
        try:
            print "Waiting for connection...."
            connection, addr = srv.accept()
            print 'Connected by', addr
            #enter console->serial loop
            redir = Redirector(devicename, connection)
            if redir.devicetype == 'S':
                if 'baudrate' in locals():
                    redir.device.baudrate = baudrate
                if 'bytesize' in locals():
                    redir.device.bytesize = bytesize
                if 'parity' in locals():
                    redir.device.parity = parity
                if 'stopbits' in locals():
                    redir.device.stopbits = stopbits
                if 'rtscts' in locals():
                    redir.device.rtscts = rtscts
                if 'xonxoff' in locals():
                    redir.device.xonxoff = xonxoff
                try:
                    redir.device.open()
                except serial.SerialException, e:
                    print "Could not open serial port %s: %s" % (
                        devicename.port, e)
                    sys.exit(1)

            redir.shortcut()
            print 'Disconnected'
            connection.close()
        except socket.error, msg:
            print msg

if __name__ == '__main__':

    #parse command line options
    try:
        opts, args = getopt.getopt(sys.argv[1:],
                "dhb:p:rs:xy:",
                ["debug", "help", "baud=", "rtscts", "xonxoff"])
    except getopt.GetoptError:
        # print help information and exit:
        print >>sys.stderr, __doc__
        sys.exit(2)

    debug = False

    for o, a in opts:
        if o in ("-h", "--help"):         # help text
            sys.exit()
        elif o in ("-b", "--baud"):       # specified baudrate
            try:
                baudrate = int(a)
            except ValueError:
                raise ValueError("Baudrate must be a integer number")
        elif o in ("-y", "--bytesize"):   # specified bytesize
            bytesize = int(a)
        elif o in ("-p", "--parity"):     # specified parity
            parity = a
        elif o in ("-s", "--stopbits"):   # specified stopbits
            stopbits = int(a)
        elif o in ("-r", "--rtscts"):
            rtscts = True
        elif o in ("-x", "--xonxoff"):
            xonxoff = True
        elif o in ("-d", "--debug"):
            debug = True

    devicename = args[0]
    port = args[1]

    if not debug:
        # Fork in background
        pid = os.fork()
        if pid:
            sys.exit(0)

        # Replace stdin
        sys.stdin.close()
        sys.stdin = open("/dev/null", "r")

        # Replace stdout
        sys.stdout.close()
        sys.stdout = open("/dev/null", "w")

        # Replace stderr
        sys.stderr.close()
        sys.stderr = open("/dev/null", "w")

    run_server(devicename, port)
