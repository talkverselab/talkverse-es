/// 단어표·퀴즈에서 빼는 낱말 — 비속어·성인 말(12+ 등급, uk 심사 점검 2026-11-23).
/// 빈도 통계 원본(`lang_es_top.csv`)은 그대로 두고, 앱 DB 에 넣을 때 거른다.
const kBlockedWords = {
  'cabrón', 'cabrona', 'cagar', 'carajo', 'coño', 'culo', 'droga', 'drogas', 'follar', 'hostia', 'hostias',
  'joder', 'jodido', 'jodida', 'maricón', 'marica', 'mierda', 'pendejo', 'puta', 'puto', 'putas', 'putos',
  'sexo', 'zorra', 'gilipollas', 'polla', 'cojones', 'verga', 'chingar', 'capullo', 'idiota', 'imbécil',
};

bool isBlockedWord(String w) => kBlockedWords.contains(w.trim().toLowerCase());
