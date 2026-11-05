// Guide-empty dialog (Phase 2, plan §2 step 2): when a daily
// or practice start finds NO guide questions, the app NEVER
// silently substitutes the bank. It asks: start an explicit
// bank set, or cancel. Own tiny bn/en table (shared by the
// practice + practice-tab screens, so the keys are not
// duplicated across two page string files).
import 'package:flutter/material.dart';

import '../../../l10n/language_provider.dart';

const _bn = {
  'title': 'গাইডে প্রশ্ন পাওয়া যায়নি',
  'note': 'এই বিষয়/শ্রেণির গাইড-প্রশ্ন সার্ভারে পাওয়া যায়নি। '
      'ব্যাংক-সেট দিয়ে শুরু করলে সেটা স্পষ্টভাবে ব্যাংক-সেট '
      'হিসেবে দেখাবে।',
  'bank': 'ব্যাংক-সেট দিয়ে শুরু করো',
  'cancel': 'বাতিল',
};

const _en = {
  'title': 'No guide questions found',
  'note': 'No guide questions were found on the server for this '
      'subject/class. Starting a bank set will be clearly '
      'labelled as a bank set.',
  'bank': 'Start with bank set',
  'cancel': 'Cancel',
};

/// True = the user explicitly chose a bank set; false/null =
/// cancel (stay on the practice screen, no quiz started).
Future<bool> showGuideFallbackDialog(BuildContext context) async {
  final s = languageNotifier.value.languageCode == 'bn' ? _bn : _en;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s['title']!),
      content: Text(s['note']!),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s['cancel']!),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s['bank']!),
        ),
      ],
    ),
  );
  return ok == true;
}
