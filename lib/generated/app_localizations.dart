import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Bondi'**
  String get app_title;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with people around you'**
  String get welcome_subtitle;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_label;

  /// No description provided for @sign_in_button.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in_button;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continue_with_google.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continue_with_google;

  /// No description provided for @dont_have_an_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dont_have_an_account;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @join_community_text.
  ///
  /// In en, this message translates to:
  /// **'Join a community of intentional individuals seeking meaningful relationships'**
  String get join_community_text;

  /// No description provided for @enter_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enter_email_hint;

  /// No description provided for @enter_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enter_password_hint;

  /// No description provided for @terms_and_policy.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get terms_and_policy;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get persian;

  /// No description provided for @sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sign_up;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sign_in;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get email_required;

  /// No description provided for @email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get email_invalid;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get password_required;

  /// No description provided for @password_min_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get password_min_length;

  /// No description provided for @splash_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Find Your Match'**
  String get splash_subtitle;

  /// No description provided for @splash_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to server...'**
  String get splash_connecting;

  /// No description provided for @splash_check_internet.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get splash_check_internet;

  /// No description provided for @splash_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get splash_retry;

  /// No description provided for @splash_connection_failed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get splash_connection_failed;

  /// No description provided for @screenshot_disabled_notice.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are disabled to protect your privacy'**
  String get screenshot_disabled_notice;

  /// No description provided for @photo_fullscreen_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap photo for full screen'**
  String get photo_fullscreen_hint;

  /// No description provided for @signup_title.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signup_title;

  /// No description provided for @signup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us and find your match'**
  String get signup_subtitle;

  /// No description provided for @signup_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signup_email_label;

  /// No description provided for @signup_password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signup_password_label;

  /// No description provided for @signup_confirm_password_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signup_confirm_password_label;

  /// No description provided for @signup_button.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup_button;

  /// No description provided for @signup_already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signup_already_have_account;

  /// No description provided for @signup_email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get signup_email_required;

  /// No description provided for @signup_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get signup_email_invalid;

  /// No description provided for @signup_password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get signup_password_required;

  /// No description provided for @signup_password_min_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get signup_password_min_length;

  /// No description provided for @signup_confirm_password_required.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get signup_confirm_password_required;

  /// No description provided for @signup_passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signup_passwords_do_not_match;

  /// No description provided for @signin_button.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signin_button;

  /// No description provided for @signup_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get signup_email_hint;

  /// No description provided for @signup_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get signup_password_hint;

  /// No description provided for @signup_confirm_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signup_confirm_password_hint;

  /// No description provided for @verify_title.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verify_title;

  /// No description provided for @verify_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to'**
  String get verify_subtitle;

  /// No description provided for @verify_code_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get verify_code_hint;

  /// No description provided for @verify_resend.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get verify_resend;

  /// No description provided for @verify_button.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verify_button;

  /// No description provided for @verify_referral_hint.
  ///
  /// In en, this message translates to:
  /// **'Referral code (optional)'**
  String get verify_referral_hint;

  /// No description provided for @verify_referral_bonus.
  ///
  /// In en, this message translates to:
  /// **'💡 Get 3 days of premium free with a referral code'**
  String get verify_referral_bonus;

  /// No description provided for @login_email_required.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get login_email_required;

  /// No description provided for @login_email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get login_email_invalid;

  /// No description provided for @login_password_required.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get login_password_required;

  /// No description provided for @login_password_invalid.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get login_password_invalid;

  /// No description provided for @verify_resend_success.
  ///
  /// In en, this message translates to:
  /// **'New verification code sent to your email'**
  String get verify_resend_success;

  /// No description provided for @verify_resend_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code'**
  String get verify_resend_failed;

  /// No description provided for @verify_code_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code'**
  String get verify_code_required;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settings_dark_mode;

  /// No description provided for @settings_dark_mode_desc.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme throughout the app'**
  String get settings_dark_mode_desc;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settings_privacy;

  /// No description provided for @settings_hide_last_seen.
  ///
  /// In en, this message translates to:
  /// **'Hide Last Seen'**
  String get settings_hide_last_seen;

  /// No description provided for @settings_hide_last_seen_desc.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show when you were last active'**
  String get settings_hide_last_seen_desc;

  /// No description provided for @settings_hide_online_status.
  ///
  /// In en, this message translates to:
  /// **'Hide Online Status'**
  String get settings_hide_online_status;

  /// No description provided for @settings_hide_online_status_desc.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show when you\'re online'**
  String get settings_hide_online_status_desc;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_push_notifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settings_push_notifications;

  /// No description provided for @settings_push_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications'**
  String get settings_push_notifications_desc;

  /// No description provided for @settings_like_notifications.
  ///
  /// In en, this message translates to:
  /// **'Like Notifications'**
  String get settings_like_notifications;

  /// No description provided for @settings_like_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone likes you'**
  String get settings_like_notifications_desc;

  /// No description provided for @settings_match_notifications.
  ///
  /// In en, this message translates to:
  /// **'Match Notifications'**
  String get settings_match_notifications;

  /// No description provided for @settings_match_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you get a match'**
  String get settings_match_notifications_desc;

  /// No description provided for @settings_message_notifications.
  ///
  /// In en, this message translates to:
  /// **'Message Notifications'**
  String get settings_message_notifications;

  /// No description provided for @settings_message_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you receive a message'**
  String get settings_message_notifications_desc;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_language_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settings_language_desc;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settings_logout;

  /// No description provided for @settings_logout_desc.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settings_logout_desc;

  /// No description provided for @settings_logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settings_logout_confirm;

  /// No description provided for @settings_premium_title.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get settings_premium_title;

  /// No description provided for @settings_premium_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited likes, chats and profile boosts'**
  String get settings_premium_subtitle;

  /// No description provided for @settings_premium_perk_likes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited likes'**
  String get settings_premium_perk_likes;

  /// No description provided for @settings_premium_perk_chats.
  ///
  /// In en, this message translates to:
  /// **'Unlimited chats'**
  String get settings_premium_perk_chats;

  /// No description provided for @settings_premium_perk_boost.
  ///
  /// In en, this message translates to:
  /// **'Profile boost'**
  String get settings_premium_perk_boost;

  /// No description provided for @settings_premium_cta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now'**
  String get settings_premium_cta;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifications_empty;

  /// No description provided for @notifications_section_liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get notifications_section_liked;

  /// No description provided for @notifications_section_likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get notifications_section_likes;

  /// No description provided for @notifications_section_matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get notifications_section_matches;

  /// No description provided for @notifications_section_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notifications_section_system;

  /// No description provided for @notifications_empty_section.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get notifications_empty_section;

  /// No description provided for @notifications_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get notifications_close;

  /// No description provided for @error_email_exists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get error_email_exists;

  /// No description provided for @error_email_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get error_email_invalid_format;

  /// No description provided for @error_too_many_attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment'**
  String get error_too_many_attempts;

  /// No description provided for @error_network.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet'**
  String get error_network;

  /// No description provided for @error_something_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get error_something_wrong;

  /// No description provided for @error_email_not_found.
  ///
  /// In en, this message translates to:
  /// **'Email not found. Please start over'**
  String get error_email_not_found;

  /// No description provided for @error_verification_failed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get error_verification_failed;

  /// No description provided for @error_invalid_code.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired verification code'**
  String get error_invalid_code;

  /// No description provided for @error_profile_complete_failed.
  ///
  /// In en, this message translates to:
  /// **'Profile completion failed'**
  String get error_profile_complete_failed;

  /// No description provided for @error_profile_already_complete.
  ///
  /// In en, this message translates to:
  /// **'Profile is already complete'**
  String get error_profile_already_complete;

  /// No description provided for @error_session_expired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again'**
  String get error_session_expired;

  /// No description provided for @error_invalid_data.
  ///
  /// In en, this message translates to:
  /// **'Invalid data provided'**
  String get error_invalid_data;

  /// No description provided for @error_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get error_login_failed;

  /// No description provided for @error_wrong_credentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get error_wrong_credentials;

  /// No description provided for @discover_title.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover_title;

  /// No description provided for @discover_loading.
  ///
  /// In en, this message translates to:
  /// **'Finding people near you...'**
  String get discover_loading;

  /// No description provided for @discover_no_profiles.
  ///
  /// In en, this message translates to:
  /// **'No more profiles'**
  String get discover_no_profiles;

  /// No description provided for @discover_no_profiles_hint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get discover_no_profiles_hint;

  /// No description provided for @discover_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get discover_try_again;

  /// No description provided for @discover_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get discover_refresh;

  /// No description provided for @discover_widen_title.
  ///
  /// In en, this message translates to:
  /// **'No one found nearby'**
  String get discover_widen_title;

  /// No description provided for @discover_widen_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Try widening your search'**
  String get discover_widen_subtitle;

  /// No description provided for @discover_widen_distance.
  ///
  /// In en, this message translates to:
  /// **'+{km} km'**
  String discover_widen_distance(Object km);

  /// No description provided for @discover_widen_age.
  ///
  /// In en, this message translates to:
  /// **'+{years} years'**
  String discover_widen_age(Object years);

  /// No description provided for @discover_limit_reached_title.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get discover_limit_reached_title;

  /// No description provided for @discover_limit_reached_likes.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your likes today. Come back tomorrow!'**
  String get discover_limit_reached_likes;

  /// No description provided for @discover_limit_reached_chats.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your chats today. Come back tomorrow!'**
  String get discover_limit_reached_chats;

  /// No description provided for @discover_say_something.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get discover_say_something;

  /// No description provided for @discover_send_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Send a message with your like...'**
  String get discover_send_message_hint;

  /// No description provided for @discover_send_and_like.
  ///
  /// In en, this message translates to:
  /// **'Send & Like'**
  String get discover_send_and_like;

  /// No description provided for @discover_match_title.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match!'**
  String get discover_match_title;

  /// No description provided for @discover_match_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You and {name} liked each other'**
  String discover_match_subtitle(Object name);

  /// No description provided for @discover_match_message_sent.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent!'**
  String get discover_match_message_sent;

  /// No description provided for @discover_send_message.
  ///
  /// In en, this message translates to:
  /// **'Send a Message'**
  String get discover_send_message;

  /// No description provided for @discover_keep_swiping.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get discover_keep_swiping;

  /// No description provided for @discover_filter_all.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get discover_filter_all;

  /// No description provided for @discover_filter_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get discover_filter_male;

  /// No description provided for @discover_filter_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get discover_filter_female;

  /// No description provided for @discover_filter_show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get discover_filter_show;

  /// No description provided for @discover_filter_age_range.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get discover_filter_age_range;

  /// No description provided for @discover_filter_years.
  ///
  /// In en, this message translates to:
  /// **'{min} - {max} years'**
  String discover_filter_years(Object max, Object min);

  /// No description provided for @discover_filter_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get discover_filter_apply;

  /// No description provided for @discover_filter_max_distance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get discover_filter_max_distance;

  /// No description provided for @discover_filter_km.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String discover_filter_km(Object distance);

  /// No description provided for @discover_km_away.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String discover_km_away(Object distance);

  /// No description provided for @discover_tap_for_more.
  ///
  /// In en, this message translates to:
  /// **'Tap for more'**
  String get discover_tap_for_more;

  /// No description provided for @discover_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get discover_premium;

  /// No description provided for @discover_revert_pass.
  ///
  /// In en, this message translates to:
  /// **'Revert last pass'**
  String get discover_revert_pass;

  /// No description provided for @profile_section_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_section_about;

  /// No description provided for @profile_section_physical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get profile_section_physical;

  /// No description provided for @profile_section_lifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get profile_section_lifestyle;

  /// No description provided for @profile_section_background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get profile_section_background;

  /// No description provided for @profile_section_languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profile_section_languages;

  /// No description provided for @profile_section_interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profile_section_interests;

  /// No description provided for @profile_section_prompts.
  ///
  /// In en, this message translates to:
  /// **'Prompts'**
  String get profile_section_prompts;

  /// No description provided for @profile_label_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profile_label_height;

  /// No description provided for @profile_label_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profile_label_weight;

  /// No description provided for @profile_label_body_type.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get profile_label_body_type;

  /// No description provided for @profile_label_relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get profile_label_relationship;

  /// No description provided for @profile_label_living_situation.
  ///
  /// In en, this message translates to:
  /// **'Living Situation'**
  String get profile_label_living_situation;

  /// No description provided for @profile_label_children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get profile_label_children;

  /// No description provided for @profile_label_smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get profile_label_smoking;

  /// No description provided for @profile_label_drinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get profile_label_drinking;

  /// No description provided for @profile_label_education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profile_label_education;

  /// No description provided for @profile_label_work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get profile_label_work;

  /// No description provided for @profile_label_religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get profile_label_religion;

  /// No description provided for @profile_label_ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get profile_label_ethnicity;

  /// No description provided for @profile_label_politics.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get profile_label_politics;

  /// No description provided for @search_title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_title;

  /// No description provided for @search_loading.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get search_loading;

  /// No description provided for @search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get search_no_results;

  /// No description provided for @search_no_results_hint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get search_no_results_hint;

  /// No description provided for @search_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get search_filters;

  /// No description provided for @search_advanced_filters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get search_advanced_filters;

  /// No description provided for @search_apply_filters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get search_apply_filters;

  /// No description provided for @search_reset_filters.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get search_reset_filters;

  /// No description provided for @search_sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get search_sort_by;

  /// No description provided for @search_sort_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get search_sort_recent;

  /// No description provided for @search_sort_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get search_sort_distance;

  /// No description provided for @search_sort_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get search_sort_age;

  /// No description provided for @search_sort_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get search_sort_name;

  /// No description provided for @search_sort_last_seen.
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get search_sort_last_seen;

  /// No description provided for @search_filter_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get search_filter_location;

  /// No description provided for @search_filter_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get search_filter_country;

  /// No description provided for @search_filter_province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get search_filter_province;

  /// No description provided for @search_filter_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get search_filter_city;

  /// No description provided for @search_filter_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get search_filter_height;

  /// No description provided for @search_filter_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get search_filter_weight;

  /// No description provided for @search_filter_body_type.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get search_filter_body_type;

  /// No description provided for @search_filter_relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get search_filter_relationship;

  /// No description provided for @search_filter_education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get search_filter_education;

  /// No description provided for @search_filter_smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get search_filter_smoking;

  /// No description provided for @search_filter_drinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get search_filter_drinking;

  /// No description provided for @search_filter_political.
  ///
  /// In en, this message translates to:
  /// **'Political'**
  String get search_filter_political;

  /// No description provided for @search_filter_children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get search_filter_children;

  /// No description provided for @search_filter_living.
  ///
  /// In en, this message translates to:
  /// **'Living Situation'**
  String get search_filter_living;

  /// No description provided for @search_filter_religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get search_filter_religion;

  /// No description provided for @search_filter_ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get search_filter_ethnicity;

  /// No description provided for @search_filter_interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get search_filter_interests;

  /// No description provided for @search_filter_languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get search_filter_languages;

  /// No description provided for @search_filter_has_photos.
  ///
  /// In en, this message translates to:
  /// **'Has Photos'**
  String get search_filter_has_photos;

  /// No description provided for @search_filter_verified.
  ///
  /// In en, this message translates to:
  /// **'Verified Only'**
  String get search_filter_verified;

  /// No description provided for @search_filter_age_range.
  ///
  /// In en, this message translates to:
  /// **'Age Range'**
  String get search_filter_age_range;

  /// No description provided for @search_filter_distance_km.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get search_filter_distance_km;

  /// No description provided for @search_filter_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get search_filter_gender;

  /// No description provided for @search_page.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String search_page(Object current, Object total);

  /// No description provided for @search_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get search_next;

  /// No description provided for @search_prev.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get search_prev;

  /// No description provided for @search_active_filters.
  ///
  /// In en, this message translates to:
  /// **'{count} filters'**
  String search_active_filters(Object count);

  /// No description provided for @search_limit_reached_likes.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your likes today. Come back tomorrow!'**
  String get search_limit_reached_likes;

  /// No description provided for @search_limit_reached_chats.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your chats today. Come back tomorrow!'**
  String get search_limit_reached_chats;

  /// No description provided for @search_say_something.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get search_say_something;

  /// No description provided for @search_send_and_like.
  ///
  /// In en, this message translates to:
  /// **'Send & Like'**
  String get search_send_and_like;

  /// No description provided for @search_match_title.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match!'**
  String get search_match_title;

  /// No description provided for @search_match_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You and {name} liked each other'**
  String search_match_subtitle(Object name);

  /// No description provided for @search_match_message_sent.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent!'**
  String get search_match_message_sent;

  /// No description provided for @search_send_message.
  ///
  /// In en, this message translates to:
  /// **'Send a Message'**
  String get search_send_message;

  /// No description provided for @search_continue_browsing.
  ///
  /// In en, this message translates to:
  /// **'Continue Browsing'**
  String get search_continue_browsing;

  /// No description provided for @search_tap_for_details.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get search_tap_for_details;

  /// No description provided for @search_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get search_premium;

  /// No description provided for @search_verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get search_verified;

  /// No description provided for @chat_liked_me.
  ///
  /// In en, this message translates to:
  /// **'Liked Me'**
  String get chat_liked_me;

  /// No description provided for @chat_i_liked.
  ///
  /// In en, this message translates to:
  /// **'I Liked'**
  String get chat_i_liked;

  /// No description provided for @chat_chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chat_chats;

  /// No description provided for @chat_requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get chat_requests;

  /// No description provided for @chat_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get chat_pending;

  /// No description provided for @chat_incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get chat_incoming;

  /// No description provided for @chat_empty_pending.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t started any chats yet'**
  String get chat_empty_pending;

  /// No description provided for @chat_empty_incoming.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any incoming chats yet'**
  String get chat_empty_incoming;

  /// No description provided for @chat_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get chat_accept;

  /// Notification: someone liked you
  ///
  /// In en, this message translates to:
  /// **'{name} liked you'**
  String chat_liked_you(String name);

  /// Notification: you liked someone
  ///
  /// In en, this message translates to:
  /// **'You liked {name}'**
  String chat_you_liked(String name);

  /// No description provided for @time_just_now.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get time_just_now;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String time_minutes_ago(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String time_hours_ago(int count);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String time_days_ago(int count);

  /// No description provided for @chat_empty_matches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Start swiping!'**
  String get chat_empty_matches;

  /// No description provided for @chat_empty_liked_me.
  ///
  /// In en, this message translates to:
  /// **'No one has liked you yet'**
  String get chat_empty_liked_me;

  /// No description provided for @chat_empty_i_liked.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t liked anyone yet'**
  String get chat_empty_i_liked;

  /// No description provided for @chat_empty_chats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chat_empty_chats;

  /// No description provided for @chat_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chat_online;

  /// No description provided for @chat_last_seen_minutes.
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes}m ago'**
  String chat_last_seen_minutes(Object minutes);

  /// No description provided for @chat_last_seen_hours.
  ///
  /// In en, this message translates to:
  /// **'Last seen {hours}h ago'**
  String chat_last_seen_hours(Object hours);

  /// No description provided for @chat_last_seen_days.
  ///
  /// In en, this message translates to:
  /// **'Last seen {days}d ago'**
  String chat_last_seen_days(Object days);

  /// No description provided for @chat_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chat_offline;

  /// No description provided for @chat_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chat_send;

  /// No description provided for @chat_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chat_reply;

  /// No description provided for @chat_voice_message.
  ///
  /// In en, this message translates to:
  /// **'Voice Message'**
  String get chat_voice_message;

  /// No description provided for @chat_photo_message.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chat_photo_message;

  /// No description provided for @chat_typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get chat_typing;

  /// No description provided for @chat_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chat_edit;

  /// No description provided for @chat_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chat_delete;

  /// No description provided for @chat_delete_for_me.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chat_delete_for_me;

  /// No description provided for @chat_delete_for_everyone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chat_delete_for_everyone;

  /// No description provided for @chat_edit_message.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chat_edit_message;

  /// No description provided for @chat_message_reported.
  ///
  /// In en, this message translates to:
  /// **'Message reported'**
  String get chat_message_reported;

  /// No description provided for @chat_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Daily chat limit reached'**
  String get chat_limit_reached;

  /// No description provided for @chat_limit_explanation.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all your chats today. Come back tomorrow!'**
  String get chat_limit_explanation;

  /// No description provided for @chat_unmatched.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chat_unmatched;

  /// No description provided for @chat_initiation_limit.
  ///
  /// In en, this message translates to:
  /// **'Message limit'**
  String get chat_initiation_limit;

  /// No description provided for @chat_initiation_limit_explanation.
  ///
  /// In en, this message translates to:
  /// **'Send up to 2 messages. Wait for a reply to continue chatting.'**
  String get chat_initiation_limit_explanation;

  /// No description provided for @chat_waiting_for_reply.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reply...'**
  String get chat_waiting_for_reply;

  /// Title above the Accept button in a pending chat for the recipient
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a chat request'**
  String chat_accept_title(String name);

  /// Shown to the initiator of a pending chat who has used the 2-message limit
  ///
  /// In en, this message translates to:
  /// **'You can\'t send more messages until {name} accepts your chat.'**
  String chat_waiting_accept(String name);

  /// Shown when a chat has been blocked or ended by the other user
  ///
  /// In en, this message translates to:
  /// **'This conversation with {name} is over.'**
  String chat_conversation_over(String name);

  /// No description provided for @chat_error_loading.
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Please try again.'**
  String get chat_error_loading;

  /// No description provided for @chat_error_sending.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get chat_error_sending;

  /// No description provided for @chat_error_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chat_error_retry;

  /// No description provided for @chat_voice_max_duration.
  ///
  /// In en, this message translates to:
  /// **'Max 120 seconds'**
  String get chat_voice_max_duration;

  /// No description provided for @chat_voice_recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get chat_voice_recording;

  /// No description provided for @chat_voice_playing.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get chat_voice_playing;

  /// No description provided for @chat_image_preview.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chat_image_preview;

  /// No description provided for @chat_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get chat_loading;

  /// No description provided for @chat_loading_more.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get chat_loading_more;

  /// No description provided for @chat_delete_message.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chat_delete_message;

  /// No description provided for @chat_forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chat_forward;

  /// No description provided for @chat_matched_at.
  ///
  /// In en, this message translates to:
  /// **'Matched {time}'**
  String chat_matched_at(Object time);

  /// No description provided for @toast_like_sent.
  ///
  /// In en, this message translates to:
  /// **'Like sent!'**
  String get toast_like_sent;

  /// No description provided for @toast_like_and_message_sent.
  ///
  /// In en, this message translates to:
  /// **'Like and message sent!'**
  String get toast_like_and_message_sent;

  /// No description provided for @profile_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profile_updated_success;

  /// No description provided for @interests_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Interests updated successfully!'**
  String get interests_updated_success;

  /// No description provided for @photos_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Photos updated successfully'**
  String get photos_updated_success;

  /// No description provided for @photo_cropped_success.
  ///
  /// In en, this message translates to:
  /// **'Profile picture cropped successfully'**
  String get photo_cropped_success;

  /// No description provided for @photo_crop_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save crop'**
  String get photo_crop_failed;

  /// No description provided for @photo_crop_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String photo_crop_error(String error);

  /// No description provided for @prompts_updated_success.
  ///
  /// In en, this message translates to:
  /// **'Prompts updated successfully!'**
  String get prompts_updated_success;

  /// No description provided for @upload_profile_picture_first.
  ///
  /// In en, this message translates to:
  /// **'Please upload a profile picture first'**
  String get upload_profile_picture_first;

  /// No description provided for @face_verification_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Face verification coming soon!'**
  String get face_verification_coming_soon;

  /// No description provided for @photo_rejected_reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String photo_rejected_reason(String reason);

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @my_tickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get my_tickets;

  /// No description provided for @new_ticket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get new_ticket;

  /// No description provided for @ticket_subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get ticket_subject;

  /// No description provided for @ticket_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get ticket_message;

  /// No description provided for @ticket_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue in detail (at least 10 characters)'**
  String get ticket_message_hint;

  /// No description provided for @ticket_reply_hint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get ticket_reply_hint;

  /// No description provided for @ticket_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get ticket_send;

  /// No description provided for @ticket_status_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticket_status_open;

  /// No description provided for @ticket_status_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ticket_status_in_progress;

  /// No description provided for @ticket_status_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticket_status_closed;

  /// No description provided for @ticket_subject_account.
  ///
  /// In en, this message translates to:
  /// **'Account / Login issue'**
  String get ticket_subject_account;

  /// No description provided for @ticket_subject_photo.
  ///
  /// In en, this message translates to:
  /// **'Photo verification'**
  String get ticket_subject_photo;

  /// No description provided for @ticket_subject_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment / Premium'**
  String get ticket_subject_payment;

  /// No description provided for @ticket_subject_bug.
  ///
  /// In en, this message translates to:
  /// **'Report a problem (bug)'**
  String get ticket_subject_bug;

  /// No description provided for @ticket_subject_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ticket_subject_other;

  /// No description provided for @ticket_other_hint.
  ///
  /// In en, this message translates to:
  /// **'Selecting “Other”? Explain your issue in the message below.'**
  String get ticket_other_hint;

  /// No description provided for @ticket_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get ticket_empty_title;

  /// No description provided for @ticket_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Have an issue? Create a support ticket and our team will help you.'**
  String get ticket_empty_body;

  /// No description provided for @ticket_create_first.
  ///
  /// In en, this message translates to:
  /// **'Create your first ticket'**
  String get ticket_create_first;

  /// No description provided for @ticket_created.
  ///
  /// In en, this message translates to:
  /// **'Ticket created'**
  String get ticket_created;

  /// No description provided for @ticket_reply_sent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get ticket_reply_sent;

  /// No description provided for @ticket_closed_note.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed. Sending a message will reopen it.'**
  String get ticket_closed_note;

  /// No description provided for @ticket_support_team.
  ///
  /// In en, this message translates to:
  /// **'Support Team'**
  String get ticket_support_team;

  /// No description provided for @ticket_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get ticket_you;

  /// No description provided for @ticket_load_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tickets. Pull to refresh.'**
  String get ticket_load_error;

  /// No description provided for @notifications_see_details.
  ///
  /// In en, this message translates to:
  /// **'See details'**
  String get notifications_see_details;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
