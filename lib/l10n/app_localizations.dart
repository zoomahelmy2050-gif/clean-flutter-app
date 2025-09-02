import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Security Center'**
  String get appTitle;

  /// Welcome back message
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Login page subtitle
  ///
  /// In en, this message translates to:
  /// **'Log in to your account to continue'**
  String get loginSubtitle;

  /// Username or email field label
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get usernameOrEmail;

  /// Email validation message
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmailValidation;

  /// Password validation message
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPasswordValidation;

  /// Remember me checkbox label
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Phone sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get signInWithPhone;

  /// Backup code login button
  ///
  /// In en, this message translates to:
  /// **'Use a backup code'**
  String get useBackupCode;

  /// Sign up prompt text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Or divider text
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Create account title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Name field validation
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// Account settings tab title
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// 2FA settings label
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// Biometric authentication option
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// Backup codes option
  ///
  /// In en, this message translates to:
  /// **'Backup Codes'**
  String get backupCodes;

  /// Generate backup codes button
  ///
  /// In en, this message translates to:
  /// **'Generate Codes'**
  String get generateCodes;

  /// View backup codes button
  ///
  /// In en, this message translates to:
  /// **'View Codes'**
  String get viewCodes;

  /// Export data button
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Change language button
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Dashboard page title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Analytics section title
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Reports section title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Security overview section title
  ///
  /// In en, this message translates to:
  /// **'Security Overview'**
  String get securityOverview;

  /// Threat level indicator
  ///
  /// In en, this message translates to:
  /// **'Threat Level'**
  String get threatLevel;

  /// Active threats count
  ///
  /// In en, this message translates to:
  /// **'Active Threats'**
  String get activeThreats;

  /// Secured devices count
  ///
  /// In en, this message translates to:
  /// **'Secured Devices'**
  String get securedDevices;

  /// Last scan timestamp
  ///
  /// In en, this message translates to:
  /// **'Last Scan'**
  String get lastScan;

  /// Run scan button
  ///
  /// In en, this message translates to:
  /// **'Run Scan'**
  String get runScan;

  /// View details button
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Low threat level
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// Medium threat level
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// High threat level
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Critical threat level
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Reset password button text
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Send reset link button text
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Back to login link text
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Enter email placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Enter password placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Enter new password placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Security tab label
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Security Hub page title
  ///
  /// In en, this message translates to:
  /// **'Security Hub'**
  String get securityHub;

  /// Security Center page title
  ///
  /// In en, this message translates to:
  /// **'Security Center'**
  String get securityCenter;

  /// Threat monitoring section title
  ///
  /// In en, this message translates to:
  /// **'Threat Monitoring'**
  String get threatMonitoring;

  /// User management section title
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// TOTP authentication option
  ///
  /// In en, this message translates to:
  /// **'TOTP Authentication'**
  String get totpAuth;

  /// Email OTP option
  ///
  /// In en, this message translates to:
  /// **'Email OTP'**
  String get emailOtp;

  /// Change password option
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Active sessions option
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// Security alerts option
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get securityAlerts;

  /// Account recovery option
  ///
  /// In en, this message translates to:
  /// **'Account Recovery'**
  String get accountRecovery;

  /// Personal information section
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Help center section
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Send feedback option
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Enable button text
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// Disable button text
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message prefix
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning message prefix
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Information message prefix
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter button text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort button text
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Export button text
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Import button text
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Paste button text
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Cut button text
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// Select all button text
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Reset button text
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Upgrade button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// Download button text
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Upload button text
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Sync button text
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// Backup button text
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// Restore button text
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us today and protect your data'**
  String get signupSubtitle;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signupWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signupWithGoogle;

  /// No description provided for @nameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get nameValidation;

  /// No description provided for @emailValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get emailValidation;

  /// No description provided for @passwordValidation.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordValidation;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered. Please log in.'**
  String get emailAlreadyRegistered;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to register user.'**
  String get registrationFailed;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email'**
  String get verificationEmailSent;

  /// No description provided for @googleAccountNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Google account not registered. Please sign up first.'**
  String get googleAccountNotRegistered;

  /// No description provided for @goToSignup.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign up'**
  String get goToSignup;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountNotFound;

  /// No description provided for @googleSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign up failed'**
  String get googleSignupFailed;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset code'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset code sent to your email.'**
  String get resetCodeSent;

  /// No description provided for @failedToSendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get failedToSendCode;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {email}'**
  String enterCodeSentTo(Object email);

  /// No description provided for @securityKey.
  ///
  /// In en, this message translates to:
  /// **'Security Key'**
  String get securityKey;

  /// No description provided for @ensureKeyMatches.
  ///
  /// In en, this message translates to:
  /// **'Ensure this key matches the one in your email to avoid phishing.'**
  String get ensureKeyMatches;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resending.
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get resending;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(Object seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get invalidOrExpiredCode;

  /// No description provided for @otpResentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP re-sent to {email}'**
  String otpResentTo(Object email);

  /// No description provided for @failedToResend.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend: {error}'**
  String failedToResend(Object error);

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @environmentalCenter.
  ///
  /// In en, this message translates to:
  /// **'Environmental Center'**
  String get environmentalCenter;

  /// No description provided for @sensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensors;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @dailyGreenGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Green Goal'**
  String get dailyGreenGoal;

  /// No description provided for @scanWaste.
  ///
  /// In en, this message translates to:
  /// **'Scan Waste'**
  String get scanWaste;

  /// No description provided for @logCommute.
  ///
  /// In en, this message translates to:
  /// **'Log Commute'**
  String get logCommute;

  /// No description provided for @energyTips.
  ///
  /// In en, this message translates to:
  /// **'Energy Tips'**
  String get energyTips;

  /// No description provided for @liveMetrics.
  ///
  /// In en, this message translates to:
  /// **'Live Metrics'**
  String get liveMetrics;

  /// No description provided for @airQualityIndex.
  ///
  /// In en, this message translates to:
  /// **'Air Quality Index'**
  String get airQualityIndex;

  /// No description provided for @energyUsage.
  ///
  /// In en, this message translates to:
  /// **'Energy Usage'**
  String get energyUsage;

  /// No description provided for @energyOverTime.
  ///
  /// In en, this message translates to:
  /// **'Energy Over Time'**
  String get energyOverTime;

  /// No description provided for @exportImage.
  ///
  /// In en, this message translates to:
  /// **'Export image'**
  String get exportImage;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported'**
  String get csvExported;

  /// No description provided for @chartImageExported.
  ///
  /// In en, this message translates to:
  /// **'Chart image exported'**
  String get chartImageExported;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @energySourceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Energy Source Breakdown'**
  String get energySourceBreakdown;

  /// No description provided for @solar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get solar;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Avg (MA)'**
  String get average;

  /// No description provided for @goodThreshold.
  ///
  /// In en, this message translates to:
  /// **'Good threshold'**
  String get goodThreshold;

  /// No description provided for @zoomPan.
  ///
  /// In en, this message translates to:
  /// **'Zoom/Pan'**
  String get zoomPan;

  /// No description provided for @reducePlastics.
  ///
  /// In en, this message translates to:
  /// **'Reduce single-use plastics'**
  String get reducePlastics;

  /// No description provided for @reducePlasticsBody.
  ///
  /// In en, this message translates to:
  /// **'Carry a reusable bottle and bag.'**
  String get reducePlasticsBody;

  /// No description provided for @saveEnergyHome.
  ///
  /// In en, this message translates to:
  /// **'Save energy at home'**
  String get saveEnergyHome;

  /// No description provided for @saveEnergyHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Switch to LED and unplug idle devices.'**
  String get saveEnergyHomeBody;

  /// No description provided for @greenerCommute.
  ///
  /// In en, this message translates to:
  /// **'Greener commute'**
  String get greenerCommute;

  /// No description provided for @greenerCommuteBody.
  ///
  /// In en, this message translates to:
  /// **'Walk, cycle, or use public transport when possible.'**
  String get greenerCommuteBody;

  /// No description provided for @biometricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device.'**
  String get biometricsNotAvailable;

  /// No description provided for @biometricSigninEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in enabled.'**
  String get biometricSigninEnabled;

  /// No description provided for @biometricEnrollmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Biometric enrollment cancelled.'**
  String get biometricEnrollmentCancelled;

  /// No description provided for @biometricSigninDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in disabled.'**
  String get biometricSigninDisabled;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to logout'**
  String get logoutFailed;

  /// No description provided for @failedToOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Failed to open {pageName}'**
  String failedToOpenPage(Object pageName);

  /// No description provided for @securityVerification.
  ///
  /// In en, this message translates to:
  /// **'Security Verification'**
  String get securityVerification;

  /// No description provided for @securityHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account security'**
  String get securityHubSubtitle;

  /// No description provided for @securityScore.
  ///
  /// In en, this message translates to:
  /// **'Security Score: {score}%'**
  String securityScore(Object score);

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @accountStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is secure'**
  String get accountStatusSubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @personalInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your profile details'**
  String get personalInformationSubtitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsSubtitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize app appearance'**
  String get appearanceSubtitle;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get helpCenterSubtitle;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts and feedback'**
  String get sendFeedbackSubtitle;

  /// No description provided for @vulnerabilityScanning.
  ///
  /// In en, this message translates to:
  /// **'Vulnerability Scanning'**
  String get vulnerabilityScanning;

  /// No description provided for @userBehaviorAnalytics.
  ///
  /// In en, this message translates to:
  /// **'User Behavior Analytics'**
  String get userBehaviorAnalytics;

  /// No description provided for @auditTrail.
  ///
  /// In en, this message translates to:
  /// **'Audit Trail'**
  String get auditTrail;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @summaryEmails.
  ///
  /// In en, this message translates to:
  /// **'Summary Emails'**
  String get summaryEmails;

  /// No description provided for @roleManagement.
  ///
  /// In en, this message translates to:
  /// **'Role Management'**
  String get roleManagement;

  /// No description provided for @sessionSettings.
  ///
  /// In en, this message translates to:
  /// **'Session Settings'**
  String get sessionSettings;

  /// No description provided for @databaseMigration.
  ///
  /// In en, this message translates to:
  /// **'Database Migration'**
  String get databaseMigration;

  /// No description provided for @realTimeMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Real-time Monitoring'**
  String get realTimeMonitoring;

  /// No description provided for @securityAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Security Analytics'**
  String get securityAnalytics;

  /// No description provided for @threatIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Threat Intelligence'**
  String get threatIntelligence;

  /// No description provided for @userRiskScoring.
  ///
  /// In en, this message translates to:
  /// **'User Risk Scoring'**
  String get userRiskScoring;

  /// No description provided for @complianceReporting.
  ///
  /// In en, this message translates to:
  /// **'Compliance Reporting'**
  String get complianceReporting;

  /// No description provided for @securityIncidentResponse.
  ///
  /// In en, this message translates to:
  /// **'Security Incident Response'**
  String get securityIncidentResponse;

  /// No description provided for @userActivity.
  ///
  /// In en, this message translates to:
  /// **'User Activity'**
  String get userActivity;

  /// No description provided for @advancedServices.
  ///
  /// In en, this message translates to:
  /// **'Advanced Services'**
  String get advancedServices;

  /// No description provided for @quantumCrypto.
  ///
  /// In en, this message translates to:
  /// **'Quantum Crypto'**
  String get quantumCrypto;

  /// No description provided for @complianceAutomation.
  ///
  /// In en, this message translates to:
  /// **'Compliance Automation'**
  String get complianceAutomation;

  /// No description provided for @mdmDashboard.
  ///
  /// In en, this message translates to:
  /// **'MDM Dashboard'**
  String get mdmDashboard;

  /// No description provided for @forensicsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Forensics Dashboard'**
  String get forensicsDashboard;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOtpCode;

  /// No description provided for @totpSetup.
  ///
  /// In en, this message translates to:
  /// **'TOTP Setup'**
  String get totpSetup;

  /// No description provided for @totpVerification.
  ///
  /// In en, this message translates to:
  /// **'TOTP Verification'**
  String get totpVerification;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @enterTotpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter TOTP Code'**
  String get enterTotpCode;

  /// No description provided for @backupCodeLogin.
  ///
  /// In en, this message translates to:
  /// **'Backup Code Login'**
  String get backupCodeLogin;

  /// No description provided for @enterBackupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Backup Code'**
  String get enterBackupCode;

  /// No description provided for @phoneLogin.
  ///
  /// In en, this message translates to:
  /// **'Phone Login'**
  String get phoneLogin;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone Number'**
  String get enterPhoneNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @securitySetup.
  ///
  /// In en, this message translates to:
  /// **'Security Setup'**
  String get securitySetup;

  /// No description provided for @setupSecurityMethods.
  ///
  /// In en, this message translates to:
  /// **'Setup Security Methods'**
  String get setupSecurityMethods;

  /// No description provided for @authenticatorApp.
  ///
  /// In en, this message translates to:
  /// **'Authenticator App'**
  String get authenticatorApp;

  /// No description provided for @passkeys.
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeys;

  /// No description provided for @securityAccountCenter.
  ///
  /// In en, this message translates to:
  /// **'Security Account Center'**
  String get securityAccountCenter;

  /// No description provided for @analyticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Analytics Overview'**
  String get analyticsOverview;

  /// No description provided for @usageDashboard.
  ///
  /// In en, this message translates to:
  /// **'Usage Dashboard'**
  String get usageDashboard;

  /// No description provided for @securityDashboard.
  ///
  /// In en, this message translates to:
  /// **'Security Dashboard'**
  String get securityDashboard;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @systemLogs.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get systemLogs;

  /// No description provided for @errorLogs.
  ///
  /// In en, this message translates to:
  /// **'Error Logs'**
  String get errorLogs;

  /// No description provided for @accessLogs.
  ///
  /// In en, this message translates to:
  /// **'Access Logs'**
  String get accessLogs;

  /// No description provided for @emailSettings.
  ///
  /// In en, this message translates to:
  /// **'Email Settings'**
  String get emailSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// No description provided for @dataImport.
  ///
  /// In en, this message translates to:
  /// **'Data Import'**
  String get dataImport;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @systemStatus.
  ///
  /// In en, this message translates to:
  /// **'System Status'**
  String get systemStatus;

  /// No description provided for @healthCheck.
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get healthCheck;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @resourceUsage.
  ///
  /// In en, this message translates to:
  /// **'Resource Usage'**
  String get resourceUsage;

  /// No description provided for @networkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get networkStatus;

  /// No description provided for @databaseStatus.
  ///
  /// In en, this message translates to:
  /// **'Database Status'**
  String get databaseStatus;

  /// No description provided for @serviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Service Status'**
  String get serviceStatus;

  /// No description provided for @alertsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Alerts & Notifications'**
  String get alertsNotifications;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Alerts'**
  String get criticalAlerts;

  /// No description provided for @warningAlerts.
  ///
  /// In en, this message translates to:
  /// **'Warning Alerts'**
  String get warningAlerts;

  /// No description provided for @infoAlerts.
  ///
  /// In en, this message translates to:
  /// **'Info Alerts'**
  String get infoAlerts;

  /// No description provided for @alertHistory.
  ///
  /// In en, this message translates to:
  /// **'Alert History'**
  String get alertHistory;

  /// No description provided for @notificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Notification History'**
  String get notificationHistory;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @smsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get smsNotifications;

  /// No description provided for @webhookNotifications.
  ///
  /// In en, this message translates to:
  /// **'Webhook Notifications'**
  String get webhookNotifications;

  /// No description provided for @slackNotifications.
  ///
  /// In en, this message translates to:
  /// **'Slack Notifications'**
  String get slackNotifications;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
