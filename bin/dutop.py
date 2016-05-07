#!/usr/bin/env python

import os
import sys
from stat import *

def disk_usage(filename, dev):
    total_size = 0
    st = os.lstat(filename)
    if st.st_dev == dev:
        if S_ISREG(st.st_mode):
            total_size += st.st_blksize * st.st_blocks
        elif S_ISDIR(st.st_mode):
            total_size += st.st_blksize * st.st_blocks
            try:
                for f in os.listdir(filename):
                    _, size = disk_usage(os.path.join(filename, f), dev)
                    total_size += size
            except Exception as ex:
                sys.stderr.write(str(ex) + "\n")
        else:
            filename = None
    else:
        filename = None
    return filename, total_size

def pretty_size(size):
    units = 'BKMGT'
    unit_index = 0
    size = float(size)
    while size >= 1000:
        size /= 1000
        unit_index += 1
    s = '{}'.format(size)[0:4]
    if s.endswith('.'):
        s = s[0:-1]
    return ' ' * (4 - len(s)) + s + units[unit_index]

def main():
    path = '.'
    if len(sys.argv) == 2:
        path = sys.argv[1]

    st = os.lstat(path)
    if S_ISREG(st.st_mode):
        print "{} {}".format(pretty_size(st.st_blksize * st.st_blocks), path)
    elif S_ISDIR(st.st_mode):
        files = []
        try:
            for f in os.listdir(path):
                f, size = disk_usage(os.path.join(path, f), st.st_dev)
                if f:
                    files.append((f, size))
        except Exception as ex:
            sys.stderr.write(str(ex) + "\n")
        for f, s in sorted(files, key=lambda f:f[1], reverse=True):
            print "{} {}".format(pretty_size(s), f)

if __name__ == '__main__':
    main()
