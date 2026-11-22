import 'dart:math';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../widgets/episode_play_pane.dart';

/// 토크버스 커리큘럼 — 기준 `~/talkverse/CURRICULUM_SPEC.md`(2026-11-22, 전 언어 같게).
/// 레벨 고르기 → 코스(다이얼로그 3·5·10편) → 편마다 연습 → 복습(1·3·7일) → 코스 시험 80% → 다음 코스·레벨.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

const _goalLabels = {1: '가볍게', 2: '보통', 3: '집중'};

class _CurriculumScreenState extends State<CurriculumScreen> {
  final _store = CurriculumStore.instance;
  bool _ready = false;
  bool _pickLevel = false;
  bool _confirmNew = false;
  int _size = 5;
  final Set<String> _sel = {};
  String? _banner;

  CurriculumState get s => _store.state;
  DialogueService get ds => DialogueService.instance;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ds.ensureLoaded();
    await _store.load();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _save() async {
    final now = DateTime.now();
    s.rollDay(now);
    s.touchStreak(now);
    await _store.save();
    if (mounted) setState(() {});
  }

  List<Dialogue> get _levelDs => s.level == null ? const [] : ds.list(region: s.level);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : (s.level == null || _pickLevel)
              ? _levelPicker()
              : _home(),
    );
  }

  // ── 레벨 고르기 ──
  Widget _levelPicker() {
    final regs = ds.regions;
    return ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)), children: [
      Text(tr('회화 레벨을 고르세요. 처음이면 가장 낮은 레벨부터 권해요.'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
      const SizedBox(height: 12),
      for (var i = 0; i < regs.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            key: ValueKey('cur-level-${regs[i]}'),
            style: _tileStyle(),
            onPressed: () async {
              if (s.level != regs[i]) {
                s.level = regs[i];
                s.course = null;
              }
              _pickLevel = false;
              _sel.clear();
              await _save();
            },
            child: Row(children: [
              SizedBox(width: 44, child: Text(regs[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ai))),
              Expanded(child: Text(tr(DialogueService.levelKo[regs[i]] ?? regs[i]), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              Text(_levelProgress(regs[i]), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              if (i == 0 && s.level == null) ...[const SizedBox(width: 8), _chip(tr('추천'))],
            ]),
          ),
        ),
    ]);
  }

  String _levelProgress(String r) {
    final l = ds.list(region: r);
    final p = l.where((d) => s.passedDialogues.contains(d.id)).length;
    return trf('{0}/{1}편 통과', [p, l.length]);
  }

  // ── 코스 홈 ──
  Widget _home() {
    final now = DateTime.now();
    s.rollDay(now);
    final due = s.dueReview(now);
    final c = s.course;
    final active = c != null && c.passedAt == null;
    return ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: [
      if (_banner != null)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0x2236A35B), borderRadius: BorderRadius.circular(12)),
          child: Text(_banner!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
        ),
      _todayCard(now, due.length),
      const SizedBox(height: 12),
      Row(children: [
        Text('${s.level} · ${tr(DialogueService.levelKo[s.level] ?? '')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.sumi)),
        const SizedBox(width: 8),
        Text(_levelProgress(s.level!), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const Spacer(),
        TextButton(key: const ValueKey('cur-change-level'), onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
      ]),
      const SizedBox(height: 6),
      if (active) ..._courseView(c) else ..._builder(),
    ]);
  }

  Widget _todayCard(DateTime now, int dueN) {
    final newLeft = s.newLeft();
    final total = s.dailyGoal + s.todayReview + dueN;
    final done = s.todayNew.clamp(0, s.dailyGoal) + s.todayReview;
    final finished = s.todayDone(now);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cal, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(finished ? tr('오늘 분량 끝') : trf('오늘: 복습 {0} · 새 편 {1}', [dueN, newLeft]),
                key: const ValueKey('cur-today'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.sumi)),
          ),
          if (s.streakCount > 0) Text(trf('🔥 {0}일 연속', [s.streakCount]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.beni)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: total == 0 ? 1 : (done / total).clamp(0.0, 1.0), minHeight: 8, backgroundColor: AppColors.line, color: AppColors.ai),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text(tr('하루 목표'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          const SizedBox(width: 8),
          for (final g in [1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: ValueKey('cur-goal-$g'),
                label: Text(trf('{0} · 새 편 {1}', [tr(_goalLabels[g]!), g]), style: const TextStyle(fontSize: 11.5)),
                selected: s.dailyGoal == g,
                onSelected: (_) {
                  s.dailyGoal = g;
                  _save();
                },
              ),
            ),
        ]),
        if (dueN > 0) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('cur-review'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(44)),
            onPressed: _startReview,
            icon: const Icon(Icons.replay, size: 18),
            label: Text(trf('복습 {0}줄 하기', [dueN])),
          ),
        ],
      ]),
    );
  }

  // ── 코스 만들기 ──
  List<Widget> _builder() {
    final level = _levelDs;
    final passed = s.passedDialogues.toSet();
    final last = s.course;
    return [
      if (last?.passedAt != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(tr('지난 코스 통과! 다음 코스를 고르세요.'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.matcha))),
      Text(tr('이번 코스에서 연습할 다이얼로그를 고르세요.'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
      const SizedBox(height: 8),
      Row(children: [
        Text(tr('개수'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(width: 8),
        for (final n in [3, 5, 10])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              key: ValueKey('cur-size-$n'),
              label: Text(trf('{0}편', [n])),
              selected: _size == n,
              onSelected: (_) => setState(() {
                _size = n;
                while (_sel.length > n) {
                  _sel.remove(_sel.last);
                }
              }),
            ),
          ),
        const Spacer(),
        TextButton(
          key: const ValueKey('cur-recommend'),
          onPressed: () => setState(() {
            final r = recommend(level, passed, _sel, _size);
            _sel
              ..clear()
              ..addAll(r);
          }),
          child: Text(tr('추천으로 채우기')),
        ),
      ]),
      for (final d in level)
        CheckboxListTile(
          key: ValueKey('cur-pick-${d.id}'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _sel.contains(d.id),
          onChanged: (v) => setState(() {
            if (v == true && _sel.length < _size) _sel.add(d.id);
            if (v != true) _sel.remove(d.id);
          }),
          title: Text('${d.emoji} ${d.title}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
          subtitle: Text('${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${trf('{0}줄', [d.turns.length])}${passed.contains(d.id) ? ' · ✓ ${tr('통과')}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ),
      const SizedBox(height: 8),
      FilledButton(
        key: const ValueKey('cur-start'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.ai, minimumSize: const Size.fromHeight(48)),
        onPressed: _sel.length == _size
            ? () async {
                s.course = Course('${s.level}-${DateTime.now().millisecondsSinceEpoch}', [for (final d in level) if (_sel.contains(d.id)) d.id]);
                _sel.clear();
                _banner = null;
                await _save();
              }
            : null,
        child: Text(trf('코스 시작 ({0}/{1})', [_sel.length, _size])),
      ),
    ];
  }

  // ── 진행 중 코스 ──
  List<Widget> _courseView(Course c) {
    final list = [for (final id in c.dialogueIds) ds.byId(id)].whereType<Dialogue>().toList();
    return [
      Text(trf('코스 {0}편 · 연습 {1}/{0}', [list.length, c.practiced.where(c.dialogueIds.contains).length]), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
      const SizedBox(height: 6),
      for (final d in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            key: ValueKey('cur-ep-${d.id}'),
            style: _tileStyle(),
            onPressed: () => _practice(d),
            child: Row(children: [
              Text(d.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(d.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              c.practiced.contains(d.id)
                  ? const Icon(Icons.check_circle, color: AppColors.matcha, size: 20)
                  : Text(tr('연습'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ai)),
            ]),
          ),
        ),
      const SizedBox(height: 6),
      if (c.examScores.isNotEmpty) Text(trf('지난 시험 {0}점 — 80점 이상이면 통과', [c.examScores.last]), style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight)),
      const SizedBox(height: 6),
      FilledButton(
        key: const ValueKey('cur-exam'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
        onPressed: c.allPracticed ? () => _exam(list) : null,
        child: Text(c.allPracticed ? tr('코스 시험 보기') : tr('모든 편을 연습하면 시험이 열려요')),
      ),
      const SizedBox(height: 14),
      if (!_confirmNew)
        TextButton(key: const ValueKey('cur-new'), onPressed: () => setState(() => _confirmNew = true), child: Text(tr('새 코스 시작')))
      else
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cal, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr('지금 코스를 그만두고 새 코스를 고를까요? 복습 일정은 그대로 남아요.'), style: const TextStyle(fontSize: 13.5, color: AppColors.sumi)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => setState(() => _confirmNew = false), child: Text(tr('계속하기'))),
              FilledButton(
                key: const ValueKey('cur-new-yes'),
                onPressed: () async {
                  s.course = null;
                  _confirmNew = false;
                  await _save();
                },
                child: Text(tr('새 코스 고르기')),
              ),
            ]),
          ]),
        ),
    ];
  }

  // ── 동작 ──
  Future<void> _practice(Dialogue d) async {
    final qs = buildQuestions(d, _levelDs, Random());
    final res = await openFull<List<bool>>(context, (_) => _PracticeScreen(dialogue: d, questions: qs));
    if (res == null) return;
    final now = DateTime.now();
    s.rollDay(now);
    for (var i = 0; i < qs.length && i < res.length; i++) {
      s.grade(qs[i].lineId, res[i], now);
    }
    final c = s.course;
    if (c != null && !c.practiced.contains(d.id)) {
      c.practiced.add(d.id);
      s.todayNew++;
    }
    await _save();
  }

  Future<void> _startReview() async {
    final now = DateTime.now();
    final due = s.dueReview(now).take(20).toList();
    final rnd = Random();
    final qs = <CurQuestion>[];
    for (final r in due) {
      final parts = r.lineId.split('#');
      final d = ds.byId(parts.first);
      final n = int.tryParse(parts.length > 1 ? parts[1] : '');
      if (d == null || n == null) {
        s.review.remove(r); // 편이 없어졌으면 대기열에서 뺀다
        continue;
      }
      qs.addAll(buildQuestions(d, ds.list(region: d.region), rnd, maxQ: 1, onlyTurns: {n}));
    }
    if (qs.isEmpty) {
      await _save();
      return;
    }
    if (!mounted) return;
    final res = await openFull<List<bool>>(context, (_) => _QuizScreen(title: tr('복습'), questions: qs));
    if (res == null) return;
    s.rollDay(DateTime.now());
    for (var i = 0; i < qs.length && i < res.length; i++) {
      s.grade(qs[i].lineId, res[i], DateTime.now());
      s.todayReview++;
    }
    await _save();
  }

  Future<void> _exam(List<Dialogue> list) async {
    final qs = buildExam(list, _levelDs, Random());
    final res = await openFull<List<bool>>(context, (_) => _QuizScreen(title: tr('코스 시험'), questions: qs, exam: true));
    if (res == null) return;
    final c = s.course!;
    final right = res.where((x) => x).length;
    final score = curriculumScore(right, qs.length);
    c.examScores.add(score);
    final now = DateTime.now();
    for (var i = 0; i < qs.length && i < res.length; i++) {
      if (!res[i]) s.grade(qs[i].lineId, false, now);
    }
    if (curriculumPassed(right, qs.length)) {
      c.passedAt = dayKey(now);
      for (final id in c.dialogueIds) {
        if (!s.passedDialogues.contains(id)) s.passedDialogues.add(id);
      }
      _banner = trf('코스 통과! {0}점', [score]);
      final level = _levelDs;
      if (level.isNotEmpty && level.every((d) => s.passedDialogues.contains(d.id))) {
        final regs = ds.regions;
        final i = regs.indexOf(s.level!);
        if (i >= 0 && i + 1 < regs.length) {
          s.level = regs[i + 1];
          s.course = null;
          _banner = trf('{0} 레벨을 모두 통과! {1} 레벨이 열렸어요.', [regs[i], regs[i + 1]]);
        } else {
          _banner = tr('모든 레벨을 통과했어요!');
        }
      }
    } else {
      // 틀린 편만 다시 연습 → 다시 시험
      final wrongEps = {for (var i = 0; i < qs.length && i < res.length; i++) if (!res[i]) qs[i].lineId.split('#').first};
      c.practiced.removeWhere(wrongEps.contains);
      _banner = trf('{0}점 — 80점이 안 돼요. 틀린 편을 다시 연습하고 시험을 보세요.', [score]);
    }
    await _save();
  }

  ButtonStyle _tileStyle() => OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: AppColors.cal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        side: const BorderSide(color: AppColors.line, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.ai, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      );
}

/// 편 연습 — 1) 듣기·읽기(녹음 있으면 녹음, 없으면 기기 TTS — 회화 화면과 같은 재생기) 2) 확인 문제.
class _PracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  final List<CurQuestion> questions;
  const _PracticeScreen({required this.dialogue, required this.questions});
  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen> {
  bool _quiz = false;
  @override
  Widget build(BuildContext context) {
    if (_quiz) return _QuizScreen(title: widget.dialogue.title, questions: widget.questions, popOnDone: true);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(widget.dialogue.title)),
      body: Column(children: [
        Expanded(child: EpisodePlayPane(dialogue: widget.dialogue, autoPlay: false)),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset(context)),
          child: FilledButton(
            key: const ValueKey('cur-to-quiz'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.ai, minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              TtsService.instance.stop();
              widget.questions.isEmpty ? Navigator.of(context).pop(<bool>[]) : setState(() => _quiz = true);
            },
            child: Text(trf('확인 문제 풀기 ({0})', [widget.questions.length])),
          ),
        ),
      ]),
    );
  }
}

/// 문제 풀기 — 끝나면 맞힘 목록(`List<bool>`)을 돌려준다.
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<CurQuestion> questions;
  final bool exam;
  final bool popOnDone;
  const _QuizScreen({required this.title, required this.questions, this.exam = false, this.popOnDone = true});
  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int _i = 0;
  String? _picked;
  final List<bool> _res = [];

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    final done = _i >= qs.length;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(widget.title)),
      body: done ? _summary() : _question(qs[_i], qs.length),
    );
  }

  Widget _summary() {
    final right = _res.where((x) => x).length;
    final score = curriculumScore(right, _res.length);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.exam ? (score >= kCurriculumPass ? '🎉' : '💪') : '✅', style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(trf('{0}문제 중 {1}개 맞힘 · {2}점', [_res.length, right, score]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('cur-quiz-done'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi),
            onPressed: () => Navigator.of(context).pop(List<bool>.from(_res)),
            child: Text(tr('확인')),
          ),
        ]),
      ),
    );
  }

  Widget _question(CurQuestion q, int n) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
          const SizedBox(height: 12),
          Text(q.prompt, key: const ValueKey('cur-stem'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4)),
          if (q.sub != null) ...[const SizedBox(height: 6), Text(q.sub!, style: const TextStyle(fontSize: 14, color: AppColors.sumiLight))],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(tr(q.kind == 'blank' ? '빈칸에 맞는 낱말을 고르세요.' : '뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi))),
            IconButton(onPressed: () => TtsService.instance.speak(q.kind == 'blank' ? q.prompt.replaceFirst('____', q.answer) : q.prompt), icon: const Icon(Icons.volume_up, color: AppColors.beni)),
          ]),
          const SizedBox(height: 10),
          for (var k = 0; k < q.options.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                key: ValueKey('cur-opt-$k'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                  side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
                ),
                onPressed: _picked != null
                    ? null
                    : () => setState(() {
                          _picked = q.options[k];
                          _res.add(q.options[k] == q.answer);
                        }),
                child: Text(q.options[k], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
              ),
            ),
          if (_picked != null)
            FilledButton(
              key: const ValueKey('cur-next'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
              onPressed: () => setState(() {
                _i++;
                _picked = null;
              }),
              child: Text(tr('다음 →')),
            ),
        ]),
      );
}

/// 홈 카드 — 「오늘: 복습 N · 새 편 N」 + 진행 막대(스펙 §6). 누르면 커리큘럼 화면.
class CurriculumHomeCard extends StatefulWidget {
  const CurriculumHomeCard({super.key});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    CurriculumStore.instance.load().then((_) => mounted ? setState(() => _ready = true) : null);
  }

  @override
  Widget build(BuildContext context) {
    final s = CurriculumStore.instance.state;
    final now = DateTime.now();
    final dueN = _ready ? s.dueReview(now).length : 0;
    final started = _ready && s.level != null;
    final total = s.dailyGoal + s.todayReview + dueN;
    final done = s.todayNew.clamp(0, s.dailyGoal) + s.todayReview;
    final line = !started
        ? tr('레벨에서 다이얼로그를 골라 매일 연습 · 80% 넘으면 다음 코스')
        : s.todayDone(now)
            ? (s.streakCount > 0 ? '${tr('오늘 분량 끝')} · ${trf('🔥 {0}일 연속', [s.streakCount])}' : tr('오늘 분량 끝'))
            : trf('오늘: 복습 {0} · 새 편 {1}', [dueN, s.newLeft()]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: const ValueKey('cur-home-card'),
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await openPane(context, (_) => const CurriculumScreen());
          await CurriculumStore.instance.load();
          if (mounted) setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.ai, borderRadius: BorderRadius.circular(10)),
              child: const Text('TV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                const SizedBox(height: 2),
                Text(line, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                if (started) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: total == 0 ? 1 : (done / total).clamp(0.0, 1.0), minHeight: 5, backgroundColor: AppColors.line, color: AppColors.ai),
                  ),
                ],
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}
