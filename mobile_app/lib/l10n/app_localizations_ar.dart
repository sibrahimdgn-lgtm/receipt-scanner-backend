// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ماسح الإيصالات';

  @override
  String get poweredByGemini => 'مدعوم بواسطة Gemini AI';

  @override
  String get navScan => 'مسح';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navHistory => 'السجل';

  @override
  String get trackYourSpending => 'تابع مصروفاتك';

  @override
  String get trackYourSpendingBody =>
      'أنشئ حسابًا مجانيًا لحفظ إيصالاتك ومشاهدة ملخصات الإنفاق اليومية والأسبوعية والشهرية والسنوية.';

  @override
  String get signUpSignIn => 'إنشاء حساب / تسجيل الدخول';

  @override
  String get maybeLater => 'لاحقًا';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signUpFree => 'إنشاء حساب مجانًا';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get saveAndTrackSpending => 'احفظ وتابع مصروفاتك';

  @override
  String get saveAndTrackSpendingBody =>
      'أنشئ حسابًا مجانيًا لحفظ هذا الإيصال ومتابعة مصروفاتك اليومية والأسبوعية والشهرية والسنوية.';

  @override
  String get scanReceiptTitle => 'امسح إيصالًا';

  @override
  String get scanReceiptSubtitle =>
      'التقط صورة أو ارفع ملف JPG أو PNG أو PDF ودع الذكاء الاصطناعي يستخرج التفاصيل';

  @override
  String get scanUploadOptions => 'التقط صورة أو ارفع ملف إيصال';

  @override
  String get supportedScanFormats =>
      'يدعم الإيصالات المطبوعة والفواتير الإلكترونية والإيصالات الرقمية بصيغ JPG وPNG وPDF.';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get openCamera => 'افتح الكاميرا';

  @override
  String get uploadReceiptFile => 'ارفع JPG أو PNG أو PDF';

  @override
  String get cameraAccessTitle => 'استخدم الكاميرا';

  @override
  String get cameraAccessBody =>
      'اسمح بالوصول إلى الكاميرا لالتقاط الإيصال فورًا من شاشة المسح.';

  @override
  String get allowCameraAccess => 'اسمح بالوصول إلى الكاميرا';

  @override
  String get cameraStarting => 'جارٍ تشغيل الكاميرا...';

  @override
  String get cameraPreviewTitle => 'التقاط إيصال مباشر';

  @override
  String get cameraPreviewBody => 'ضع الإيصال داخل الإطار ثم التقطه.';

  @override
  String get captureReceiptPhoto => 'التقط الإيصال';

  @override
  String get cameraPermissionDenied =>
      'تم رفض الوصول إلى الكاميرا. تحقّق من إعدادات المتصفح ثم حاول مرة أخرى.';

  @override
  String get cameraUnavailable => 'تعذر تشغيل الكاميرا على هذا الجهاز.';

  @override
  String get cameraUnsupported =>
      'هذا المتصفح لا يدعم التقاط الكاميرا المباشر.';

  @override
  String get changeFile => 'اختر ملفًا آخر';

  @override
  String get analyzeSelectedFile => 'حلل الملف المحدد';

  @override
  String get selectedReceiptFile => 'ملف الإيصال المحدد';

  @override
  String get pdfDocument => 'مستند PDF';

  @override
  String get pdfReadyForAnalysis =>
      'هذا الملف جاهز للتحليل بالذكاء الاصطناعي. سنرسل المستند الأصلي بدون ضغط للصورة.';

  @override
  String get tapToScan => 'اختر ملفًا لبدء المسح';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get analyzingReceipt =>
      'تجري الآن معالجة تفاصيل الإيصال بالذكاء الاصطناعي...';

  @override
  String get analyzingReceiptBody =>
      'يستغرق ذلك عادة بضع ثوانٍ. يرجى إبقاء هذه الشاشة مفتوحة.';

  @override
  String get receiptScannedAndSaved => 'تم مسح الإيصال وحفظه بنجاح.';

  @override
  String get scanFailedTryAgain => 'فشل المسح، يرجى المحاولة مرة أخرى.';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signInToAccount => 'سجّل الدخول إلى حسابك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get setupShopSeconds => 'أعد إعداد متجرك خلال ثوانٍ';

  @override
  String get shopName => 'اسم المتجر';

  @override
  String get createAccountButton => 'إنشاء الحساب';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get enterValidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get minSixCharacters => '6 أحرف على الأقل';

  @override
  String get enterShopName => 'أدخل اسم المتجر';

  @override
  String get authFirebaseNotConfigured =>
      'لم يتم إعداد Firebase لهذا الإصدار بعد.';

  @override
  String get authAccountSetupRequired =>
      'تم تسجيل الدخول عبر Firebase بنجاح، لكن إعداد المتجر غير مكتمل. يرجى إكمال التسجيل أولاً.';

  @override
  String get shopSetupMissingTitle => 'ملف المتجر مفقود';

  @override
  String get shopSetupMissingBody =>
      'حساب Firebase جاهز، لكننا لم نجد ملف متجر داخل Firestore. أنشئ متجرًا جديدًا للمتابعة.';

  @override
  String get createNewShop => 'إنشاء متجر جديد';

  @override
  String get completeShopSetupTitle => 'أكمل إعداد المتجر';

  @override
  String get completeShopSetupBody =>
      'لقد وجدنا حسابك، لكن ملف Firestore غير مكتمل. أضف اسم المتجر وأنشئ ملف المتجر الآن.';

  @override
  String get shopSetupCreateButton => 'إنشاء ملف المتجر';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authEmailAlreadyInUse =>
      'عنوان البريد الإلكتروني هذا مستخدم بالفعل.';

  @override
  String get authWeakPassword => 'اختر كلمة مرور أقوى لا تقل عن 6 أحرف.';

  @override
  String get authNetworkError => 'حدث خطأ في الشبكة. يرجى المحاولة مرة أخرى.';

  @override
  String get authTooManyRequests =>
      'تم تنفيذ عدد كبير جدًا من المحاولات. يرجى الانتظار قليلًا ثم المحاولة مرة أخرى.';

  @override
  String get authUnexpectedError => 'تعذر إكمال عملية المصادقة.';

  @override
  String get dashboardSignInPrompt => 'سجّل الدخول لعرض لوحة التحكم';

  @override
  String get historySignInPrompt => 'سجّل الدخول لعرض إيصالاتك';

  @override
  String get spendingTrends => 'اتجاهات الإنفاق';

  @override
  String get spendingByCategory => 'الإنفاق حسب الفئة';

  @override
  String get topSpots => 'الأماكن الأكثر استخدامًا';

  @override
  String get totalSpend => 'إجمالي الإنفاق';

  @override
  String get totalReceipts => 'إجمالي الإيصالات';

  @override
  String get dashboardCurrencyFilter => 'تصفية عملة لوحة التحكم';

  @override
  String get receiptCurrency => 'عملة الإيصال';

  @override
  String get dashboardCurrencyFilterBody =>
      'تتم تصفية الإجماليات والرسوم البيانية وتوزيعات الفئات حسب عملة الدفع المحفوظة على كل إيصال.';

  @override
  String dashboardCurrencySingleBody(String activeLabel) {
    return 'يتم عرض إجماليات لوحة التحكم الحالية بعملة $activeLabel.';
  }

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get monthly => 'شهري';

  @override
  String get yearly => 'سنوي';

  @override
  String get noSpendingDataYet => 'لا توجد بيانات إنفاق بعد';

  @override
  String get scanToSeeCategories => 'امسح الإيصالات لرؤية توزيع الفئات';

  @override
  String get scanToSeeTopSpots =>
      'امسح الإيصالات لرؤية الأماكن الأكثر استخدامًا';

  @override
  String get receiptsTitle => 'الإيصالات';

  @override
  String get noReceiptsYet => 'لا توجد إيصالات بعد';

  @override
  String get scanFirstReceipt => 'امسح أول إيصال للبدء';

  @override
  String get items => 'العناصر';

  @override
  String get total => 'الإجمالي';

  @override
  String get date => 'التاريخ';

  @override
  String get noExtractedItems => 'لا توجد عناصر مستخرجة';

  @override
  String get editReceiptData => 'تعديل بيانات الإيصال';

  @override
  String get deleteReceiptTitle => 'حذف الإيصال؟';

  @override
  String get deleteReceiptBody =>
      'لا يمكن التراجع عن هذا الإجراء. ستتم إزالة جميع البيانات المستخرجة.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get unknownVendor => 'بائع غير معروف';

  @override
  String get unknownItem => 'عنصر غير معروف';

  @override
  String get receiptScanned => 'تم مسح الإيصال!';

  @override
  String get done => 'تم';

  @override
  String get tax => 'الضريبة';

  @override
  String get editReceiptDetails => 'تعديل تفاصيل الإيصال';

  @override
  String get save => 'حفظ';

  @override
  String get generalInfo => 'معلومات عامة';

  @override
  String get vendorName => 'اسم البائع';

  @override
  String get dateIso => 'التاريخ (YYYY-MM-DD)';

  @override
  String get currencyCode => 'رمز العملة';

  @override
  String get currencyCodeHint =>
      'استخدم رموز ISO 4217 مثل TRY أو EUR أو USD أو AED لتصحيح عملة الدفع المكتشفة.';

  @override
  String get extractedItems => 'العناصر المستخرجة';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get quantityShort => 'الكمية';

  @override
  String get price => 'السعر';

  @override
  String get category => 'الفئة';

  @override
  String get language => 'اللغة';

  @override
  String get languageUpdated => 'تم تحديث اللغة';

  @override
  String get languageUpdateFailed => 'تعذر حفظ اللغة';

  @override
  String get categoryFood => 'طعام';

  @override
  String get categoryStationery => 'قرطاسية';

  @override
  String get categoryTransport => 'مواصلات/سفر';

  @override
  String get categoryElectronics => 'إلكترونيات';

  @override
  String get categoryHealth => 'صحة';

  @override
  String get categoryEntertainment => 'ترفيه';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get noLineItems => 'لا توجد عناصر سطر مستخرجة.';

  @override
  String receiptCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# إيصال',
      many: '# إيصالًا',
      few: '# إيصالات',
      two: 'إيصالان',
      one: 'إيصال واحد',
      zero: 'لا توجد إيصالات',
    );
    return '$_temp0';
  }

  @override
  String itemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# عنصر',
      many: '# عنصرًا',
      few: '# عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا توجد عناصر',
    );
    return '$_temp0';
  }

  @override
  String itemsSectionTitle(int count) {
    return 'العناصر ($count)';
  }

  @override
  String get failedToLoadDashboard => 'تعذر تحميل لوحة التحكم.';

  @override
  String get failedToLoadHistory => 'تعذر تحميل السجل.';

  @override
  String get failedToDeleteReceipt => 'تعذر حذف الإيصال.';

  @override
  String failedToUpdateReceiptPrefix(String error) {
    return 'تعذر تحديث الإيصال: $error';
  }

  @override
  String get turkish => 'التركية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get german => 'الألمانية';

  @override
  String get arabic => 'العربية';
}
