import 'package:flutter/material.dart';
import '../theme/slip_theme.dart';

class HairlineInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final bool isPassword;
  final Widget? suffixIcon;
  final String? helperText;
  final TextInputType keyboardType;
  final int maxLines;

  const HairlineInput({
    super.key,
    this.label = '',
    this.placeholder,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.isPassword = false,
    this.suffixIcon,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHint = hint ?? placeholder;
    final effectiveObscure = isPassword || obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: SlipTheme.steel,
                    ),
              ),
              if (helperText != null)
                Text(
                  helperText!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          obscureText: effectiveObscure,
          keyboardType: effectiveObscure ? TextInputType.text : keyboardType,
          maxLines: effectiveObscure ? 1 : maxLines,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: SlipTheme.carbon,
                fontSize: 14,
              ),
          decoration: InputDecoration(
            hintText: effectiveHint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SlipTheme.steelLight,
                  fontSize: 13,
                ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: SlipTheme.hairline, width: 0.8),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: SlipTheme.hairline, width: 0.8),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: SlipTheme.carbon, width: 1.5),
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ),
      ],
    );
  }
}
