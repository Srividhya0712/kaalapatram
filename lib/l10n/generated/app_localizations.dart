import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Kaalapatram'**
  String get appName;

  /// App tagline
  ///
  /// In en, this message translates to:
  /// **'Your Work Calendar & Network'**
  String get tagline;

  /// Welcome message on login
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// Login subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Forgot password button
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Signing in loading text
  ///
  /// In en, this message translates to:
  /// **'Signing In...'**
  String get signingIn;

  /// Divider text
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Register prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Calendar tab
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Network tab
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// Chats tab
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// Profile section
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Manage connections menu item
  ///
  /// In en, this message translates to:
  /// **'Manage Connections'**
  String get manageConnections;

  /// Notifications menu item
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Theme settings menu item
  ///
  /// In en, this message translates to:
  /// **'Theme & Appearance'**
  String get themeAppearance;

  /// Language settings menu item
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Feedback menu item
  ///
  /// In en, this message translates to:
  /// **'Feedback & Support'**
  String get feedbackSupport;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Delete account option
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account subtitle
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteAccount;

  /// Delete confirmation question
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountWarning;

  /// Delete info header
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete:'**
  String get deleteAccountInfo;

  /// Delete info item
  ///
  /// In en, this message translates to:
  /// **'Your profile and personal information'**
  String get yourProfile;

  /// Delete info item
  ///
  /// In en, this message translates to:
  /// **'All your events'**
  String get allEvents;

  /// Delete info item
  ///
  /// In en, this message translates to:
  /// **'All your connections'**
  String get allConnections;

  /// Delete info item
  ///
  /// In en, this message translates to:
  /// **'All your chat messages'**
  String get allMessages;

  /// Delete warning
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get cannotBeUndone;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete confirmation button
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// Deleting loading text
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deletingAccount;

  /// Delete success message
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get accountDeleted;

  /// My calendar title
  ///
  /// In en, this message translates to:
  /// **'My Calendar'**
  String get myCalendar;

  /// Network calendar title
  ///
  /// In en, this message translates to:
  /// **'Network Calendar'**
  String get networkCalendar;

  /// Calendar format month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Calendar format two weeks
  ///
  /// In en, this message translates to:
  /// **'2 Weeks'**
  String get twoWeeks;

  /// Calendar format week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// Add event button
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// Edit event title
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// Event details title
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// Time field label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Tamil date field label
  ///
  /// In en, this message translates to:
  /// **'Tamil Date'**
  String get tamilDate;

  /// Tamil date picker title
  ///
  /// In en, this message translates to:
  /// **'Select Tamil Date'**
  String get selectTamilDate;

  /// Day selection label
  ///
  /// In en, this message translates to:
  /// **'Select Day'**
  String get selectDay;

  /// Select button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Work details section
  ///
  /// In en, this message translates to:
  /// **'Work Details'**
  String get workDetails;

  /// Assigned by field
  ///
  /// In en, this message translates to:
  /// **'Assigned By'**
  String get assignedBy;

  /// Assigned by hint
  ///
  /// In en, this message translates to:
  /// **'Who assigned this work?'**
  String get whoAssigned;

  /// What to carry field
  ///
  /// In en, this message translates to:
  /// **'What to Carry'**
  String get whatToCarry;

  /// What to carry hint
  ///
  /// In en, this message translates to:
  /// **'List items to bring...'**
  String get listItems;

  /// Employer info section
  ///
  /// In en, this message translates to:
  /// **'Employer Info'**
  String get employerInfo;

  /// Employer name field
  ///
  /// In en, this message translates to:
  /// **'Employer Name'**
  String get employerName;

  /// Employer name hint
  ///
  /// In en, this message translates to:
  /// **'Name of the employer'**
  String get nameOfEmployer;

  /// Contact number field
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// Contact number hint
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// Payment section
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Amount field
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amount;

  /// Amount hint
  ///
  /// In en, this message translates to:
  /// **'Enter payment amount'**
  String get enterAmount;

  /// Save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Create event button
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// Delete event button
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

  /// Edit event button
  ///
  /// In en, this message translates to:
  /// **'Edit This Event'**
  String get editThisEvent;

  /// Event created message
  ///
  /// In en, this message translates to:
  /// **'Event created successfully'**
  String get eventCreated;

  /// Event updated message
  ///
  /// In en, this message translates to:
  /// **'Event updated successfully'**
  String get eventUpdated;

  /// Event deleted message
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventDeleted;

  /// Required field error
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No events message
  ///
  /// In en, this message translates to:
  /// **'No events for this day'**
  String get noEvents;

  /// Add event hint
  ///
  /// In en, this message translates to:
  /// **'Tap + to add an event'**
  String get tapToAdd;

  /// Connections title
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// Pending tab
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Accepted status
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Send connection request button
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// Accept button
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Reject button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Connected status
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No connections message
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get noConnections;

  /// Search users placeholder
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// Messages title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No chats message
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChats;

  /// No chats hint
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with your connections'**
  String get startConversation;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Edit profile button
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Profession field
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profession;

  /// Bio field
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Profile updated message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// Quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Edit profile subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// Manage connections subtitle
  ///
  /// In en, this message translates to:
  /// **'Add or remove connections'**
  String get addRemoveConnections;

  /// Notification settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage notification settings'**
  String get manageNotifications;

  /// Privacy settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Control your privacy preferences'**
  String get controlPrivacy;

  /// App tour menu item
  ///
  /// In en, this message translates to:
  /// **'View App Tour'**
  String get viewAppTour;

  /// App tour subtitle
  ///
  /// In en, this message translates to:
  /// **'Learn how to use the app'**
  String get learnHowToUse;

  /// Tour reset message
  ///
  /// In en, this message translates to:
  /// **'Tour reset! Switch tabs to see the tour again.'**
  String get tourReset;

  /// Privacy settings menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// Notification settings menu item
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// Sign out error message
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out'**
  String get failedToSignOut;

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get passwordResetSent;

  /// Email required message
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address first'**
  String get pleaseEnterEmail;

  /// Invalid email message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// Password length error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
