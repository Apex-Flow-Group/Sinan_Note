/// مسافة Levenshtein بين نصين (عدد الإدراجات والحذف والاستبدالات).
/// صفّان فقط من الجدول، فالذاكرة O(طول النص الثاني).
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      current[j] = substitution < deletion
          ? (substitution < insertion ? substitution : insertion)
          : (deletion < insertion ? deletion : insertion);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}
