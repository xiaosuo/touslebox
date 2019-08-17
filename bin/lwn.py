#!/usr/bin/env python

import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import os
import requests
import re
import htmllib
import formatter
import time
import csv

BASE_URI = 'https://lwn.net'
LWN_URI = BASE_URI + '/Kernel/Index/'

class ArticleExtractor(htmllib.HTMLParser):
    def __init__(self, f):
        htmllib.HTMLParser.__init__(self, f)
        self.text = ''
        self.date = None
        self.href = None
        self.extract = False
        self.tags = []
        self.entries = [('date', 'title', 'href')]
        self.dedup_set = set()

    def handle_data(self, data):
        data = data.strip()
        if data and self.extract and self.tags:
            if self.tags[-1] == 'a':
                self.text += data
            else:
                self.date = time.strftime('%Y-%m-%d', time.strptime(data.strip(), '(%B %d, %Y)'))

    def start_p(self, attrs):
        attrs = dict(attrs)
        if attrs.get('class') == 'IndexEntry':
            self.extract = True
        self.tags.append('p')

    def end_p(self):
        if self.extract:
            dedup_text = self.date + self.text.strip() + self.href
            if dedup_text not in self.dedup_set:
                self.dedup_set.add(dedup_text)
                self.entries.append((self.date, self.text.strip(), BASE_URI + self.href))
            self.text = ''
            self.date = None
            self.href = None
            self.extract = False
        self.tags.pop()

    def start_a(self, attrs):
        if self.extract:
            attrs = dict(attrs)
            self.href = attrs.get('href')
        self.tags.append('a')

    def end_a(self):
        self.tags.pop()

    def dump(self):
        csv.writer(sys.stdout).writerows(self.entries)

def main():
    f = formatter.NullFormatter()
    p = ArticleExtractor(f)
    p.feed(requests.get(LWN_URI).text)
    p.close()
    p.dump()

if __name__ == '__main__':
    main()
