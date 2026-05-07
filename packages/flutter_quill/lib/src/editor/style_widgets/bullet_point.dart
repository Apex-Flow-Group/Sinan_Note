import 'package:flutter/widgets.dart';

class QuillBulletPoint extends StatelessWidget {
  const QuillBulletPoint({
    required this.style,
    required this.width,
    this.padding = 0,
    this.backgroundColor,
    this.textAlign,
    super.key,
  });

  final TextStyle style;
  final double width;
  final double padding;
  final Color? backgroundColor;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 16;
    final lineHeight = style.height ?? 1.15;
    final topOffset = (fontSize * (lineHeight - 1.15)) / 2;
    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding, top: topOffset),
      color: backgroundColor,
      child: Text(
        '•',
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
