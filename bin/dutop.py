#!/usr/bin/env python

import os
import sys
from stat import *

def disk_usage(filename, dev):
    size = 0
    st = os.lstat(filename)
    if st.st_mode & S_IFREG:
        size += st.st_blksize * st.st_blocks
    elif st.st_mode & S_IFDIR:
        size += st.st_blksize * st.st_blocks
        try:
            for f in os.listdir(filename):
                size += disk_usage(os.path.join(filename, f), dev)
        except Exception as ex:
            sys.stderr.write(str(ex) + "\n")
    return size

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
    if st.st_mode & S_IFREG:
        print "{} {}".format(st.st_blksize * st.st_blocks, path)
    else:
        files = []
        try:
            for f in os.listdir(path):
                f = os.path.join(path, f)
                files.append((f, disk_usage(f, st.st_dev)))
        except Exception as ex:
            sys.stderr.write(str(ex) + "\n")
        for f, s in sorted(files, key=lambda f:f[1], reverse=True):
            print "{} {}".format(pretty_size(s), f)

if __name__ == '__main__':
    main()
