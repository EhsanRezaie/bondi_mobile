// lib/widgets/phone_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../config/app_theme.dart';
import '../utils/phone_utils.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<CountryCode> onCountryChanged;
  final VoidCallback? onSubmitted;
  final bool Function(String value)? validator;

  /// Maximum number of national digits accepted (driven by the selected
  /// country). Falls back to 15 when not provided.
  final int maxLength;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.errorText,
    this.onChanged,
    required this.onCountryChanged,
    this.onSubmitted,
    this.validator,
    this.maxLength = 15,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    // Country picker dialog follows the active theme in both light and dark.
    final dialogBackground = surfaceColor;
    final dialogTextColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final dialogMutedColor = textMutedColor;
    final searchFill = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            const PhoneNumberInputFormatter(),
            LengthLimitingTextInputFormatter(maxLength),
          ],
          style: AppTheme.bodyLarge.copyWith(color: onSurfaceColor),
          onSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTheme.bodyMedium.copyWith(color: textMutedColor),
            prefixIconConstraints: const BoxConstraints(minWidth: 60),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
              child: CountryCodePicker(
                onChanged: onCountryChanged,
                initialSelection: 'IR',
                favorite: const ['+98'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                padding: EdgeInsets.zero,
                textStyle: AppTheme.bodyBold.copyWith(color: onSurfaceColor),
                dialogSize: const Size(400, 480),
                dialogBackgroundColor: dialogBackground,
                dialogTextStyle: AppTheme.bodyLarge.copyWith(
                  color: dialogTextColor,
                ),
                headerTextStyle: AppTheme.titleMedium.copyWith(
                  color: dialogTextColor,
                ),
                closeIcon: Icon(
                  Icons.close,
                  color: dialogTextColor,
                  size: 20,
                ),
                boxDecoration: BoxDecoration(
                  color: dialogBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                searchStyle: AppTheme.bodyMedium.copyWith(
                  color: dialogTextColor,
                ),
                searchDecoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: dialogMutedColor,
                  ),
                  filled: true,
                  fillColor: searchFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
                flagDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            prefixIconColor: textMutedColor,
            filled: true,
            fillColor: surfaceColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide(
                color: errorText != null ? AppTheme.lightError : borderColor,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide(
                color: errorText != null ? AppTheme.lightError : primaryColor,
                width: 2.0,
              ),
            ),
            errorText: errorText,
            errorStyle: TextStyle(
              fontSize: 12,
              color: AppTheme.lightError,
            ),
          ),
        ),
      ],
    );
  }
}
