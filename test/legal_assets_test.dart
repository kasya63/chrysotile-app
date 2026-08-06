import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legal assets are bundled', () async {
    for (final path in [
      'assets/legal/privacy_policy_ru.md',
      'assets/legal/terms_ru.md',
      'assets/legal/delete_account_ru.md',
    ]) {
      final text = await rootBundle.loadString(path);
      expect(text.isNotEmpty, true, reason: path);
      print('OK $path len=${text.length}');
    }
  });
}
