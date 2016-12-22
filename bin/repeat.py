#!/usr/bin/env python

import os
import sys
import argparse
import subprocess
import time

def main():
    ap = argparse.ArgumentParser(description='Repeat command NUMBER times')
    ap.add_argument('-n', '--number', type=int, default=10,
            help='Repeat <NUMBER> times, 10 by default')
    ap.add_argument('-d', '--delay', type=int, default=1,
            help='Delay <DELAY> seconds between executions, 1 by default')
    ap.add_argument('command', nargs=1, help='Command')
    ap.add_argument('argument', nargs='*', help='Command argument')
    args = ap.parse_args()
    cmd_args = args.command + args.argument

    for _ in xrange(args.number):
        rc = subprocess.call(cmd_args)
        if rc != 0:
            sys.exit(rc)
        time.sleep(args.delay)

if __name__ == '__main__':
    main()
