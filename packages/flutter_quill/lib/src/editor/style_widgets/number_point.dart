import 'package:flutter/widgets.dart';
import '../../../flutter_quill.dart';

class QuillNumberPoint extends StatelessWidget {
  const QuillNumberPoint({
    required this.index,
    required this.indentLevelCounts,
    required this.count,
    required this.style,
    required this.width,
    required this.attrs,
    this.textDirection,
    this.textAlign,
    this.withDot = true,
    this.padding = 0.0,
    super.key,
    this.backgroundColor,
  });

  final String index;
  final Map<int?, int> indentLevelCounts;
  final int count;
  final TextStyle style;
  final double width;
  final Map<String, Attribute> attrs;
  final bool withDot;
  final double padding;
  final Color? backgroundColor;
  final TextAlign? textAlign;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final dir = textDirection ?? Directionality.of(context);
    final isLtr = dir == TextDirection.ltr;

    // في LTR: "1."  في RTL: ".1" (التقليد العربي)
    final label = withDot ? (isLtr ? '$index.' : '.$index') : index;

    // النص دائماً LTR لمنع BiDi engine من عكس الأرقام
    final child = Directionality(
      textDirection: TextDirection.ltr,
      child: Text(label, style: style, textAlign: textAlign),
    );

    return Container(
      alignment:
          isLtr ? AlignmentDirectional.topStart : AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding),
      color: backgroundColor,
      child: child,
    );
  }
}
