#!/usr/bin/env python3
"""Grok 재작성(data/review/grok/<id>_rewrite.md, 줄 = `n S: 스페인어 / 한국어 / 이유 / 감정 [/ F: 여성판]`)을 편 JSON 에 반영.
  python3 tools/grok/apply_rewrite.py <편id>...
- tl·ko·감정(emotion 또는 segs)·tl_f 를 바꾼다. 문장 속 이모지는 떼어 채팅 편이면 stamp 로, 아니면 버린다(음성이 읽지 않게).
- note·tags·new 는 옛 값을 두고 `note_stale: true` 표시 — 세션 리뷰에서 새 문장에 맞게 고친다. 초안은 draft_claude 칸에 보관.
- 끝나면 tools/check_dialogues.py --fix-rd 로 독음을 채운다."""
import glob, json, re, subprocess, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
ROOT = Path(__file__).resolve().parents[2]
import importlib.util as _iu
_s = _iu.spec_from_file_location('chk', str(Path(__file__).resolve().parents[1] / 'check_dialogues.py'))
STAMP = {}
for _ln in open(_s.origin, encoding='utf-8').read().split('STAMP = {', 1)[1].split('}\n', 1)[0].splitlines():
    for _k, _v in re.findall(r"'(.+?)': \{([^}]*)\}", _ln):
        STAMP[_k] = set(re.findall(r"'(\w+)'", _v))
EMOS = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
# Grok 이 16개 밖 감정을 쓸 때 가까운 값으로(2026-11-09)
MAP = {'curious': 'surprised', 'confident': 'cheerful', 'proud': 'excited', 'sleepy': 'sad', 'tired': 'sad', 'defensive': 'flustered',
       'smug': 'teasing', 'confused': 'worried', 'resigned': 'sad', 'happy': 'cheerful', 'nervous': 'stiff', 'embarrassed': 'flustered',
       'angry': 'annoyed', 'playful': 'teasing', 'relieved': 'gentle', 'hopeful': 'gentle', 'disappointed': 'sad', 'shocked': 'surprised'}
EMOJI = re.compile('[\U0001F000-\U0001FAFF☀-➿️‍]+')


def clean(s):
    s = EMOJI.sub('', s)
    return re.sub(r'\s+', ' ', s).strip()


for id_ in sys.argv[1:]:
    p = Path(glob.glob(str(ROOT / f'assets/data/dialogues/R*/*/{id_}.json'))[0])
    e = json.load(open(p, encoding='utf-8'))
    raw = (ROOT / f'data/review/grok/{id_}_rewrite.md').read_text(encoding='utf-8')
    rows = {}
    for ln in raw.splitlines():
        m = re.match(r'^(\d+) ([A-D]):\s*(.*)$', ln.strip())
        if m:
            rows[int(m.group(1))] = (m.group(2), [x.strip() for x in m.group(3).split(' / ')])
    if sorted(rows) != [t['num'] for t in e['turns']]:
        print(id_, '턴 번호가 안 맞음', sorted(rows)); continue
    if 'draft_claude' not in e:
        e['draft_claude'] = [{'tl': t['tl'], 'ko': t['ko']} for t in e['turns']]
    bad = []
    for t in e['turns']:
        sp, parts = rows[t['num']]
        if sp != t['speaker']:
            bad.append(f"{t['num']} 화자 {sp}≠{t['speaker']}")
        fem = next((x[2:].strip() for x in parts if x.startswith('F:')), None)
        parts = [x for x in parts if not x.startswith('F:')]
        tl, ko = parts[0], parts[1] if len(parts) > 1 else t['ko']
        if re.match(r'^[a-z]+:', tl) and tl.split(':', 1)[0] in EMOS:  # 본문 칸에 감정 조각을 넣은 답 → 글만 남기고 감정 칸으로
            emo_in_tl = tl
            tl = ' '.join(x.split(':', 1)[1].strip() for x in tl.split('|') if ':' in x)
        else:
            emo_in_tl = ''
        parts = parts[:3] + [re.sub(r'[a-z]+', lambda m: MAP.get(m.group(0), m.group(0)), x) for x in parts[3:]]
        emo = parts[3] if len(parts) > 3 else (parts[-1] if parts[-1].split(':')[0] in EMOS else '')
        if emo_in_tl and emo.split(':')[0] not in EMOS: emo = emo_in_tl
        em = EMOJI.findall(tl)
        if e.get('kind') == 'chat' and em:
            t['stamp'] = em[0][0]
        t['tl'], t['ko'] = clean(tl), clean(ko)
        for k in ('segs', 'emotion', 'tl_f', 'rd_f', 'ko_f'):
            t.pop(k, None)
        if '|' in emo or ':' in emo:
            segs = [[x.split(':', 1)[0].strip(), clean(x.split(':', 1)[1])] for x in emo.split('|') if ':' in x]
            if all(s[0] in EMOS for s in segs) and len(segs) > 1:
                t['segs'] = segs
            else:
                t['emotion'] = segs[0][0] if segs and segs[0][0] in EMOS else 'neutral'
        else:
            t['emotion'] = emo if emo in EMOS else 'neutral'
            if emo not in EMOS: bad.append(f"{t['num']} 감정 {emo!r}")
        st = t.get('stamp'); ems = [s[0] for s in t['segs']] if t.get('segs') else [t.get('emotion')]
        if st and STAMP.get(st) and not set(ems) & STAMP[st]:
            t.pop('stamp')  # 감정 열(음성)과 안 맞는 스탬프는 뺀다
        if fem and clean(fem) != t['tl']:
            t['tl_f'] = clean(fem)
        t['note_stale'] = True
    e['draft'] = 'grok'
    e['review'] = {'grok_rewrite': f'data/review/grok/{id_}_rewrite.md', 'model': '전문가'}
    p.write_text(json.dumps(e, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(id_, '반영', len(rows), '턴', '; '.join(bad))
subprocess.run([sys.executable, str(ROOT / 'tools/check_dialogues.py'), '--fix-rd', *[glob.glob(str(ROOT / f'assets/data/dialogues/R*/*/{i}.json'))[0] for i in sys.argv[1:]]])
