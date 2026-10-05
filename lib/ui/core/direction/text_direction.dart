// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';

/// اتجاه النص يُشتق ولا يُخزَّن: أول حرف يحسم الاتجاه.
///
/// - حرف عربي/عبري/سرياني… ← RTL، حرف لاتيني… ← LTR.
/// - الأرقام: الهندية (٠-٩) ← RTL، والغربية (0-9) ← LTR.
/// - لا شيء يحسم (فراغ، رموز) ← null، فيتبع السطر ما قبله أو [fallback].
///
/// المصدر الوحيد للاتجاه: محرر Quill (`textDirectionResolver`) وكل عرض نص.
TextDirection? strongDirectionOf(String text) {
  final match = _decisive.firstMatch(text);
  if (match == null) return null;
  return match.group(1) != null ? TextDirection.rtl : TextDirection.ltr;
}

TextDirection directionOf(String text,
        {TextDirection fallback = TextDirection.rtl}) =>
    strongDirectionOf(text) ?? fallback;

/// المجموعة 1: يحسم RTL (حروف الكتابات من اليمين + الأرقام الهندية).
/// غير ذلك: حرف لاتيني/يوناني/سيريلي أو رقم غربي يحسم LTR.
final _decisive = RegExp(
  r'([֐-ࣿיִ-﷿ﹰ-﻿٠-٩۰-۹])'
  r'|[A-Za-zÀ-ɏͰ-ϿЀ-ӿ0-9]',
);

/// نص يأخذ اتجاهه من محتواه.
class DirectionalText extends StatelessWidget {
  const DirectionalText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        textDirection: directionOf(data, fallback: Directionality.of(context)),
      );
}
