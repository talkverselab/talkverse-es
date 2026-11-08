#!/usr/bin/env python3
"""스페인어(카스티야) → 한글 독음. 표기표 = docs/DIALOGUE.md 「한글 독음 표기표」.
  from rd_es import rd   /   python3 tools/rd_es.py "¿Qué tal, Lucía?" """
import re, sys, unicodedata

CHO = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
JUNG = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ']
JONG = ' ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ'
V = {'a': 'ㅏ', 'e': 'ㅔ', 'i': 'ㅣ', 'o': 'ㅗ', 'u': 'ㅜ'}
Y = {'a': 'ㅑ', 'e': 'ㅖ', 'i': 'ㅣ', 'o': 'ㅛ', 'u': 'ㅠ'}  # ll·y·ñ 뒤
MAP = {'b': 'ㅂ', 'v': 'ㅂ', 'c': 'ㄲ', 'k': 'ㄲ', 'q': 'ㄲ', 'd': 'ㄷ', 'f': 'ㅍ', 'g': 'ㄱ', 'j': 'ㅎ', 'l': 'ㄹ', 'm': 'ㅁ', 'n': 'ㄴ',
       'p': 'ㅃ', 'r': 'ㄹ', 's': 'ㅅ', 't': 'ㄸ', 'z': 'ㅆ', 'w': 'ㅇ'}


def syl(c, v, j=' '):
    return chr(0xAC00 + (CHO.index(c) * 21 + JUNG.index(v)) * 28 + JONG.index(j))


def tokens(w):
    """낱말 → [(자음, 모음표, 모음)] 소리 단위. 모음 없는 자음은 v=None."""
    out, i, n = [], 0, len(w)
    vow = 'aeiou'
    while i < n:
        c = w[i]
        nx = w[i + 1] if i + 1 < n else ''
        if c in vow:
            out.append(('ㅇ', V, c)); i += 1; continue
        if c == 'h': i += 1; continue
        cons, table, step = None, V, 1
        if w.startswith('ch', i): cons, step = 'ㅊ', 2
        elif w.startswith('ll', i): cons, table, step = 'ㅇ', Y, 2
        elif w.startswith('rr', i): cons, step = 'ㄹ', 2
        elif w.startswith('qu', i) and i + 2 < n and w[i + 2] in 'ei': cons, step = 'ㄲ', 2
        elif w.startswith('gu', i) and i + 2 < n and w[i + 2] in 'ei': cons, step = 'ㄱ', 2
        elif c == 'ñ': cons, table = 'ㄴ', Y
        elif c == 'y':
            if nx and nx in vow: cons, table = 'ㅇ', Y
            else: out.append(('ㅇ', V, 'i')); i += 1; continue
        elif c == 'c' and nx in ('e', 'i') and nx: cons = 'ㅆ'
        elif c == 'g' and nx in ('e', 'i') and nx: cons = 'ㅎ'
        elif c == 'x':
            out.append(('ㄱ', None, None)); cons = 'ㅅ'
        elif c == 'g' and nx == 'ü' and i + 2 < n and w[i + 2] in vow:
            out.append(('ㄱ', V, 'u')); i += 2; continue
        elif c == 'ü': out.append(('ㅇ', V, 'u')); i += 1; continue
        else: cons = MAP.get(c)
        if cons is None: i += 1; continue
        i += step
        if i < n and w[i] in vow:
            out.append((cons, table, w[i])); i += 1
        else:
            out.append((cons, None, None))
    return out


EXC = {'pizza': '삐짜', 'pizzas': '삐짜스'}


def word(w):
    if w.lower() in EXC:
        return EXC[w.lower()]
    w = w.lower().replace('ñ', '\0')
    w = ''.join(ch for ch in unicodedata.normalize('NFD', w) if unicodedata.category(ch) != 'Mn' or ch == '̈')
    w = w.replace('ü', 'ü').replace('\0', 'ñ')
    ts = tokens(w)
    res = []  # [cho, jung, jong]
    for i, (c, t, v) in enumerate(ts):
        if t is not None:
            # 모음 사이 l → 앞 음절 받침 ㄹ + ㄹ (hola 올라)
            if c == 'ㄹ' and res and res[-1][2] == ' ' and i > 0 and ts[i - 1][1] is not None and w_has_l(w, ts, i):
                res[-1][2] = 'ㄹ'
            if c == 'ㄹ' and res and res[-1][1] == 'ㅡ' and res[-1][2] == ' ' and w_has_l(w, ts, i):
                res[-1][2] = 'ㄹ'
            res.append([c, t[v], ' '])
            continue
        if c == 'ㄱ' and res and res[-1][2] == ' ' and i + 1 < len(ts) and ts[i + 1][0] == 'ㅅ':  # x = 받침 ㄱ + ㅅ (extraño 엑스뜨라뇨)
            res[-1][2] = 'ㄱ'
            continue
        # 받침으로 쓰는 것: n·m·l (뒤가 자음이거나 낱말 끝)
        if res and res[-1][2] == ' ' and c in ('ㄴ', 'ㅁ', 'ㄹ') and is_coda(w, ts, i):
            res[-1][2] = {'ㄴ': 'ㄴ', 'ㅁ': 'ㄴ' if i == len(ts) - 1 else 'ㅁ', 'ㄹ': 'ㄹ'}[c]
            continue
        res.append([c, 'ㅡ', ' '])
    return ''.join(syl(*r) for r in res)


def is_coda(w, ts, i):
    c = ts[i][0]
    if c == 'ㄹ':  # r 받침은 「르」, l 받침만 ㄹ — 원문에서 몇 번째 자음인지 세기 어려워 낱말 안 r 여부로 가른다
        return _src(w, ts, i) == 'l'
    return True


def w_has_l(w, ts, i):
    return _src(w, ts, i) == 'l'


def _src(w, ts, i):
    """ts[i] 의 ㄹ 이 l 인지 r 인지 — 낱말에서 ㄹ 소리 순서로 찾는다."""
    k = sum(1 for t in ts[:i] if t[0] == 'ㄹ')
    letters = re.findall(r'rr|r|l(?!l)', re.sub(r'll', '', w))
    return letters[k][0] if k < len(letters) else 'r'


def rd(text):
    text = re.sub(r'[¡¿]', '', text)
    return re.sub(r"\{[a-z_]+\}|[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+", lambda m: m[0] if m[0].startswith('{') else word(m[0]), text)


if __name__ == '__main__':
    print(rd(' '.join(sys.argv[1:])))
