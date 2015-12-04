#!/usr/bin/env python

with open('/proc/net/udp') as f:
    lines = f.readlines()
lines.pop(0) # remove the title
for line in lines:
    s = line.split()
    ip, port = s[1].split(':')
    n = [str(int(ip[i*2:i*2+2], 16)) for i in xrange(4)]
    n.reverse()
    ip = '.'.join(n)
    port = int(port, 16)
    drops = s[12]
    if drops != '0':
        print ':'.join([ip, str(port)]), drops
