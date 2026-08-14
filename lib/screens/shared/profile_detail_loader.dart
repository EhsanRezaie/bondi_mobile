import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/services/chat_service.dart';

/// Fetches a user's full profile ([userId]) via GET /users/{user_id} and then
/// builds the detail widget through [builder]. Used when a discover/search card
/// is tapped: the list only carries slim card data, so the full profile is
/// hydrated on demand (cached via dio_cache_interceptor).
class ProfileDetailLoader extends StatefulWidget {
  final String userId;
  final Widget Function(DiscoverProfile profile) builder;

  const ProfileDetailLoader({
    super.key,
    required this.userId,
    required this.builder,
  });

  @override
  State<ProfileDetailLoader> createState() => _ProfileDetailLoaderState();
}

class _ProfileDetailLoaderState extends State<ProfileDetailLoader> {
  DiscoverProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ChatService.getPublicProfile(widget.userId);
      if (response.statusCode == 200 && response.data != null) {
        final profile = await compute(_parseProfile, response.data);
        if (mounted) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _error = 'not_found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  t.error_something_wrong,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 15,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text(t.discover_try_again),
              ),
            ],
          ),
        ),
      );
    }

    return widget.builder(_profile!);
  }
}

DiscoverProfile _parseProfile(dynamic data) =>
    DiscoverProfile.fromJson(data as Map<String, dynamic>);