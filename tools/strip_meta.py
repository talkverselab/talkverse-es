#!/usr/bin/env python3
"""회화 편 JSON 의 작업 기록 칸(draft·review·draft_claude)을 앱 묶음·서버 원고에서 빼고 data/review/meta/<편id>.json 에 옮긴다.
출처(AI 이름) 공개 금지 — uk 심사 점검 11-23 F. script_publish.py 가 올리기 전에 이 칸이 남아 있으면 멈춘다.
  python3 tools/strip_meta.py        # 옮기고 지움(이미 옮긴 칸은 meta 에 합침)"""
import glob
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
META = ROOT / 'data/review/meta'
KEYS = ('draft', 'review', 'draft_claude')
AI = re.compile(r'claude|grok|gemini|gpt|openai', re.I)


def main():
    META.mkdir(parents=True, exist_ok=True)
    n = 0
    for p in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R[0-5]/*/*.json'))):
        raw = Path(p).read_text(encoding='utf-8')
        d = json.loads(raw)
        got = {k: d.pop(k) for k in KEYS if k in d}
        # 턴 안의 작업 기록 칸(이름에 AI 이름이 든 것, 예 note_claude_old)도 옮긴다
        tm = {}
        for t in d.get('turns', []):
            x = {k: t.pop(k) for k in list(t) if AI.search(k)}
            if x:
                tm[str(t.get('num'))] = x
        if tm:
            got['turn_meta'] = tm
        if not got:
            continue
        mf = META / f"{d['id']}.json"
        old = json.loads(mf.read_text(encoding='utf-8')) if mf.exists() else {}
        mf.write_text(json.dumps({**old, **got}, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        indent = 1 if raw.startswith('{\n ') and not raw.startswith('{\n  ') else 2
        Path(p).write_text(json.dumps(d, ensure_ascii=False, indent=indent) + '\n', encoding='utf-8')
        n += 1
    print('옮김', n, '편 →', META.relative_to(ROOT))


if __name__ == '__main__':
    main()
