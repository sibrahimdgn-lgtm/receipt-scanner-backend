// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Fiş Tarayıcı';

  @override
  String get poweredByGemini => 'Gemini AI destekli';

  @override
  String get navScan => 'Tarama';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navHistory => 'Geçmiş';

  @override
  String get trackYourSpending => 'Harcamalarını Takip Et';

  @override
  String get trackYourSpendingBody =>
      'Fişlerini kaydetmek ve günlük, haftalık, aylık ve yıllık harcama kırılımlarını görmek için ücretsiz hesap oluştur.';

  @override
  String get signUpSignIn => 'Kayıt Ol / Giriş Yap';

  @override
  String get maybeLater => 'Daha sonra';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get signUpFree => 'Ücretsiz Kayıt Ol';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get saveAndTrackSpending => 'Harcamanı Kaydet ve Takip Et';

  @override
  String get saveAndTrackSpendingBody =>
      'Bu fişi kaydetmek ve günlük, haftalık, aylık ve yıllık harcamanı takip etmek için ücretsiz hesap oluştur.';

  @override
  String get scanReceiptTitle => 'Fiş Tara';

  @override
  String get scanReceiptSubtitle =>
      'Fotoğraf çek veya JPG, PNG ya da PDF yükle; detayları AI çıkarsın';

  @override
  String get scanUploadOptions => 'Fotoğraf çek veya fiş dosyası yükle';

  @override
  String get supportedScanFormats =>
      'JPG, PNG ve PDF formatındaki basılı fişleri, e-faturaları ve dijital fişleri destekler.';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get openCamera => 'Kamerayı Aç';

  @override
  String get uploadReceiptFile => 'JPG, PNG veya PDF Yükle';

  @override
  String get cameraAccessTitle => 'Kameranı kullan';

  @override
  String get cameraAccessBody =>
      'Tarama ekranından fişi anında yakalamak için kamera erişimine izin ver.';

  @override
  String get allowCameraAccess => 'Kamera Erişimine İzin Ver';

  @override
  String get cameraStarting => 'Kamera başlatılıyor...';

  @override
  String get cameraPreviewTitle => 'Canlı fiş yakalama';

  @override
  String get cameraPreviewBody =>
      'Fişi çerçevenin içine yerleştir, ardından yakala.';

  @override
  String get captureReceiptPhoto => 'Fişi Yakala';

  @override
  String get cameraPermissionDenied =>
      'Kamera erişimi reddedildi. Tarayıcı ayarlarını kontrol edip tekrar dene.';

  @override
  String get cameraUnavailable => 'Bu cihazda kamera başlatılamadı.';

  @override
  String get cameraUnsupported =>
      'Bu tarayıcı canlı kamera taramayı desteklemiyor.';

  @override
  String get changeFile => 'Başka Dosya Seç';

  @override
  String get analyzeSelectedFile => 'Seçili Dosyayı Analiz Et';

  @override
  String get selectedReceiptFile => 'Seçilen Fiş Dosyası';

  @override
  String get pdfDocument => 'PDF Belgesi';

  @override
  String get pdfReadyForAnalysis =>
      'Bu PDF analiz için hazır. Görsel sıkıştırması yapmadan orijinal belgeyi göndereceğiz.';

  @override
  String get tapToScan => 'Taramaya başlamak için bir dosya seç';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get analyzingReceipt =>
      'Fiş detayları yapay zeka ile analiz ediliyor...';

  @override
  String get analyzingReceiptBody =>
      'Bu işlem genelde birkaç saniye sürer. Lütfen bu ekranı açık tut.';

  @override
  String get receiptScannedAndSaved => 'Fiş başarıyla tarandı ve kaydedildi.';

  @override
  String get scanFailedTryAgain =>
      'Tarama başarısız oldu, lütfen tekrar deneyin.';

  @override
  String get welcomeBack => 'Tekrar hoş geldin';

  @override
  String get signInToAccount => 'Hesabına giriş yap';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get dontHaveAccount => 'Hesabın yok mu?';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get setupShopSeconds => 'Mağazanı saniyeler içinde kur';

  @override
  String get shopName => 'Mağaza Adı';

  @override
  String get createAccountButton => 'Hesap Oluştur';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı?';

  @override
  String get enterValidEmail => 'Geçerli bir e-posta gir';

  @override
  String get minSixCharacters => 'En az 6 karakter';

  @override
  String get enterShopName => 'Mağaza adını gir';

  @override
  String get authFirebaseNotConfigured =>
      'Firebase bu yapı için henüz yapılandırılmadı.';

  @override
  String get authAccountSetupRequired =>
      'Firebase girişi başarılı oldu ama mağaza kurulumu eksik. Lütfen önce kaydı tamamla.';

  @override
  String get shopSetupMissingTitle => 'Mağaza profili eksik';

  @override
  String get shopSetupMissingBody =>
      'Firebase hesabın hazır, ancak Firestore içinde bir mağaza profili bulamadık. Devam etmek için yeni bir mağaza oluştur.';

  @override
  String get createNewShop => 'Yeni Mağaza Oluştur';

  @override
  String get completeShopSetupTitle => 'Mağaza kurulumunu tamamla';

  @override
  String get completeShopSetupBody =>
      'Hesabını bulduk ama Firestore profilin eksik görünüyor. Mağaza adını ekleyip profilini şimdi oluştur.';

  @override
  String get shopSetupCreateButton => 'Mağaza Profilini Oluştur';

  @override
  String get authInvalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get authEmailAlreadyInUse => 'Bu e-posta adresi zaten kullanımda.';

  @override
  String get authWeakPassword =>
      'En az 6 karakter içeren daha güçlü bir şifre seç.';

  @override
  String get authNetworkError => 'Bir ağ hatası oluştu. Lütfen tekrar dene.';

  @override
  String get authTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar dene.';

  @override
  String get authUnexpectedError => 'Kimlik doğrulama tamamlanamadı.';

  @override
  String get dashboardSignInPrompt => 'Paneli görmek için giriş yap';

  @override
  String get historySignInPrompt => 'Fişlerini görmek için giriş yap';

  @override
  String get spendingTrends => 'Harcama Trendleri';

  @override
  String get spendingByCategory => 'Kategoriye Göre Harcama';

  @override
  String get topSpots => 'En Çok Gidilen Yerler';

  @override
  String get totalSpend => 'Toplam Harcama';

  @override
  String get totalReceipts => 'Toplam Fiş';

  @override
  String get dashboardCurrencyFilter => 'Panel para birimi filtresi';

  @override
  String get receiptCurrency => 'Fiş para birimi';

  @override
  String get dashboardCurrencyFilterBody =>
      'Toplamlar, grafikler ve kategori kırılımları her fiş için kaydedilen ödeme para birimine göre filtrelenir.';

  @override
  String dashboardCurrencySingleBody(String activeLabel) {
    return 'Panel toplamları şu anda $activeLabel cinsinden gösteriliyor.';
  }

  @override
  String get daily => 'Günlük';

  @override
  String get weekly => 'Haftalık';

  @override
  String get monthly => 'Aylık';

  @override
  String get yearly => 'Yıllık';

  @override
  String get noSpendingDataYet => 'Henüz harcama verisi yok';

  @override
  String get scanToSeeCategories => 'Kategori dağılımını görmek için fiş tara';

  @override
  String get scanToSeeTopSpots => 'En çok gidilen yerleri görmek için fiş tara';

  @override
  String get receiptsTitle => 'Fişler';

  @override
  String get noReceiptsYet => 'Henüz fiş yok';

  @override
  String get scanFirstReceipt => 'Başlamak için ilk fişini tara';

  @override
  String get items => 'Kalemler';

  @override
  String get total => 'Toplam';

  @override
  String get date => 'Tarih';

  @override
  String get noExtractedItems => 'Çıkarılan kalem yok';

  @override
  String get editReceiptData => 'Fiş Verisini Düzenle';

  @override
  String get deleteReceiptTitle => 'Fiş silinsin mi?';

  @override
  String get deleteReceiptBody =>
      'Bu işlem geri alınamaz. Tüm çıkarılan veriler silinecek.';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get unknownVendor => 'Bilinmeyen satıcı';

  @override
  String get unknownItem => 'Bilinmeyen kalem';

  @override
  String get receiptScanned => 'Fiş Tarandı!';

  @override
  String get done => 'Tamam';

  @override
  String get tax => 'Vergi';

  @override
  String get editReceiptDetails => 'Fiş Detaylarını Düzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get generalInfo => 'GENEL BİLGİ';

  @override
  String get vendorName => 'Satıcı Adı';

  @override
  String get dateIso => 'Tarih (YYYY-MM-DD)';

  @override
  String get currencyCode => 'Para Birimi Kodu';

  @override
  String get currencyCodeHint =>
      'Algılanan ödeme para birimini düzeltmek için TRY, EUR, USD veya AED gibi ISO 4217 kodları kullan.';

  @override
  String get extractedItems => 'ÇIKARILAN KALEMLER';

  @override
  String get itemName => 'Kalem Adı';

  @override
  String get quantityShort => 'Adet';

  @override
  String get price => 'Fiyat';

  @override
  String get category => 'Kategori';

  @override
  String get language => 'Dil';

  @override
  String get languageUpdated => 'Dil güncellendi';

  @override
  String get languageUpdateFailed => 'Dil kaydedilemedi';

  @override
  String get categoryFood => 'Gıda';

  @override
  String get categoryStationery => 'Kırtasiye';

  @override
  String get categoryTransport => 'Ulaşım/Yol';

  @override
  String get categoryElectronics => 'Elektronik';

  @override
  String get categoryHealth => 'Sağlık';

  @override
  String get categoryEntertainment => 'Eğlence';

  @override
  String get categoryOther => 'Diğer';

  @override
  String get noLineItems => 'Çıkarılan satır kalemi yok.';

  @override
  String receiptCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# fiş',
      one: '# fiş',
    );
    return '$_temp0';
  }

  @override
  String itemCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# kalem',
      one: '# kalem',
    );
    return '$_temp0';
  }

  @override
  String itemsSectionTitle(int count) {
    return 'Kalemler ($count)';
  }

  @override
  String get failedToLoadDashboard => 'Panel yüklenemedi.';

  @override
  String get failedToLoadHistory => 'Geçmiş yüklenemedi.';

  @override
  String get failedToDeleteReceipt => 'Fiş silinemedi.';

  @override
  String failedToUpdateReceiptPrefix(String error) {
    return 'Fiş güncellenemedi: $error';
  }

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get german => 'Deutsch';

  @override
  String get arabic => 'Arapça';
}
