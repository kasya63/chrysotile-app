import 'package:chrysotile_app/core/storage/text_scale_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final textScaleStoreProvider = Provider<TextScaleStore>((ref) {
  return TextScaleStore();
});

final textScaleProvider =
    StateNotifierProvider<TextScaleNotifier, double>((ref) {
  return TextScaleNotifier(ref.watch(textScaleStoreProvider));
});

class TextScaleNotifier extends StateNotifier<double> {
  TextScaleNotifier(this._store) : super(TextScaleStore.normal) {
    _load();
  }

  final TextScaleStore _store;

  Future<void> _load() async {
    state = await _store.load();
  }

  Future<void> setScale(double value) async {
    state = value;
    await _store.save(value);
  }
}
