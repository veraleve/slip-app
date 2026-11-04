import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/native_device_service.dart';

class ClickableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const ClickableText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  State<ClickableText> createState() => _ClickableTextState();
}

class _ClickableTextState extends State<ClickableText> {
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final defaultStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final defaultLinkStyle = widget.linkStyle ??
        defaultStyle.copyWith(
          color: const Color(0xFF1E88E5), // Clean academic link blue
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        );

    final matches = _urlRegex.allMatches(widget.text);
    if (matches.isEmpty) {
      return Text(
        widget.text,
        style: defaultStyle,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: widget.text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      final url = match.group(0)!;
      String cleanUrl = url;
      String trailingPunctuation = '';
      if (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
        trailingPunctuation = url.substring(url.length - 1);
        cleanUrl = url.substring(0, url.length - 1);
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          NativeDeviceService.openUrl(cleanUrl);
        };
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: cleanUrl,
          style: defaultLinkStyle,
          recognizer: recognizer,
        ),
      );

      if (trailingPunctuation.isNotEmpty) {
        spans.add(TextSpan(
          text: trailingPunctuation,
          style: defaultStyle,
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
