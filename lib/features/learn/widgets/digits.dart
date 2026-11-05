// Bangla digit conversion, shared by Area 2 screens. English
// output keeps Latin digits; Bangla output converts every digit.
const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String toBnDigits(String input) {
  final buf = StringBuffer();
  for (final ch in input.split('')) {
    final d = int.tryParse(ch);
    buf.write(d == null ? ch : _bnDigits[d]);
  }
  return buf.toString();
}

String numStr(int value, bool bangla) =>
    bangla ? toBnDigits('$value') : '$value';
