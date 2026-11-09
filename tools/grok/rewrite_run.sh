#!/bin/zsh
# 사용: tools/grok/rewrite_run.sh <편.json>...   한 방(data/review/grok/room.txt)에서 편마다 Grok(전문가) 재작성 → data/review/grok/<id>_rewrite.md
# M4 Chrome 9239(~/chrome-grok-es) 터널 필요. 한도 문구가 나오면 멈춘다. 이미 받은 편은 건너뛴다.
cd ~/talkverse/es
curl -s -m 5 http://127.0.0.1:9239/json/version >/dev/null || ssh -fN -o ExitOnForwardFailure=yes -L 9239:127.0.0.1:9239 macmini4
ROOM=$(cut -c1-8 data/review/grok/room.txt)
for f in "$@"; do
  id=$(basename $f .json); out=data/review/grok/${id}_rewrite.md
  n=$(python3 -c "import json;print(len(json.load(open('$f',encoding='utf-8'))['turns']))")
  [ -s $out ] && [ $(grep -cE '^[0-9]+ [A-D]:' $out) -ge $n ] && continue
  python3 tools/grok/rewrite_request.py $f >/dev/null
  res=$(GROK_CDP_PORT=9239 /usr/bin/python3 tools/grok/grok_send.py data/review/grok/${id}_prompt.md $out --tab $ROOM --wait 120 2>&1 | tail -1)
  case "$res" in LIMIT*) echo "$id 한도: $res"; rm -f $out; exit 3;; NOINPUT*) echo "$id 입력창 없음"; exit 2;; esac
  w=$(GROK_CDP_PORT=9239 /usr/bin/python3 tools/grok/wait_answer.py $ROOM $out $n 900)
  echo "$(date +%H:%M) $id $w $(grep -cE '^[0-9]+ [A-D]:' $out)/$n"
done
