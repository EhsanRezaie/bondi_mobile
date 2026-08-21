// lib/screens/profile/verify_selfie_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../generated/app_localizations.dart';
import '../../models/photo.dart';
import '../../services/photo_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/action_toast.dart';
import '../../widgets/selfie_capture_view.dart';

class VerifySelfieScreen extends StatefulWidget {
  const VerifySelfieScreen({super.key});

  @override
  State<VerifySelfieScreen> createState() => _VerifySelfieScreenState();
}

class _VerifySelfieScreenState extends State<VerifySelfieScreen> {
  File? _selfieFile;
  bool _isVerifying = false;
  bool _isLoadingStatus = true;
  VerificationStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final t = AppLocalizations.of(context)!;
    final status = await PhotoService.getVerificationStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _isLoadingStatus = false;
    });
    if (status != null && !status.eligibleToVerify && !status.isVerified) {
      showActionToast(
        context,
        t.verify_selfie_cooldown(status.cooldownRemainingSeconds ?? 0),
        isError: true,
      );
    }
  }

  Future<void> _pickSelfie() async {
    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const SelfieCaptureView()),
    );
    if (file == null || !mounted) return;
    final validationError = PhotoService.validateImage(file);
    if (validationError != null) {
      showActionToast(context, validationError, isError: true);
      return;
    }
    setState(() {
      _selfieFile = file;
    });
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
      await _loadStatus();
    }
  }

  bool get _canVerify {
    if (_isVerifying) return false;
    if (_status == null) return true;
    if (_status!.isVerified) return false;
    if (!_status!.eligibleToVerify &&
        (_status!.cooldownRemainingSeconds ?? 0) > 0) {
      return false;
    }
    return _status!.eligibleToVerify || _selfieFile != null;
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

                // Status banner
                if (_isLoadingStatus)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.verify_selfie_checking,
                          style: AppTheme.bodyMedium.copyWith(
                            color: textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_status?.isVerified ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.verify_selfie_already_verified,
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!(_status?.eligibleToVerify ?? true) &&
                    (_status?.cooldownRemainingSeconds ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightError.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_top,
                            color: AppTheme.lightError,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.verify_selfie_cooldown(
                                _status!.cooldownRemainingSeconds!,
                              ),
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.lightError,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                    onPressed: _canVerify ? _verify : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canVerify
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.3),
                      foregroundColor: _canVerify
                          ? Colors.white
                          : primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
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
                        : Text(
                            t.verify_selfie_submit,
                            style: AppTheme.buttonText,
                          ),
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
