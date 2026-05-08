import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt Scanner'**
  String get appTitle;

  /// No description provided for @poweredByGemini.
  ///
  /// In en, this message translates to:
  /// **'Powered by Gemini AI'**
  String get poweredByGemini;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @trackYourSpending.
  ///
  /// In en, this message translates to:
  /// **'Track Your Spending'**
  String get trackYourSpending;

  /// No description provided for @trackYourSpendingBody.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save your receipts and see daily, weekly, monthly and yearly spending breakdowns.'**
  String get trackYourSpendingBody;

  /// No description provided for @signUpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign Up / Sign In'**
  String get signUpSignIn;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signUpFree.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Free'**
  String get signUpFree;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @saveAndTrackSpending.
  ///
  /// In en, this message translates to:
  /// **'Save & Track Your Spending'**
  String get saveAndTrackSpending;

  /// No description provided for @saveAndTrackSpendingBody.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save this receipt and track your daily, weekly, monthly and yearly spending.'**
  String get saveAndTrackSpendingBody;

  /// No description provided for @scanReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a Receipt'**
  String get scanReceiptTitle;

  /// No description provided for @scanReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload a JPG, PNG, or PDF and let AI extract the details'**
  String get scanReceiptSubtitle;

  /// No description provided for @scanUploadOptions.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload a receipt file'**
  String get scanUploadOptions;

  /// No description provided for @supportedScanFormats.
  ///
  /// In en, this message translates to:
  /// **'Supports printed receipts, e-invoices, and digital receipts in JPG, PNG, and PDF formats.'**
  String get supportedScanFormats;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @openCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get openCamera;

  /// No description provided for @uploadReceiptFile.
  ///
  /// In en, this message translates to:
  /// **'Upload JPG, PNG, or PDF'**
  String get uploadReceiptFile;

  /// No description provided for @cameraAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your camera'**
  String get cameraAccessTitle;

  /// No description provided for @cameraAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to capture a receipt instantly from the scan screen.'**
  String get cameraAccessBody;

  /// No description provided for @allowCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Camera Access'**
  String get allowCameraAccess;

  /// No description provided for @cameraStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting camera...'**
  String get cameraStarting;

  /// No description provided for @cameraPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live receipt capture'**
  String get cameraPreviewTitle;

  /// No description provided for @cameraPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Place the receipt inside the frame, then capture it.'**
  String get cameraPreviewBody;

  /// No description provided for @captureReceiptPhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture Receipt'**
  String get captureReceiptPhoto;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Check your browser settings and try again.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera could not be started on this device.'**
  String get cameraUnavailable;

  /// No description provided for @cameraUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This browser does not support live camera capture.'**
  String get cameraUnsupported;

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Choose Another File'**
  String get changeFile;

  /// No description provided for @analyzeSelectedFile.
  ///
  /// In en, this message translates to:
  /// **'Analyze Selected File'**
  String get analyzeSelectedFile;

  /// No description provided for @selectedReceiptFile.
  ///
  /// In en, this message translates to:
  /// **'Selected Receipt File'**
  String get selectedReceiptFile;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @pdfReadyForAnalysis.
  ///
  /// In en, this message translates to:
  /// **'This PDF is ready for AI analysis. We will send the original document without image compression.'**
  String get pdfReadyForAnalysis;

  /// No description provided for @tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Choose a file to start scanning'**
  String get tapToScan;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @analyzingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Analyzing receipt...'**
  String get analyzingReceipt;

  /// No description provided for @analyzingReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'Gemini AI is extracting the data'**
  String get analyzingReceiptBody;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @setupShopSeconds.
  ///
  /// In en, this message translates to:
  /// **'Set up your shop in seconds'**
  String get setupShopSeconds;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @minSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minSixCharacters;

  /// No description provided for @enterShopName.
  ///
  /// In en, this message translates to:
  /// **'Enter your shop name'**
  String get enterShopName;

  /// No description provided for @authFirebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured for this build yet.'**
  String get authFirebaseNotConfigured;

  /// No description provided for @authAccountSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Your Firebase sign-in succeeded, but your shop setup is missing. Please complete registration first.'**
  String get authAccountSetupRequired;

  /// No description provided for @shopSetupMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop profile missing'**
  String get shopSetupMissingTitle;

  /// No description provided for @shopSetupMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Your Firebase account is ready, but we could not find a shop profile in Firestore. Create a new shop to continue.'**
  String get shopSetupMissingBody;

  /// No description provided for @createNewShop.
  ///
  /// In en, this message translates to:
  /// **'Create New Shop'**
  String get createNewShop;

  /// No description provided for @completeShopSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your shop setup'**
  String get completeShopSetupTitle;

  /// No description provided for @completeShopSetupBody.
  ///
  /// In en, this message translates to:
  /// **'We found your account, but your Firestore profile is incomplete. Add a shop name and create your shop profile now.'**
  String get completeShopSetupBody;

  /// No description provided for @shopSetupCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Shop Profile'**
  String get shopSetupCreateButton;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email address is already in use.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password with at least 6 characters.'**
  String get authWeakPassword;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'A network error occurred. Please try again.'**
  String get authNetworkError;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a bit and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Authentication could not be completed.'**
  String get authUnexpectedError;

  /// No description provided for @dashboardSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your dashboard'**
  String get dashboardSignInPrompt;

  /// No description provided for @historySignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your receipts'**
  String get historySignInPrompt;

  /// No description provided for @spendingTrends.
  ///
  /// In en, this message translates to:
  /// **'Spending Trends'**
  String get spendingTrends;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// No description provided for @topSpots.
  ///
  /// In en, this message translates to:
  /// **'Top Spots'**
  String get topSpots;

  /// No description provided for @totalSpend.
  ///
  /// In en, this message translates to:
  /// **'Total Spend'**
  String get totalSpend;

  /// No description provided for @totalReceipts.
  ///
  /// In en, this message translates to:
  /// **'Total Receipts'**
  String get totalReceipts;

  /// No description provided for @dashboardCurrencyFilter.
  ///
  /// In en, this message translates to:
  /// **'Dashboard currency filter'**
  String get dashboardCurrencyFilter;

  /// No description provided for @receiptCurrency.
  ///
  /// In en, this message translates to:
  /// **'Receipt currency'**
  String get receiptCurrency;

  /// No description provided for @dashboardCurrencyFilterBody.
  ///
  /// In en, this message translates to:
  /// **'Totals, charts and category breakdowns are filtered by the payment currency stored on each receipt.'**
  String get dashboardCurrencyFilterBody;

  /// No description provided for @dashboardCurrencySingleBody.
  ///
  /// In en, this message translates to:
  /// **'Current dashboard totals are shown in {activeLabel}.'**
  String dashboardCurrencySingleBody(String activeLabel);

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @noSpendingDataYet.
  ///
  /// In en, this message translates to:
  /// **'No spending data yet'**
  String get noSpendingDataYet;

  /// No description provided for @scanToSeeCategories.
  ///
  /// In en, this message translates to:
  /// **'Scan receipts to see category breakdown'**
  String get scanToSeeCategories;

  /// No description provided for @scanToSeeTopSpots.
  ///
  /// In en, this message translates to:
  /// **'Scan receipts to see top spots'**
  String get scanToSeeTopSpots;

  /// No description provided for @receiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsTitle;

  /// No description provided for @noReceiptsYet.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get noReceiptsYet;

  /// No description provided for @scanFirstReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan your first receipt to get started'**
  String get scanFirstReceipt;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @noExtractedItems.
  ///
  /// In en, this message translates to:
  /// **'No extracted items'**
  String get noExtractedItems;

  /// No description provided for @editReceiptData.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt Data'**
  String get editReceiptData;

  /// No description provided for @deleteReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Receipt?'**
  String get deleteReceiptTitle;

  /// No description provided for @deleteReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All extracted data will be removed.'**
  String get deleteReceiptBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @unknownVendor.
  ///
  /// In en, this message translates to:
  /// **'Unknown vendor'**
  String get unknownVendor;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown item'**
  String get unknownItem;

  /// No description provided for @receiptScanned.
  ///
  /// In en, this message translates to:
  /// **'Receipt Scanned!'**
  String get receiptScanned;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @editReceiptDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt Details'**
  String get editReceiptDetails;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'GENERAL INFO'**
  String get generalInfo;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor Name'**
  String get vendorName;

  /// No description provided for @dateIso.
  ///
  /// In en, this message translates to:
  /// **'Date (YYYY-MM-DD)'**
  String get dateIso;

  /// No description provided for @currencyCode.
  ///
  /// In en, this message translates to:
  /// **'Currency Code'**
  String get currencyCode;

  /// No description provided for @currencyCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Use ISO 4217 codes like TRY, EUR, USD or AED to correct the detected payment currency.'**
  String get currencyCodeHint;

  /// No description provided for @extractedItems.
  ///
  /// In en, this message translates to:
  /// **'EXTRACTED ITEMS'**
  String get extractedItems;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @quantityShort.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantityShort;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @languageUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Language could not be saved'**
  String get languageUpdateFailed;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryStationery.
  ///
  /// In en, this message translates to:
  /// **'Stationery'**
  String get categoryStationery;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport/Travel'**
  String get categoryTransport;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @noLineItems.
  ///
  /// In en, this message translates to:
  /// **'No extracted line items.'**
  String get noLineItems;

  /// No description provided for @receiptCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# receipt} other{# receipts}}'**
  String receiptCountLabel(int count);

  /// No description provided for @itemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{# item} other{# items}}'**
  String itemCountLabel(int count);

  /// No description provided for @itemsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String itemsSectionTitle(int count);

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard.'**
  String get failedToLoadDashboard;

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history.'**
  String get failedToLoadHistory;

  /// No description provided for @failedToDeleteReceipt.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete receipt.'**
  String get failedToDeleteReceipt;

  /// No description provided for @failedToUpdateReceiptPrefix.
  ///
  /// In en, this message translates to:
  /// **'Failed to update receipt: {error}'**
  String failedToUpdateReceiptPrefix(String error);

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkce'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;
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
      <String>['ar', 'de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
