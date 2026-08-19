// lib/screens/profile/verify_selfie_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../generated/app_localizations.dart';
import '../../services/photo_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/action_toast.dart';

class VerifySelfieScreen extends StatefulWidget {
  const VerifySelfieScreen({super.key});

  @override
  State<VerifySelfieScreen> createState() => _VerifySelfieScreenState();
}

class _VerifySelfieScreenState extends State<VerifySelfieScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selfieFile;
  bool _isVerifying = false;

  Future<void> _pickSelfie() async {
    final t = AppLocalizations.of(context)!;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        final file = File(image.path);
        final validationError = PhotoService.validateImage(file);
        if (validationError != null) {
          if (mounted) {
            showActionToast(context, validationError, isError: true);
          }
          return;
        }
        setState(() {
          _selfieFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        showActionToast(context, t.error_something_wrong, isError: true);
      }
    }
  }

  Future<void> _verify() async {
    final t = AppLocalizations.of(context)!;
    if (_selfieFile == null) {
      showActionToast(context, t.verify_selfie_pick_first, isError: true);
      return;
    }

    setState(() => _isVerifying = true);

    final result = await PhotoService.verifyWithSelfie(_selfieFile!);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (result.verified) {
      showActionToast(context, result.message);
      Navigator.pop(context, true);
    } else {
      showActionToast(context, result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.verify_selfie_title,
          style: AppTheme.titleMedium.copyWith(color: onSurfaceColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AppLayout.box(
          context: context,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  t.verify_selfie_subtitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(color: textMutedColor),
                ),
                const SizedBox(height: 12),
                Text(
                  t.verify_selfie_instructions,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(color: textMutedColor),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _isVerifying ? null : _pickSelfie,
                      child: Container(
                        width: 220,
                        height: 300,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          image: _selfieFile != null
                              ? DecorationImage(
                                  image: FileImage(_selfieFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selfieFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 56,
                                    color: textMutedColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    t.verify_selfie_take_selfie,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: textMutedColor,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selfieFile != null) ...[
                  OutlinedButton(
                    onPressed: _isVerifying ? null : _pickSelfie,
                    style: AppTheme.outlineButton,
                    child: Text(t.verify_selfie_retake),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.verify_selfie_submit, style: AppTheme.buttonText),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
