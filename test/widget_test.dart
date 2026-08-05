import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HomeFeed parses API payload', () {
    final feed = HomeFeed.fromJson({
      'hero': [
        {
          'id': 1,
          'title': 'Тест',
          'subtitle': '',
          'excerpt': 'Кратко',
          'date': '2026-07-08T10:00:00+05:00',
          'date_display': '08.07.2026',
          'permalink': 'https://chrysotile.kz/test',
          'image': null,
          'thumbnail': null,
          'categories': [],
          'reading_min': 2,
          'views': 10,
        },
      ],
      'sections': [],
    });

    expect(feed.hero, hasLength(1));
    expect(feed.hero.first.title, 'Тест');
  });
}
