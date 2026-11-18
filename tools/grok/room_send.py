#!/usr/bin/python3
"""새 Grok 방 하나에 요청문 하나 → 답 저장 → 탭 닫기(언어감각·옛 회화 다시 쓰기, 2026-11-18).
  GROK_CDP_PORT=9239 /usr/bin/python3 tools/grok/room_send.py <요청문> <저장> <줄 수> [--model 빠른] [--wait 180]
- 방을 편마다 새로 연다(긴 방은 초안 베끼기·오판 TIMEOUT, uk 2026-11-18).
- 답은 3분까지만(사용자 지시 2026-11-10) — 넘으면 생성 중지. 중지 전에 방의 답을 한 번 더 읽어 저장(uk: TIMEOUT 오판 주의).
- 끝 판단: 번호 줄이 n 개 이상이고 답 길이가 25초 그대로. 출력: OK <방주소> | PARTIAL <줄 수> <방주소> | LIMIT <문구> | NOINPUT
- 방 주소는 data/review/grok/rooms_20261118.txt 에 남긴다."""
import json, os, re, sys, time, urllib.request
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9239')
a = sys.argv[1:]
src, dst, n = a[0], a[1], int(a[2])
model = a[a.index('--model') + 1] if '--model' in a else '빠른'
wait = int(a[a.index('--wait') + 1]) if '--wait' in a else 180
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIMIT_RE = re.compile(r'(한도에 도달|limit reached|rate limit|사용량 한도|SuperGrok|upgrade to)', re.I)
t = json.load(urllib.request.urlopen(urllib.request.Request(g.BASE + '/json/new?https://grok.com/', method='PUT')))
TID = t['id']
urllib.request.urlopen(g.BASE + '/json/activate/' + TID); time.sleep(10)
def cdp():
    return g.CDP(next(x for x in g.tabs() if x['id'] == TID))
def close():
    try: urllib.request.urlopen(g.BASE + '/json/close/' + TID, timeout=5)
    except Exception: pass
c = cdp(); c.call('Emulation.setFocusEmulationEnabled', enabled=True)
def click(x, y):
    c.call('Input.dispatchMouseEvent', type='mouseMoved', x=x, y=y)
    for typ in ('mousePressed', 'mouseReleased'):
        c.call('Input.dispatchMouseEvent', type=typ, x=x, y=y, button='left', clickCount=1, buttons=1)
lab = c.ev("(document.getElementById('model-select-trigger')||{getAttribute:()=>''}).getAttribute('aria-label')") or ''
if lab and model not in lab:
    r = json.loads(c.ev("JSON.stringify(document.getElementById('model-select-trigger').getBoundingClientRect())")); click(r['x'] + r['width'] / 2, r['y'] + r['height'] / 2); time.sleep(2)
    p = c.ev("(()=>{const e=[...document.querySelectorAll('[role=menuitem],[role=menuitemradio],[role=option]')].find(e=>e.innerText.trim().startsWith('"+model+"'))||[...document.querySelectorAll('[role=menu] span')].find(e=>e.textContent.trim()==='"+model+"');if(!e)return null;const b=e.getBoundingClientRect();return JSON.stringify({x:b.x+b.width/2,y:b.y+b.height/2})})()")
    if p: p = json.loads(p); click(p['x'], p['y']); time.sleep(2)
lab = c.ev("(document.getElementById('model-select-trigger')||{getAttribute:()=>''}).getAttribute('aria-label')") or ''
print('model:', lab, file=sys.stderr)
if model not in lab:
    close(); print('NOMODEL', lab); sys.exit(4)
if c.ev("document.querySelector('.ProseMirror')") is None:
    close(); print('NOINPUT'); sys.exit(2)
c.ev("document.querySelector('.ProseMirror').focus()")
c.call('Input.insertText', text=open(src, encoding='utf-8').read().strip()); time.sleep(1)
c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>['제출','보내기'].includes(e.getAttribute('aria-label')||''));if(b)b.click()})()")
time.sleep(5)
def read():
    els = cdp().ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText)") or []
    return els[-1] if els else ''
t0 = time.time(); last = ''; same_since = time.time(); txt = ''
while time.time() - t0 < wait:
    time.sleep(5); txt = read()
    if LIMIT_RE.search(txt) and len(re.findall(r'^\**\d+\**\s', txt, re.M)) < 2:
        url = cdp().ev('location.href'); close(); print('LIMIT', txt[:80].replace('\n', ' '), url); sys.exit(3)
    if txt != last: last, same_since = txt, time.time()
    k = len(re.findall(r'^\**\d+\**\s+[^:\n]+[:：]', txt, re.M))
    if k >= n and time.time() - same_since >= 25: break
url = cdp().ev('location.href')
k = len(re.findall(r'^\**\d+\**\s+[^:\n]+[:：]', txt, re.M))
if k < n:  # 3분 초과 — 중지 전에 방을 다시 읽는다(오판 주의)
    time.sleep(5); txt = read() or txt; k = len(re.findall(r'^\**\d+\**\s+[^:\n]+[:：]', txt, re.M))
    if k < n:
        cdp().ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>/중지|Stop/.test(e.getAttribute('aria-label')||''));if(b)b.click()})()")
open(dst, 'w', encoding='utf-8').write(txt)
open(f'{R}/data/review/grok/rooms_20261118.txt', 'a', encoding='utf-8').write(f'{os.path.basename(dst)}\t{url}\n')
close()
print(('OK' if k >= n else f'PARTIAL {k}'), url)
