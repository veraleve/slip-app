import 'package:flutter/material.dart';
import '../theme/slip_theme.dart';

class HairlineInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? helperText;
  final TextInputType keyboardType;

  const HairlineInput({
    super.key,
    required this.label,
    this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.helperText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
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
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SlipTheme.steelLight,
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
