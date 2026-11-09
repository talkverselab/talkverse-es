#!/bin/zsh
# 사용: tools/grok/cuts_run.sh <편id>...   컷 요청문(data/review/art/<id>/cutN_req.md)마다 그림 1장(「빠른」 모델) → cutN.jpg. 그림 방 = data/review/grok/room_art.txt
cd ~/talkverse/es
curl -s -m 5 http://127.0.0.1:9239/json/version >/dev/null || ssh -fN -o ExitOnForwardFailure=yes -L 9239:127.0.0.1:9239 macmini4
ROOM=$(cut -c1-8 data/review/grok/room_art.txt)
# 첨부(인물 기준 그림·화면 톤)는 그림 방 첫 메시지에 한 번(tools/grok/art_room.py) — 컷마다 한 줄만(사용자 지시 2026-11-09)
for id in "$@"; do
  for req in $(ls data/review/art/$id/cut*_req.md | sort -V); do
    k=$(basename $req _req.md); [ -f data/review/art/$id/$k.jpg ] && continue
    out=$(GROK_CDP_PORT=9239 /usr/bin/python3 tools/grok/grok_image.py $req data/review/art/$id/$k.jpg --tab $ROOM --wait 900 2>&1 | tail -1)
    echo "$(date +%H:%M) $id $k $out"; rm -f data/review/art/$id/$k.jpg.md
    case "$out" in LIMIT*) exit 3;; esac
  done
done
