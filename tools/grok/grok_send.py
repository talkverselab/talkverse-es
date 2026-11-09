#!/usr/bin/python3
"""Grok 프로젝트 챗에 프롬프트 파일을 보내고 답을 기다려 저장한다. 한도 문구가 뜨면 LIMIT 줄을 출력(세션이 CronCreate 로 재개).
  /usr/bin/python3 tools/grok_send.py <프롬프트파일> <저장파일> --tab <대화 id 조각> [--wait 300] [--attach a.png,b.png]
출력 마지막 줄: OK <저장파일> | LIMIT <HH:MM 또는 ?> <문구> | TIMEOUT | NOINPUT
"""
import re, sys, time
import os
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9239')  # 스페인어앱 전용 Chrome — M4 ~/chrome-grok-es(9239), M6 에서는 ssh -fN -L 9239:127.0.0.1:9239 macmini4ni4 터널로(2026-11-03)

a = sys.argv[1:]
src, dst = a[0], a[1]
frag = a[a.index('--tab') + 1] if '--tab' in a else sys.exit('--tab project/<id> 필수 (스페인어 방만)')
wait = int(a[a.index('--wait') + 1]) if '--wait' in a else 300
model = a[a.index('--model') + 1] if '--model' in a else '전문가'  # 그림은 「빠른」(전문가는 그림을 대화에 안 붙임, 인니어앱 2026-11-03)
attach = [x for x in a[a.index('--attach') + 1].split(',') if x] if '--attach' in a else []  # 첨부 파일(쉼표 구분, 절대경로) — input[type=file] 에 DOM.setFileInputFiles
LIMIT_RE = re.compile(r'(한도|limit|제한|rate|너무 많|사용량|초기화|다시 시도|try again|upgrade|SuperGrok)', re.I)
TIME_RE = re.compile(r'(\d{1,2}):(\d{2})')


def answers(c):
    els = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText)")
    return els


c = g.CDP(g.tab(frag)); c.call('Page.bringToFront')


def ensure_model(c, name):
    """모델을 name 으로(기본 「전문가」 — 사용자 지시 2026-11-03). 창이 뒤에 있으면 메뉴가 안 열려 포커스 에뮬레이션을 켠다."""
    import json as _j
    lab = c.ev("(document.getElementById('model-select-trigger')||{getAttribute:()=>''}).getAttribute('aria-label')") or ''
    if name in lab or not lab:
        return
    c.call('Emulation.setFocusEmulationEnabled', enabled=True)
    try:  # 창이 뒤에 있으면(visibility hidden) 메뉴가 안 열린다 — 탭을 활성화(2026-11-09 스페인어앱)
        import urllib.request as _u
        _id = next(x['id'] for x in g.tabs() if frag in x['url'])
        _u.urlopen(g.BASE + '/json/activate/' + _id, timeout=5)
    except Exception:
        pass
    def click(x, y):
        c.call('Input.dispatchMouseEvent', type='mouseMoved', x=x, y=y)
        for t in ('mousePressed', 'mouseReleased'):
            c.call('Input.dispatchMouseEvent', type=t, x=x, y=y, button='left', clickCount=1, buttons=1)
    r = _j.loads(c.ev("JSON.stringify(document.getElementById('model-select-trigger').getBoundingClientRect())"))
    click(r['x'] + r['width'] / 2, r['y'] + r['height'] / 2); time.sleep(2)
    pos = c.ev("(()=>{const e=[...document.querySelectorAll('[role=menuitem],[role=menuitemradio],[role=option]')].find(e=>e.innerText.trim().startsWith('"+name+"'))||[...document.querySelectorAll('[role=menu] span')].find(e=>e.textContent.trim()==='"+name+"');if(!e)return null;const b=e.getBoundingClientRect();return JSON.stringify({x:b.x+b.width/2,y:b.y+b.height/2})})()")
    if pos:
        p = _j.loads(pos); click(p['x'], p['y']); time.sleep(2)
    print('model:', c.ev("document.getElementById('model-select-trigger').getAttribute('aria-label')"))


ensure_model(c, model)
_els0 = answers(c); last_answer = _els0[-1] if _els0 else ''
text = open(src, encoding='utf-8').read().strip()
if c.ev("document.querySelector('.ProseMirror')") is None:
    print('NOINPUT'); sys.exit(2)
if attach:
    import os as _os
    doc = c.call('DOM.getDocument', depth=1)
    q = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
    files = [_os.path.abspath(x) for x in attach]
    remote = _os.environ.get('GROK_REMOTE', 'macmini4')  # 브라우저가 M4 에 있다(2026-11-03 사용자 지시) — 첨부는 M4 경로여야 한다
    if remote:
        import subprocess
        subprocess.run(['ssh', remote, 'mkdir -p /tmp/grok_att/es'], check=True)
        subprocess.run(['scp', '-q', *files, f'{remote}:/tmp/grok_att/es/'], check=True)
        files = ['/tmp/grok_att/es/' + _os.path.basename(x) for x in files]
    c.call('DOM.setFileInputFiles', nodeId=q['nodeId'], files=files); time.sleep(4 + 2 * len(attach))
    print('attached', len(attach))
c.ev("document.querySelector('.ProseMirror').focus()")
if c.ev("document.querySelector('.ProseMirror').innerText.trim().length") > 0:  # 앞 시도에서 남은 글 지우기
    c.call('Input.dispatchKeyEvent', type='keyDown', key='a', code='KeyA', modifiers=4, windowsVirtualKeyCode=65); c.call('Input.dispatchKeyEvent', type='keyUp', key='a', code='KeyA', modifiers=4, windowsVirtualKeyCode=65)
    c.call('Input.dispatchKeyEvent', type='keyDown', key='Backspace', code='Backspace', windowsVirtualKeyCode=8); c.call('Input.dispatchKeyEvent', type='keyUp', key='Backspace', code='Backspace', windowsVirtualKeyCode=8); time.sleep(1)
c.call('Input.insertText', text=text); time.sleep(1)
c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>['제출','보내기'].includes(e.getAttribute('aria-label')||''));if(b)b.click()})()")
time.sleep(3)
left = c.ev("document.querySelector('.ProseMirror').innerText.trim().length")
if left > 5:
    for typ in ('keyDown', 'keyUp'):
        c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
    time.sleep(3)
t0 = time.time(); reloaded = False
while time.time() - t0 < wait:
    body = c.ev("document.body.innerText")
    tail = body[-1500:]
    if LIMIT_RE.search(tail) and ('한도' in tail or 'limit' in tail.lower() or '초기화' in tail):
        m = TIME_RE.search(tail[tail.lower().find('한도') if '한도' in tail else 0:])
        print('LIMIT', m.group(0) if m else '?', '|', re.sub(r'\s+', ' ', tail[-300:]))
        sys.exit(3)
    busy = '작업 중' in body or c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    els = answers(c)
    if not busy and els and not els[-1].startswith('[J') and not els[-1].startswith('[G'):
        if len(els[-1]) > 150 and els[-1] != last_answer:
            open(dst, 'w', encoding='utf-8').write(els[-1]); print('OK', dst); sys.exit(0)
        if not reloaded and len(els[-1]) <= 150:
            c.call('Page.reload'); reloaded = True; time.sleep(9); c = g.CDP(g.tab(frag)); continue
    time.sleep(8)
print('TIMEOUT'); sys.exit(1)
