#!/usr/bin/env python

import os
import sys
import argparse
import stat
import atexit
import re
import glob

class IOReq(object):
    def __init__(self, comm, pid, start_time, nsec):
        self.comm = comm
        self.pid = pid
        self.insert = start_time
        self.issue = self.insert
        self.bytes_ = nsec * 512

def file_put_contents(path, content):
    with open(path, 'w') as fp:
        fp.write(content)

def cleanup():
    for event in ['complete', 'insert', 'issue']:
        file_put_contents('events/block/block_rq_{}/filter'.format(event), "0")
        file_put_contents('events/block/block_rq_{}/enable'.format(event), "0")
    file_put_contents('trace', "0")

def sprint_us(us):
    ms = us / 1000
    us = ms % 1000
    if ms >= 1000:
        s = "%d,%03d" % (ms / 1000, ms % 1000)
    else:
        s = str(ms)
    if us != 0:
        s += '.%03d' % us
    return s

def get_root_dev(major, minor):
    p = '/sys/dev/block/{}:{}'.format(major, minor)
    target = os.path.basename(os.readlink(p))
    if os.path.exists(os.path.join(p, 'partition')):
        res = glob.glob('/sys/class/block/*/{}'.format(target))
        if not res:
            raise RuntimeError("Can't find the root device of {}".format(target))
        target = os.path.basename(os.path.dirname(res[0]))
    st = os.stat('/dev/{}'.format(target))
    return os.major(st.st_rdev), os.minor(st.st_rdev)

def main():
    ap = argparse.ArgumentParser(description='Snoop the io operations')
    ap.add_argument('-d', '--device', required=True, help='The device or directory')
    ap.add_argument('--duration', type=int, help='Only show requests cost more than <duration>ms')
    args = ap.parse_args()
    if args.duration is not None:
        args.duration *= 1000
    st = os.stat(args.device)
    if stat.S_ISBLK(st.st_mode):
        major, minor = os.major(st.st_rdev), os.minor(st.st_rdev)
    else:
        major, minor = os.major(st.st_dev), os.minor(st.st_dev)

    major, minor = get_root_dev(major, minor)

    if os.geteuid() != 0:
        print >>sys.stderr, "You must be root to run this script"
        sys.exit(1)

    if not os.path.isdir('/sys/kernel/debug/tracing'):
        print >>sys.stderr, "debugfs isn't mount"
        sys.exit(1)

    os.chdir('/sys/kernel/debug/tracing')

    # construct the filter
    filter_ = "dev == {}".format((major << 20) | minor)

    atexit.register(cleanup)

    # enable events
    events = ['complete', 'insert', 'issue']
    for event in events:
        file_put_contents('events/block/block_rq_{}/filter'.format(event), filter_)
    for event in events:
        file_put_contents('events/block/block_rq_{}/enable'.format(event), "1")

    # determine the offset of timestamp
    with open('trace') as f:
        while True:
            line = f.readline()
            if not line.startswith('#'):
                print >>sys.stderr, 'Unknown header'
                sys.exit(1)
            slices = line.split()
            if len(slices) < 2:
                continue
            if slices[1].startswith('TASK'):
                if len(slices) == 6:
                    offset = 1
                else:
                    offset = 0
                break

    # run
    file_put_contents("trace", "1")

    lost_events_pat = re.compile('LOST.*EVENTS')

    # flight requests indexed by dev + loc
    flight_requests = {}

    # parse events
    abs_start_time = None
    with open('trace_pipe') as f:
        while True:
            line = f.readline()
            if line.startswith('#'):
                continue
            if lost_events_pat.search(line):
                print >>sys.stderr, line,
                continue
            slices = line.split()

            dash_pos = slices[0].rfind('-')
            comm = slices[0][:dash_pos]
            if comm == '<...>':
                comm = slices[-1]
            pid = int(slices[0][dash_pos + 1:])

            ts = slices[2 + offset][:-1]
            sec, usec = [int(x) for x in ts.split('.')]
            ts = sec * 1000000 + usec
            if abs_start_time is None:
                abs_start_time = ts
            ts -= abs_start_time
            func = slices[3 + offset][:-1]
            dev = slices[4 + offset]
            loc = slices[-4]
            index = dev + ':' + loc
            nsec = int(slices[-2])
            if func == 'block_rq_insert':
                flight_requests[index] = IOReq(comm, pid, ts, nsec)
            elif func == 'block_rq_issue':
                if index in flight_requests:
                    flight_requests[index].issue = ts
            elif func == 'block_rq_complete':
                dir_ = slices[5 + offset]
                if index in flight_requests:
                    req = flight_requests[index]
                    del flight_requests[index]
                    if args.duration is None or ts - req.insert > args.duration:
                        print '{} {} {} {} {} {} {} {} {} {} {} {}'.format(
                                sprint_us(req.insert), sprint_us(req.issue),
                                sprint_us(ts), sprint_us(ts - req.insert),
                                sprint_us(req.issue - req.insert),
                                sprint_us(ts - req.issue),
                                req.comm, req.pid, dir_, dev, loc, req.bytes_)
                        sys.stdout.flush()
            else:
                print >>sys.stderr, 'Saw dead people'
                sys.exit(1)

if __name__ == '__main__':
    main()
