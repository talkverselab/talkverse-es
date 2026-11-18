#!/bin/zsh
# 사용자 지시 2026-11-18 「허용 진행」 — Claude 문장 14편(언어감각 L1~L10 + 옛 번호 4편)을 Grok 「빠른」으로 다시 쓰기. 편마다 새 방.
# uk 순서표 「es 시작」을 받은 뒤에만 실행. 사용: tools/grok/redo_20261118.sh [L1 ... r1_love_a1 ...]  (없으면 전부, 받은 편은 건너뜀)
cd ~/talkverse/es
curl -s -m 5 http://127.0.0.1:9239/json/version >/dev/null || ssh -fN -o ExitOnForwardFailure=yes -L 9239:127.0.0.1:9239 macmini4
ALL=(L1 L2 L3 L4 L5 L6 L7 L8 L9 L10 r1_love_a1 r2_life_b1 r3_friends_b1 r4_work_b1)
for id in ${@:-$ALL}; do
  if [[ $id == L* ]]; then
    pr=data/review/grok/sense/${id}_prompt.md; out=data/review/grok/sense/${id}_rewrite.md
    n=$(python3 -c "import json;d=json.load(open('assets/data/grammar/sense_course.json'));print(len(next(l for l in d['levels'] if l['id']=='$id')['lessons'][0]['sentences']))")
  else
    pr=data/review/grok/${id}_prompt.md; out=data/review/grok/${id}_rewrite.md
    n=$(python3 -c "import json,glob;print(len(json.load(open(glob.glob('assets/data/dialogues/R*/*/$id.json')[0]))['turns']))")
  fi
  [ -s $out ] && [ $(grep -cE '^\**[0-9]+\**\s+[^:]+:' $out) -ge $n ] && { echo "$id 이미 받음"; continue; }
  res=$(GROK_CDP_PORT=9239 /usr/bin/python3 tools/grok/room_send.py $pr $out $n --model 빠른 --wait 180 2>/dev/null | tail -1)
  echo "$(date +%H:%M) $id $res"
  case "$res" in LIMIT*|NOINPUT*|NOMODEL*) exit 3;; esac
done
