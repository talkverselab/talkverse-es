import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../widgets/achievement_desk.dart';
import '../widgets/episode_play_pane.dart';
import '../widgets/spanish_decor.dart';
import 'conversation_screen.dart';
import 'dialogue_card_screen.dart';
import 'dialogue_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'topic_vocab_screen.dart';
import 'verb_screen.dart';
import 'word_freq_screen.dart';

/// 메인 — 탭 4개: 배우기 · 복습 · 탐색 · 나. 일본어앱 main_screen.dart 의 틀을 옮긴 것(2026-11-02, 공통 프롬프터 §5).
/// 넓은 화면(isWide): 앱바 아래 왼쪽 = 탭 레일 + 그 탭의 목록, 오른쪽 = 고른 내용(자기 Navigator). 폰: 하단 탭 + 내용 전체 화면.
/// 회화 재생·그림 카드처럼 집중하는 화면은 어느 쪽이든 openFull 로 전체 화면.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _pane = GlobalKey<NavigatorState>();

  static List<(IconData, IconData, String)> get _tabs => [
        (Icons.menu_book_outlined, Icons.menu_book, tr('배우기')),
        (Icons.style_outlined, Icons.style, tr('복습')),
        (Icons.explore_outlined, Icons.explore, tr('탐색')),
        (Icons.person_outline, Icons.person, tr('나')),
      ];

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      centerTitle: false,
      title: GradText(tr('스페인어유니버스'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
    );
    final stack = IndexedStack(index: _index, children: const [LearnTab(), ReviewTab(), ExploreTab(), MeTab()]);
    if (!isWide(context)) {
      return Scaffold(
        appBar: appBar,
        body: stack,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: t.$3)],
        ),
      );
    }
    // 넓은 화면(아이패드·태블릿·폴드 펼침): 레일 + 왼쪽 칸(탭 목록) | 오른쪽 칸(연 화면). 두 칸까지만.
    final w = MediaQuery.sizeOf(context).width;
    final left = (w * 0.34).clamp(300.0, 440.0);
    return Pane(
      navKey: _pane,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _pane.currentState?.maybePop(),
        child: Scaffold(
          appBar: appBar,
          body: Row(children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: w >= 900 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
              backgroundColor: AppColors.washiDeep,
              indicatorColor: AppColors.kinBright.withValues(alpha: 0.6),
              selectedIconTheme: const IconThemeData(color: AppColors.beniDeep),
              unselectedIconTheme: const IconThemeData(color: AppColors.muted),
              selectedLabelTextStyle: const TextStyle(color: AppColors.beni, fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
              destinations: [for (final t in _tabs) NavigationRailDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2), label: Text(t.$3))],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
            SizedBox(width: left, child: stack),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
            Expanded(
              child: ClipRect(
                child: Navigator(
                  key: _pane,
                  onGenerateInitialRoutes: (_, _) => [MaterialPageRoute(builder: (_) => const _PanePlaceholder())],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 오른쪽 칸이 비어 있을 때.
class _PanePlaceholder extends StatelessWidget {
  const _PanePlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const TileBadge(text: 'Ñ', size: 56, color: AppColors.beni),
            const SizedBox(height: 14),
            Text(tr('왼쪽에서 고르면 여기에 열립니다 · 회화 재생·카드는 전체 화면'),
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

/// 탭 안의 한 줄(카드) — 배지 + 제목·부제 + 꺾쇠. 누르면 오른쪽 칸(넓은 화면) 또는 push.
class _NavRow extends StatelessWidget {
  final String badge;
  final Color? color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavRow({required this.badge, this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  TileBadge(text: badge, size: 40, color: color ?? AppColors.beni),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                      const SizedBox(height: 2),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                ]),
              ),
            ),
          ),
        ),
      );
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5)),
    );

Widget _tabList(BuildContext context, List<Widget> children) => ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)),
      children: children,
    );

// ────────── 배우기 ──────────

/// 배우기: 인사 → 오늘의 학습(이어서 읽기) → 회화 → 기초 → 단어.
class LearnTab extends StatefulWidget {
  const LearnTab({super.key});
  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  @override
  void initState() {
    super.initState();
    DialogueService.instance.ensureLoaded().then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned(top: 0, left: 0, right: 0, height: 200, child: MeshBackdrop()),
      _tabList(context, [
        const SizedBox(height: 6),
        Row(children: [
          const Text('¡Hola!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.sumi, letterSpacing: -1)),
          const SizedBox(width: 6),
          const Text('👋', style: TextStyle(fontSize: 22)),
        ]),
        const SizedBox(height: 2),
        Text(tr('한국 학습자, 오늘도 시작해요'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, fontWeight: FontWeight.w500)),
        const SizedBox(height: 14),
        _TodayCard(key: ValueKey(DialogueService.instance.all.length)), // 회화를 다 읽은 뒤 다시 그려지게(const 면 setState 로도 안 바뀜)
        _section(tr('회화')),
        _NavRow(badge: '💬', title: tr('회화'), subtitle: tr('장면 컷과 함께 읽고 듣기'), onTap: () => openPane(context, (_) => const DialogueHomeScreen())),
        _NavRow(badge: '✎', color: AppColors.ai, title: tr('회화 노트'), subtitle: tr('턴마다 외움 표시·메모'), onTap: () => openPane(context, (_) => const ConversationScreen())),
        _section(tr('기초')),
        _NavRow(badge: 'V', color: AppColors.irregular, title: tr('동사 활용'), subtitle: 'Conjugación', onTap: () => openPane(context, (_) => const VerbScreen())),
        _NavRow(badge: 'el', color: AppColors.mar, title: tr('성·수'), subtitle: tr('준비 중'), onTap: () => openPane(context, (_) => _ComingSoon(title: tr('성·수 일치')))),
        _NavRow(badge: 'rr', color: AppColors.er, title: tr('발음'), subtitle: tr('준비 중'), onTap: () => openPane(context, (_) => _ComingSoon(title: tr('발음 (rr · ñ · 강세)')))),
        _section(tr('단어')),
        _NavRow(badge: 'F', color: AppColors.muted, title: tr('빈도 단어'), subtitle: 'Frecuencia', onTap: () => openPane(context, (_) => const WordFreqScreen())),
        _NavRow(badge: 'W', color: AppColors.oliva, title: tr('주제별 단어'), subtitle: 'Vocabulario', onTap: () => openPane(context, (_) => const TopicVocabScreen())),
        _NavRow(
            badge: 'E',
            color: AppColors.rojoLight,
            title: tr('주제별 표현'),
            subtitle: 'Expresión',
            onTap: () => openPane(context, (_) => TopicVocabScreen(title: tr('주제별 표현'), asset: 'assets/data/vocab/travel_expressions.json'))),
      ]),
    ]);
  }
}

/// 「오늘의 학습」 — 마지막으로 연 편(없으면 첫 편)의 장면 컷 + 읽기 시작.
class _TodayCard extends StatelessWidget {
  const _TodayCard({super.key});
  @override
  Widget build(BuildContext context) {
    final svc = DialogueService.instance;
    final last = svc.lastOpenedId != null ? svc.byId(svc.lastOpenedId!) : null;
    final d = last ?? (svc.all.isNotEmpty ? svc.list().first : null);
    if (d == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(16), boxShadow: kCardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(height: 150, child: SceneCut(dialogue: d, turn: d.turns.first, bubble: true)),
        const SizedBox(height: 10),
        Text(tr(last == null ? '오늘의 컷' : '이어서 읽기'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.beni, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('${d.emoji} ${d.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.sumi)),
        const SizedBox(height: 2),
        Text('${tr(DialogueService.levelKo[d.region] ?? d.region)} · ${trf('{0}턴', [d.turns.length])}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => openPane(context, (_) => DialogueScreen(dialogue: d)),
            style: FilledButton.styleFrom(backgroundColor: AppColors.beni, foregroundColor: Colors.white, shape: const StadiumBorder(), visualDensity: VisualDensity.compact),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(tr('읽기 시작'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ────────── 복습 ──────────

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});
  @override
  Widget build(BuildContext context) => _tabList(context, [
        _section(tr('복습')),
        _NavRow(
          badge: '🃏',
          color: AppColors.ai,
          title: tr('그림 카드'),
          subtitle: tr('그림만 보고 문장 떠올리기'),
          onTap: () async {
            final svc = DialogueService.instance;
            await svc.ensureLoaded();
            final d = (svc.lastOpenedId != null ? svc.byId(svc.lastOpenedId!) : null) ?? (svc.all.isNotEmpty ? svc.list().first : null);
            if (d != null && context.mounted) openFull(context, (_) => DialogueCardScreen(dialogue: d));
          },
        ),
        _NavRow(badge: 'V', color: AppColors.irregular, title: tr('동사 활용'), subtitle: tr('활용표 다시 보기'), onTap: () => openPane(context, (_) => const VerbScreen())),
        _NavRow(badge: '✎', color: AppColors.muted, title: tr('회화 노트'), subtitle: tr('외운 턴 다시 보기'), onTap: () => openPane(context, (_) => const ConversationScreen())),
      ]);
}

// ────────── 탐색 ──────────

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});
  @override
  Widget build(BuildContext context) => _tabList(context, [
        _section(tr('단어')),
        _NavRow(badge: 'F', color: AppColors.muted, title: tr('빈도 단어'), subtitle: 'Frecuencia', onTap: () => openPane(context, (_) => const WordFreqScreen())),
        _NavRow(badge: 'W', color: AppColors.oliva, title: tr('주제별 단어'), subtitle: 'Vocabulario', onTap: () => openPane(context, (_) => const TopicVocabScreen())),
        _NavRow(
            badge: 'E',
            color: AppColors.rojoLight,
            title: tr('주제별 표현'),
            subtitle: 'Expresión',
            onTap: () => openPane(context, (_) => TopicVocabScreen(title: tr('주제별 표현'), asset: 'assets/data/vocab/travel_expressions.json'))),
        _section(tr('문법')),
        _NavRow(badge: 'V', color: AppColors.irregular, title: tr('동사 활용'), subtitle: 'Conjugación', onTap: () => openPane(context, (_) => const VerbScreen())),
      ]);
}

// ────────── 나 ──────────

class MeTab extends StatelessWidget {
  const MeTab({super.key});
  @override
  Widget build(BuildContext context) => _tabList(context, [
        _section(tr('성과')),
        const AchievementDesk(),
        _section(tr('나')),
        _NavRow(badge: '👤', color: AppColors.ai, title: tr('프로필 · 설정'), subtitle: tr('이름·성별·계정·앱 업데이트'), onTap: () => openPane(context, (_) => const ProfileScreen())),
        _NavRow(badge: '📈', color: AppColors.muted, title: tr('진행'), subtitle: tr('회화·단어 진행도'), onTap: () => openPane(context, (_) => const ProgressScreen())),
      ]);
}

class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon({required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cal,
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(tr('Próximamente · 준비 중'), style: const TextStyle(color: AppColors.tintaLight, letterSpacing: 2))),
      );
}
