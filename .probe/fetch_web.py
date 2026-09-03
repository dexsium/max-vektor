# -*- coding: utf-8 -*-
"""Рекурсивно тянет чанки веб-клиента MAX для разбора протокола авторизации.

Публично отдаваемый браузеру JS — тот же источник, что и декомпиляция APK
в docs/MEDIA_OPCODES.md, только доступнее.
"""
import re
import os
import collections
import urllib.request

BASE = 'https://web.max.ru'
HDRS = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0'}
SEP = chr(92)  # обратный слэш, чтобы не воевать с экранированием


def main():
    seen = set()
    queue = collections.deque()
    saved = 0

    with open('index.html', encoding='utf-8', errors='ignore') as fh:
        html = fh.read()
    for path in re.findall(r'href="(/_app/[^"]+[.]js)"', html):
        queue.append(path)

    os.makedirs('js', exist_ok=True)
    while queue and saved < 500:
        path = queue.popleft()
        if path in seen:
            continue
        seen.add(path)
        try:
            req = urllib.request.Request(BASE + path, headers=HDRS)
            body = urllib.request.urlopen(req, timeout=30).read()
            body = body.decode('utf-8', 'ignore')
        except Exception:
            continue
        name = path.split('/')[-1]
        with open(os.path.join('js', name), 'w', encoding='utf-8') as fh:
            fh.write(body)
        saved += 1
        for ref in re.findall(r'''["'](\.{1,2}/[A-Za-z0-9_.-]+[.]js)["']''', body):
            base_dir = os.path.dirname(path)
            norm = os.path.normpath(os.path.join(base_dir, ref))
            norm = norm.replace(SEP, '/')
            if norm.startswith('/_app') and norm not in seen:
                queue.append(norm)

    print('скачано чанков:', saved)


if __name__ == '__main__':
    main()
