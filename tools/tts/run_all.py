#!/usr/bin/env python3
"""전편 회화 음성 생성 진행기(스페인어, M6 에서 길게 돈다 — 한국어앱 run_all.py 와 같음, PC 출력 out/es). 묶음마다: 작업 파일 → PC 생성 → 받아 오기 → 받아쓰기 검사·재생성(두 번까지) → mp4·R2·D1.
  <venv>/bin/python tools/tts/run_all.py <작업폴더> [묶음 크기=12]     끝난 편은 <작업폴더>/done.txt 에 적히고 다시 돌리면 건너뛴다.
  TTS_TRIES=6 <venv>/bin/python tools/tts/run_all.py <작업폴더> --redo   끝난 편의 불합격 조각만 더 만든다(첫 생성·본 파일 받기를 건너뛰어 고른 판을 덮지 않음, 새로 합격한 편만 다시 묶음).
PC 쪽은 작업 스케줄러 'TTS job 2060'(run_job.sh)이 돈다 — 참고 음성 2060, 문장 3090. 중간에 멈춰도 있는 파일은 건너뛰고 이어서 한다."""
import glob, json, os, subprocess, sys, time
import ttslib as L
PC = 'Administrator@100.127.143.37'; HERE = os.path.dirname(os.path.abspath(__file__))
REDO = '--redo' in sys.argv; sys.argv = [a for a in sys.argv if a != '--redo']
work = sys.argv[1]; N = int(sys.argv[2]) if len(sys.argv) > 2 else 12
os.makedirs(f'{work}/job', exist_ok=True); os.makedirs(f'{work}/wav', exist_ok=True)
log = lambda *a: print(time.strftime('%H:%M:%S'), *a, flush=True)


def sh(*a, check=True, **k):
    return subprocess.run(a, check=check, capture_output=True, text=True, **k)


def pc_run():
    """작업 스케줄러를 돌리고 JOB_END 까지 기다린다."""
    while 'Ready' not in sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout:
        time.sleep(30)                     # 앞선 작업(참고 음성 등)이 끝날 때까지
    sh('scp', '-q', f'{work}/job/moss_jobs.json', f'{PC}:D:/tts_test/job/')
    sh('ssh', PC, "Remove-Item D:\\tts_test\\job\\vox_jobs.json -ErrorAction SilentlyContinue; Start-ScheduledTask -TaskName 'TTS job 2060'")
    time.sleep(20)
    while True:
        r = sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout
        if 'Ready' in r:
            return
        time.sleep(30)


def fetch(path):
    os.makedirs(os.path.dirname(f'{work}/wav/{path}'), exist_ok=True)
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/es/{path}', os.path.dirname(f'{work}/wav/{path}') + '/', check=False)


def bad_segs():
    """편 → 불합격 조각 집합(qa.json)."""
    r = {}
    for k, q in json.load(open(f'{work}/wav/qa.json', encoding='utf-8')).items():
        if not q.get('ok'):
            r.setdefault(k.split('/')[0], set()).add(k)
    return r


done = set(open(f'{work}/done.txt').read().split()) if os.path.exists(f'{work}/done.txt') else set()
before = bad_segs() if REDO else {}
ids = [e for e in L.planned() if (e in done and e in before if REDO else e not in done)]
log('남은 편', len(ids))
for i in range(0, len(ids), N):
    # 다른 세션이 3090 「비워 주세요」 → <작업폴더>/PAUSE 를 만들면 묶음 경계에서 멈춰 기다린다(지우면 이어감)
    if os.path.exists(f'{work}/PAUSE'):
        log('PAUSE — 묶음 경계에서 멈춤')
        while os.path.exists(f'{work}/PAUSE'):
            time.sleep(30)
        log('이어감')
    eps = ids[i:i + N]
    if not REDO:
        sh(sys.executable, f'{HERE}/make_jobs.py', f'{work}/job', *eps); pc_run()
        for ep in eps:
            fetch(ep)
    for rnd in range(3):
        # whisper 가 한 파일에서 멈추는 일이 있어(일본어 7시간) 편별 하위 프로세스 + 600초 제한. 넘기면 그 편 재생성본은 버리고 넘어간다.
        tot = 0
        for ep in eps:
            try:
                r = subprocess.run([sys.executable, f'{HERE}/qa.py', f'{work}/wav', ep, '--jobs', f'{work}/job/qa_{ep}.json'], capture_output=True, text=True, timeout=600)
                log(r.stdout.strip() or r.stderr.strip()[-200:])
            except subprocess.TimeoutExpired:
                log('TIMEOUT', ep)
                for f in glob.glob(f'{work}/wav/retake/{ep}/*.wav'):
                    os.remove(f)
        jobs = []
        for ep in eps:
            p = f'{work}/job/qa_{ep}.json'
            if os.path.exists(p):
                jobs += json.load(open(p)); os.remove(p)
        tot = len(jobs)
        if tot == 0:
            break
        json.dump(jobs, open(f'{work}/job/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        pc_run()
        for ep in eps:
            fetch(f'retake/{ep}')
    for ep in eps:   # 마지막(3회째) 재생성본 검사·반영 — 빠지면 받아만 두고 예전 판을 올린다(11-24)
        try:
            r = subprocess.run([sys.executable, f'{HERE}/qa.py', f'{work}/wav', ep], capture_output=True, text=True, timeout=600)
            log('마지막', r.stdout.strip() or r.stderr.strip()[-200:])
        except subprocess.TimeoutExpired:
            log('TIMEOUT', ep)
    after = bad_segs() if REDO else {}
    for ep in eps:
        if REDO and not before[ep] - after.get(ep, set()):
            log('그대로', ep, '불합격', len(before[ep])); continue
        r = sh(sys.executable, f'{HERE}/pack.py', f'{work}/wav', ep, '--upload', check=False)
        if r.returncode:
            log('실패', ep, (r.stderr or r.stdout)[-300:]); continue
        log(r.stdout.strip())
        if not REDO:
            open(f'{work}/done.txt', 'a').write(ep + '\n')
log('끝')
