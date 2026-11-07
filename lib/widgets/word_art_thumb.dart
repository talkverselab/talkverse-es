import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';

/// 단어 타일용 그림 썸네일(512 webp). 그림이 없으면 빈 자리. 실패해도 화면은 멀쩡해야 한다.
class WordArtThumb extends StatelessWidget {
  final String word;
  final int? rank;
  final double size;
  const WordArtThumb({super.key, required this.word, this.rank, this.size = 44});

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: ArtService.instance.urlFor(word, rank: rank),
        builder: (context, snap) {
          final url = snap.data;
          if (url == null) return SizedBox(width: size, height: size);
          return ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.25),
            child: Container(
              width: size,
              height: size,
              color: AppColors.washiDeep,
              child: Image(image: artProvider(url), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          );
        },
      );
}
