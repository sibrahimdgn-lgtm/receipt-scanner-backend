// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Receipt Scanner';

  @override
  String get poweredByGemini => 'Powered by Gemini AI';

  @override
  String get navScan => 'Scan';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navHistory => 'History';

  @override
  String get trackYourSpending => 'Track Your Spending';

  @override
  String get trackYourSpendingBody =>
      'Create a free account to save your receipts and see daily, weekly, monthly and yearly spending breakdowns.';

  @override
  String get signUpSignIn => 'Sign Up / Sign In';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signUpFree => 'Sign Up Free';

  @override
  String get notNow => 'Not now';

  @override
  String get saveAndTrackSpending => 'Save & Track Your Spending';

  @override
  String get saveAndTrackSpendingBody =>
      'Create a free account to save this receipt and track your daily, weekly, monthly and yearly spending.';

  @override
  String get scanReceiptTitle => 'Scan a Receipt';

  @override
  String get scanReceiptSubtitle =>
      'Take a photo or upload a JPG, PNG, or PDF and let AI extract the details';

  @override
  String get scanUploadOptions => 'Take a photo or upload a receipt file';

  @override
  String get supportedScanFormats =>
      'Supports printed receipts, e-invoices, and digital receipts in JPG, PNG, and PDF formats.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get openCamera => 'Open Camera';

  @override
  String get uploadReceiptFile => 'Upload JPG, PNG, or PDF';

  @override
  String get cameraAccessTitle => 'Use your camera';

  @override
  String get cameraAccessBody =>
      'Allow camera access to capture a receipt instantly from the scan screen.';

  @override
  String get allowCameraAccess => 'Allow Camera Access';

  @override
  String get cameraStarting => 'Starting camera...';

  @override
  String get cameraPreviewTitle => 'Live receipt capture';

  @override
  String get cameraPreviewBody =>
      'Place the receipt inside the frame, then capture it.';

  @override
  String get captureReceiptPhoto => 'Capture Receipt';

  @override
  String get cameraPermissionDenied =>
      'Camera access was denied. Check your browser settings and try again.';

  @override
  String get cameraUnavailable => 'Camera could not be started on this device.';

  @override
  String get cameraUnsupported =>
      'This browser does not support live camera capture.';

  @override
  String get changeFile => 'Choose Another File';

  @override
  String get analyzeSelectedFile => 'Analyze Selected File';

  @override
  String get selectedReceiptFile => 'Selected Receipt File';

  @override
  String get pdfDocument => 'PDF Document';

  @override
  String get pdfReadyForAnalysis =>
      'This PDF is ready for AI analysis. We will send the original document without image compression.';

  @override
  String get tapToScan => 'Choose a file to start scanning';

  @override
  String get retry => 'Retry';

  @override
  String get analyzingReceipt => 'Receipt details are being analyzed by AI...';

  @override
  String get analyzingReceiptBody =>
      'This usually takes a few seconds. Please keep this screen open.';

  @override
  String get receiptScannedAndSaved =>
      'Receipt scanned and saved successfully.';

  @override
  String get scanFailedTryAgain => 'Scanning failed. Please try again.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToAccount => 'Sign in to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get setupShopSeconds => 'Set up your shop in seconds';

  @override
  String get shopName => 'Shop Name';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get minSixCharacters => 'Min 6 characters';

  @override
  String get enterShopName => 'Enter your shop name';

  @override
  String get authFirebaseNotConfigured =>
      'Firebase is not configured for this build yet.';

  @override
  String get authAccountSetupRequired =>
      'Your Firebase sign-in succeeded, but your shop setup is missing. Please complete registration first.';

  @override
  String get shopSetupMissingTitle => 'Shop profile missing';

  @override
  String get shopSetupMissingBody =>
      'Your Firebase account is ready, but we could not find a shop profile in Firestore. Create a new shop to continue.';

  @override
  String get createNewShop => 'Create New Shop';

  @override
  String get completeShopSetupTitle => 'Complete your shop setup';

  @override
  String get completeShopSetupBody =>
      'We found your account, but your Firestore profile is incomplete. Add a shop name and create your shop profile now.';

  @override
  String get shopSetupCreateButton => 'Create Shop Profile';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authEmailAlreadyInUse => 'This email address is already in use.';

  @override
  String get authWeakPassword =>
      'Choose a stronger password with at least 6 characters.';

  @override
  String get authNetworkError => 'A network error occurred. Please try again.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait a bit and try again.';

  @override
  String get authUnexpectedError => 'Authentication could not be completed.';

  @override
  String get dashboardSignInPrompt => 'Sign in to view your dashboard';

  @override
  String get historySignInPrompt => 'Sign in to view your receipts';

  @override
  String get spendingTrends => 'Spending Trends';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get topSpots => 'Top Spots';

  @override
  String get totalSpend => 'Total Spend';

  @override
  String get totalReceipts => 'Total Receipts';

  @override
  String get dashboardCurrencyFilter => 'Dashboard currency filter';

  @override
  String get receiptCurrency => 'Receipt currency';

  @override
  String get dashboardCurrencyFilterBody =>
      'Totals, charts and category breakdowns are filtered by the payment currency stored on each receipt.';

  @override
  String dashboardCurrencySingleBody(String activeLabel) {
    return 'Current dashboard totals are shown in $activeLabel.';
  }

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get noSpendingDataYet => 'No spending data yet';

  @override
  String get scanToSeeCategories => 'Scan receipts to see category breakdown';

  @override
  String get scanToSeeTopSpots => 'Scan receipts to see top spots';

  @override
  String get receiptsTitle => 'Receipts';

  @override
  String get noReceiptsYet => 'No receipts yet';

  @override
  String get scanFirstReceipt => 'Scan your first receipt to get started';

  @override
  String get items => 'Items';

  @override
  String get total => 'Total';

  @override
  String get date => 'Date';

  @override
  String get noExtractedItems => 'No extracted items';

  @override
  String get editReceiptData => 'Edit Receipt Data';

  @override
  String get deleteReceiptTitle => 'Delete Receipt?';

  @override
  String get deleteReceiptBody =>
      'This action cannot be undone. All extracted data will be removed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get unknownVendor => 'Unknown vendor';

  @override
  String get unknownItem => 'Unknown item';

  @override
  String get receiptScanned => 'Receipt Scanned!';

  @override
  String get done => 'Done';

  @override
  String get tax => 'Tax';

  @override
  String get editReceiptDetails => 'Edit Receipt Details';

  @override
  String get save => 'Save';

  @override
  String get generalInfo => 'GENERAL INFO';

  @override
  String get vendorName => 'Vendor Name';

  @override
  String get dateIso => 'Date (YYYY-MM-DD)';

  @override
  String get currencyCode => 'Currency Code';

  @override
  String get currencyCodeHint =>
      'Use ISO 4217 codes like TRY, EUR, USD or AED to correct the detected payment currency.';

  @override
  String get extractedItems => 'EXTRACTED ITEMS';

  @override
  String get itemName => 'Item Name';

  @override
  String get quantityShort => 'Qty';

  @override
  String get price => 'Price';

  @override
  String get category => 'Category';

  @override
  String get language => 'Language';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get languageUpdateFailed => 'Language could not be saved';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryStationery => 'Stationery';

  @override
  String get categoryTransport => 'Transport/Travel';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryOther => 'Other';

  @override
  String get noLineItems => 'No extracted line items.';

  @override
  String receiptCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# receipts',
      one: '# receipt',
    );
    return '$_temp0';
  }

  @override
  String itemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# items',
      one: '# item',
    );
    return '$_temp0';
  }

  @override
  String itemsSectionTitle(int count) {
    return 'Items ($count)';
  }

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard.';

  @override
  String get failedToLoadHistory => 'Failed to load history.';

  @override
  String get failedToDeleteReceipt => 'Failed to delete receipt.';

  @override
  String failedToUpdateReceiptPrefix(String error) {
    return 'Failed to update receipt: $error';
  }

  @override
  String get turkish => 'Turkce';

  @override
  String get english => 'English';

  @override
  String get german => 'Deutsch';

  @override
  String get arabic => 'Arabic';
}
