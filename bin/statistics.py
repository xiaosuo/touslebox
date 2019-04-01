#!/usr/bin/env python

import sys

def show_histogram(dps, num_slots):
    r = dps[-1] - dps[0]
    step = r / num_slots
    lower_bound = dps[0]
    upper_bound = lower_bound + step
    i = 0
    histo = [0]
    for dp in dps:
        if dp >= upper_bound:
            lower_bound = upper_bound
            upper_bound = lower_bound + step
            i += 1
            histo.append(0)
        histo[i] += 1
    max_num_dps = max(histo)
    lower_bound = dps[0]
    for h in histo:
        upper_bound = lower_bound + step
        print '#' * (60 * h / max_num_dps), '[{}, {})'.format(lower_bound, upper_bound)
        lower_bound = upper_bound

def main():
    dps = sorted([float(x) for x in sys.stdin])
    if len(dps) == 0:
        raise RuntimeError('no data points')
    min_dp = dps[0]
    max_dp = dps[-1]
    num_dps = len(dps)
    avg_dp = sum(dps) / num_dps
    p50 = dps[num_dps / 2]
    p90 = dps[num_dps * 9 / 10]
    p95 = dps[num_dps * 95 / 100]
    p99 = dps[num_dps * 99 / 100]
    show_histogram(dps, 10)
    print 'min:', min_dp
    print 'max:', max_dp
    print 'avg:', avg_dp
    print 'p50:', p50
    print 'p90:', p90
    print 'p95:', p95
    print 'p99:', p99

if __name__ == '__main__':
    main()
