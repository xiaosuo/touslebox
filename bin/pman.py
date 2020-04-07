#!/usr/bin/env python

import os
import curses
import sys
import collections
import subprocess
import signal

Proc = collections.namedtuple('Proc', ['pid', 'command'])

def addline(scr, y, l, attr):
    l = l + ' ' * (curses.COLS - len(l))
    scr.addstr(y, 0, l, attr)

def may_elide(l):
    if len(l) > curses.COLS - 3:
        l = l[0:curses.COLS - 3]
        l += '...'
    return l

class ProcMan(object):
    def __init__(self, procs):
        super(ProcMan, self).__init__()
        self.procs = procs

    def run(self, stdscr):
        curses.curs_set(False)
        self.curr_index = 0
        self.view_off = 0
        stdscr.clear()
        addline(stdscr, 0, '  Process Manipulation ', curses.A_REVERSE)
        stdscr.addch(curses.LINES - 1, 2, 'q', curses.A_REVERSE)
        stdscr.addstr(curses.LINES - 1, 4, 'Quit')
        stdscr.addch(curses.LINES - 1, 10, 'k', curses.A_REVERSE)
        stdscr.addstr(curses.LINES - 1, 12, 'Kill')
        self.contents_win = curses.newwin(curses.LINES - 4, curses.COLS, 2, 0)
        self.redraw()
        stdscr.refresh()

        while True:
            self.contents_win.refresh()
            k = stdscr.getch()
            if k == ord('q'):
                break
            elif k == curses.KEY_UP:
                if self.curr_index > 0:
                    self.scroll_up()
            elif k == curses.KEY_DOWN:
                if self.curr_index + 1 < len(self.procs):
                    self.scroll_down()
            elif k == ord('k'):
                os.kill(int(self.procs[self.curr_index].pid), signal.SIGTERM)
                self.procs.pop(self.curr_index)
                if not self.procs:
                    break
                self.curr_index = 0
                self.view_off = 0
                self.redraw()
            else:
                pass

    def redraw(self):
        self.contents_win.clear()
        y = 0
        for i in range(self.view_off, len(self.procs)):
            attr = 0
            if i == self.curr_index:
                attr = curses.A_REVERSE
            if y >= self.contents_win.getmaxyx()[0]:
                break
            self.contents_win.addstr(y, 0, may_elide(self.procs[i].command), attr)
            y += 1

    def scroll_up(self):
        self.curr_index -= 1
        if self.curr_index < self.view_off:
            self.view_off -= 1
        self.redraw()

    def scroll_down(self):
        self.curr_index += 1
        if self.curr_index >= self.view_off + self.contents_win.getmaxyx()[0]:
            self.view_off += 1
        self.redraw()

def main():
    argv = ['pgrep'] + sys.argv[1:]
    output = subprocess.check_output(argv)
    procs = []
    for pid in output.split():
        procs.append(Proc(pid, subprocess.check_output(['ps', '-o', 'command', '-p', pid]).strip().split('\n')[-1]))
    if procs:
        proc_man = ProcMan(procs)
        curses.wrapper(proc_man.run)

if __name__ == '__main__':
    main()
