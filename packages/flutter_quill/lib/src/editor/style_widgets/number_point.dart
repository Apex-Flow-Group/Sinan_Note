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

  @override
  Widget build(BuildContext context) {
    // نحدد اتجاه النص من الـ Directionality الأب (المحدد في text_block.dart)
    final dir = Directionality.of(context);

    // النص دائماً LTR لتجنب عكس الأرقام والنقطة بواسطة BiDi engine
    final label = withDot ? '$index.' : index;

    final child = Directionality(
      textDirection: TextDirection.ltr,
      child: Text(label, style: style, textAlign: textAlign),
    );

    return Container(
      alignment: dir == TextDirection.ltr
          ? AlignmentDirectional.topStart
          : AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding),
      color: backgroundColor,
      child: child,
    );
  }
}
