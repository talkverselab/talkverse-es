#!/usr/bin/python3
"""Grok 답이 3분 안에 끝나지 않으면 생성을 멈춘다(사용자 지시 2026-11-10 "그록 3분만, 넘어가면 대화방 중지 — 토큰 낭비").
  grok_stop.py <url조각>   → 중지 단추(응답 중지·중지·Stop) 클릭, 없으면 Escape. 출력: STOPPED <방법>"""
import os, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9239')
c = g.CDP(g.tab(sys.argv[1]))
hit = c.ev("""(()=>{const b=[...document.querySelectorAll('button')].find(e=>/중지|stop/i.test((e.getAttribute('aria-label')||'')+' '+e.innerText));if(b){b.click();return b.getAttribute('aria-label')||b.innerText}return ''})()""")
if not hit:
    for typ in ('keyDown', 'keyUp'):
        c.call('Input.dispatchKeyEvent', type=typ, key='Escape', code='Escape', windowsVirtualKeyCode=27, nativeVirtualKeyCode=27)
time.sleep(2)
print('STOPPED', hit or 'escape')
