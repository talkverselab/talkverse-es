#!/usr/bin/python3
"""방 만들기(그림·글 공용). 기본 = 그림 방. 글 방: art_room.py --text  (모델 「전문가」, 첨부 없음, 규칙 data/review/grok/rules_es.md(+amend2), 방 id → room.txt)
그림 방 만들기: 새 탭(모델 「빠른」 — 전문가는 그림을 대화에 안 붙임) → 인물 기준 그림·화면 톤 첨부 + 그림 규칙(data/review/grok/art_rules_es.md) → 방 id 를 data/review/grok/room_art.txt 에."""
import json, os, subprocess, sys, time, urllib.request
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9239')
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TEXT = '--text' in sys.argv
ATT = [] if TEXT else [f'{R}/data/review/art/chars_es_v1.jpg', f'{R}/data/review/uxui/sian_es_01.jpg']
MODEL = '전문가' if TEXT else '빠른'
RULES = (open(f'{R}/data/review/grok/rules_es.md', encoding='utf-8').read() + '\n\n' + open(f'{R}/data/review/grok/rules_es_amend2.md', encoding='utf-8').read().split('이 메시지에는')[0].replace('[ES-규칙 수정 2] 바로 앞 수정을 고칩니다(사용자 정정). ', '추가: ')) if TEXT else open(f'{R}/data/review/grok/art_rules_es.md', encoding='utf-8').read()
ROOMF = 'room.txt' if TEXT else 'room_art.txt'
t = json.load(urllib.request.urlopen(urllib.request.Request(g.BASE + '/json/new?https://grok.com/', method='PUT')))
urllib.request.urlopen(g.BASE + '/json/activate/' + t['id']); time.sleep(10)
c = g.CDP(t)
c.call('Emulation.setFocusEmulationEnabled', enabled=True)
def click(x, y):
    for typ in ('mouseMoved', 'mousePressed', 'mouseReleased'):
        c.call('Input.dispatchMouseEvent', type=typ, x=x, y=y, button='left', clickCount=1, buttons=1)
lab = c.ev("document.getElementById('model-select-trigger').getAttribute('aria-label')")
if MODEL not in lab:
    r = json.loads(c.ev("JSON.stringify(document.getElementById('model-select-trigger').getBoundingClientRect())")); click(r['x'] + r['width'] / 2, r['y'] + r['height'] / 2); time.sleep(2)
    p = c.ev("(()=>{const e=[...document.querySelectorAll('[role=menu] span')].find(e=>e.textContent.trim()==='"+MODEL+"');if(!e)return null;const b=e.getBoundingClientRect();return JSON.stringify({x:b.x+b.width/2,y:b.y+b.height/2})})()")
    if p: p = json.loads(p); click(p['x'], p['y']); time.sleep(2)
print('model', c.ev("document.getElementById('model-select-trigger').getAttribute('aria-label')"))
if ATT:
    subprocess.run(['ssh', 'macmini4', 'mkdir -p /tmp/grok_att/es'], check=True)
    subprocess.run(['scp', '-q', *ATT, 'macmini4:/tmp/grok_att/es/'], check=True)
    doc = c.call('DOM.getDocument', depth=1); q = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
    c.call('DOM.setFileInputFiles', nodeId=q['nodeId'], files=['/tmp/grok_att/es/' + os.path.basename(x) for x in ATT]); time.sleep(8)
c.ev("document.querySelector('.ProseMirror').focus()")
c.call('Input.insertText', text=RULES); time.sleep(1)
c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>['제출','보내기'].includes(e.getAttribute('aria-label')||''));if(b)b.click()})()")
for _ in range(30):
    time.sleep(4)
    u = c.ev("location.href")
    if '/c/' in u:
        rid = u.split('/c/')[1].split('?')[0]; open(f'{R}/data/review/grok/{ROOMF}', 'w').write(rid + '\n'); print('ROOM', rid); break
time.sleep(30)
print(c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText).slice(-1)[0]"))
