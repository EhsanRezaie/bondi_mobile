// lib/screens/profile/blocked_users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/blocked_user.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/services/chat_service.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/widgets/action_toast.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> _blocked = [];
  bool _isLoading = true;
  bool _isUnblocking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ChatService.getBlocks();
      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((j) => BlockedUser.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() {
          _blocked = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'blocked_users_load_error';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'blocked_users_load_error';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmUnblock(BlockedUser user) async {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.blocked_users_unblock,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Text(
          t.blocked_users_unblock_confirm(user.name ?? ''),
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t.delete_account_cancel,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: _isUnblocking
                ? null
                : () => Navigator.pop(ctx, true),
            child: Text(
              t.blocked_users_unblock,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkError : AppTheme.lightError,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _unblock(user);
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isUnblocking = true);
    try {
      final provider = context.read<ChatProvider>();
      final ok = await provider.unblockUser(user.userId);
      if (!mounted) return;
      setState(() {
        _isUnblocking = false;
        if (ok) {
          _blocked.removeWhere((b) => b.userId == user.userId);
          showActionToast(context, t.blocked_users_unblocked);
        } else {
          _errorMessage = provider.errorMessage ?? t.error_something_wrong;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUnblocking = false;
        _errorMessage = t.error_something_wrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final errorColor = AppTheme.lightError;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          t.blocked_users_title,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _blocked.isEmpty
                ? _buildError(t, errorColor, onSurfaceColor)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _blocked.isEmpty
                        ? _buildEmpty(t, onSurfaceColor, textMutedColor)
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _blocked.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 72,
                              endIndent: 16,
                              color: borderColor.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (context, index) {
                              final user = _blocked[index];
                              return RepaintBoundary(
                                key: ValueKey(user.id),
                                child: _buildRow(context, user, t, isDark, onSurfaceColor, textMutedColor, borderColor, surfaceColor),
                              );
                            },
                          ),
                  ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, BlockedUser user, AppLocalizations t,
      bool isDark, Color onSurfaceColor, Color textMutedColor, Color borderColor, Color surfaceColor) {
    final age = user.age != null ? ' · ${user.age}' : '';
    final name = (user.name ?? '').isEmpty ? '—' : user.name!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        backgroundImage: user.mainPhotoUrl != null && user.mainPhotoUrl!.isNotEmpty
            ? CachedImage.provider(user.mainPhotoUrl!, diameter: 48)
            : null,
        child: (user.mainPhotoUrl == null || user.mainPhotoUrl!.isEmpty)
            ? Icon(Icons.person, color: textMutedColor)
            : null,
      ),
      title: Text(
        '$name$age',
        style: TextStyle(
          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurfaceColor,
        ),
      ),
      trailing: SizedBox(
        width: 92,
        height: 36,
        child: OutlinedButton(
          onPressed: _isUnblocking ? null : () => _confirmUnblock(user),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppTheme.darkError : AppTheme.lightError,
            side: BorderSide(color: isDark ? AppTheme.darkError : AppTheme.lightError),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            t.blocked_users_unblock,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t, Color onSurfaceColor, Color textMutedColor) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 56, color: textMutedColor.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  t.blocked_users_empty,
                  style: AppTheme.bodyLarge.copyWith(color: onSurfaceColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    t.blocked_users_empty_sub,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySmall.copyWith(color: textMutedColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations t, Color errorColor, Color onSurfaceColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 48, color: errorColor.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            _errorMessage == 'blocked_users_load_error'
                ? t.blocked_users_load_error
                : (_errorMessage ?? t.error_something_wrong),
            style: AppTheme.bodyLarge.copyWith(color: onSurfaceColor),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: Text(t.splash_retry)),
        ],
      ),
    );
  }
}
