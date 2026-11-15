import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Same check as test/legal_assets_test.dart, but runs inside the real app
/// bundle on a device or simulator:
///   flutter test integration_test/legal_assets_test.dart -d <device-id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('legal assets are bundled on device', (tester) async {
    for (final path in [
      'assets/legal/privacy_policy_ru.md',
      'assets/legal/terms_ru.md',
      'assets/legal/delete_account_ru.md',
    ]) {
      final text = await rootBundle.loadString(path);
      expect(text.isNotEmpty, true, reason: path);
    }
  });
}
