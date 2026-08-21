import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/providers/ticket_provider.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/widgets/action_toast.dart';

class CreateTicketScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialMessage;

  const CreateTicketScreen({
    super.key,
    this.initialSubject,
    this.initialMessage,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedSubjectValue;

  static const String _otherValue = 'Other';

  List<MapEntry<String, String>> _subjects(AppLocalizations t) => [
    MapEntry('Account / Login issue', t.ticket_subject_account),
    MapEntry('Photo verification', t.ticket_subject_photo),
    MapEntry('Payment / Premium', t.ticket_subject_payment),
    MapEntry('Report a problem (bug)', t.ticket_subject_bug),
    MapEntry(_otherValue, t.ticket_subject_other),
  ];

  bool get _isOther => _selectedSubjectValue == _otherValue;

  bool get _canSubmit =>
      _selectedSubjectValue != null &&
      _messageController.text.trim().length >= 10;

  @override
  void initState() {
    super.initState();
    _selectedSubjectValue = widget.initialSubject;
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final subject = _selectedSubjectValue;
    if (subject == null) return;

    final ok = await provider.createTicket(
      subject,
      _messageController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      showActionToast(context, AppLocalizations.of(context)!.ticket_created);
      Navigator.pop(context, true);
    } else {
      showActionToast(
        context,
        provider.errorMessage ??
            AppLocalizations.of(context)!.ticket_load_error,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          t.new_ticket,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<TicketProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              AppLayout.floatingNavClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubjectField(t, isDark, onSurfaceColor, textMutedColor),
                if (_isOther) ...[
                  const SizedBox(height: 12),
                  _buildOtherHint(t, isDark, primaryColor),
                ],
                const SizedBox(height: 24),
                Text(
                  t.ticket_message,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(isPersian),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMessageField(isDark, onSurfaceColor, textMutedColor),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !provider.isCreating
                        ? _submit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300.withValues(
                        alpha: 0.8,
                      ),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: provider.isCreating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            t.ticket_send,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFor(isPersian),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectField(
    AppLocalizations t,
    bool isDark,
    Color onSurfaceColor,
    Color textMutedColor,
  ) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.ticket_subject,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubjectValue,
              isExpanded: true,
              hint: Text(
                t.ticket_subject,
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(isPersian),
                  fontSize: 15,
                  color: textMutedColor,
                ),
              ),
              icon: Icon(Icons.arrow_drop_down, color: textMutedColor),
              items: _subjects(t)
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(isPersian),
                          fontSize: 15,
                          color: onSurfaceColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubjectValue = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherHint(AppLocalizations t, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.ticket_other_hint,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
                fontSize: 13,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageField(
    bool isDark,
    Color onSurfaceColor,
    Color textMutedColor,
  ) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 6,
        minLines: 4,
        maxLength: 2000,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontFamily: AppTheme.fontFor(
            !Localizations.localeOf(context).languageCode.contains('en'),
          ),
          fontSize: 15,
          color: onSurfaceColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: t.ticket_message_hint,
          hintStyle: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(context).languageCode.contains('en'),
            ),
            fontSize: 14,
            color: textMutedColor,
          ),
        ),
      ),
    );
  }
}
