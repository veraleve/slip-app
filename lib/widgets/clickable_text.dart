import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/native_device_service.dart';
import '../theme/slip_theme.dart';

class ClickableText extends StatelessWidget {
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

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final defaultLinkStyle = linkStyle ??
        defaultStyle.copyWith(
          color: const Color(0xFF1E88E5), // Clean academic link blue
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        );

    final matches = _urlRegex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      final url = match.group(0)!;
      // Clean trailing punctuation from URL if user wrote "https://example.com."
      String cleanUrl = url;
      String trailingPunctuation = '';
      if (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
        trailingPunctuation = url.substring(url.length - 1);
        cleanUrl = url.substring(0, url.length - 1);
      }

      spans.add(
        TextSpan(
          text: cleanUrl,
          style: defaultLinkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              NativeDeviceService.openUrl(cleanUrl);
            },
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

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
