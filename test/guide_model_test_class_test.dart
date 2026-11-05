import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('model-test list resolves the saved class before reading sets',
      () {
    final src = File(
      'lib/features/practice/guide_model_test_list_screen.dart',
    ).readAsStringSync();
    expect(src, contains('resolveSchoolClass()'));
    expect(src, contains('cachedSets('));
    expect(src, contains('schoolClass: c'));
  });
}
