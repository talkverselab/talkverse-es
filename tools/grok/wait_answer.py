#!/usr/bin/python3
"""Grok 방의 마지막 답이 다 찰 때까지(번호 줄 n 개 + 「추천 표현」) 새로고침하며 기다려 저장.
  wait_answer.py <방 조각> <저장파일> <턴 수> [최대초=900]   출력: OK | PARTIAL <줄 수> | TIMEOUT"""
import os, re, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9239')
frag, dst, n = sys.argv[1], sys.argv[2], int(sys.argv[3]); limit = int(sys.argv[4]) if len(sys.argv) > 4 else 900
t0 = time.time(); best = ''
while time.time() - t0 < limit:
    time.sleep(25)
    c = g.CDP(g.tab(frag)); c.call('Page.reload'); time.sleep(12); c = g.CDP(g.tab(frag))
    busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    els = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText)") or []
    if not els:
        continue
    txt = els[-1]; k = len(re.findall(r'^\d+ [A-D]:', txt, re.M))
    if len(txt) > len(best): best = txt
    if k >= n and '추천' in txt and not busy:
        open(dst, 'w', encoding='utf-8').write(txt); print('OK'); sys.exit(0)
open(dst, 'w', encoding='utf-8').write(best)
print('PARTIAL', len(re.findall(r'^\d+ [A-D]:', best, re.M))); sys.exit(1)
