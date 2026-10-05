/// تطبيع النص العربي للبحث: بلا تشكيل، الألفات ألف واحدة، التاء المربوطة هاء،
/// الألف المقصورة ياء، وحروف لاتينية صغيرة.
abstract final class TextNormalizer {
  static final _diacritics = RegExp(r'[ً-ٟ]');
  static final _alefVariants = RegExp(r'[أإآ]');

  static String normalize(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(_diacritics, '')
        .replaceAll(_alefVariants, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }
}
