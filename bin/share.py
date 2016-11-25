#!/usr/bin/env python

import sys
import os
import socket
import argparse
from SimpleHTTPServer import SimpleHTTPRequestHandler
from BaseHTTPServer import HTTPServer

ap = argparse.ArgumentParser(description='Share path via HTTP')
ap.add_argument('path', default='.', help='The path to share', nargs='?')
args = ap.parse_args()
path = args.path

if os.path.isfile(path):
    dirname = os.path.dirname(path)
    if len(dirname) != 0:
        os.chdir(dirname)
    filename = os.path.basename(path)
elif os.path.isdir(path):
    os.chdir(path)
    filename = ''
else:
    print "Invalid file type: {}".format(path)
    sys.exit(1)

SimpleHTTPRequestHandler.protocol_version = "HTTP/1.0"
httpd = HTTPServer(('', 0), SimpleHTTPRequestHandler)
port = httpd.socket.getsockname()[1]
host = socket.gethostbyname(socket.gethostname())
print "Sharing {} via http://{}:{}/{}".format(path, host, port, filename)
print "Click the URI with Option and Command pressed to open it"
httpd.serve_forever()
