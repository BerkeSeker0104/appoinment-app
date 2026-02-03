import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'M&W'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @success.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get success;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @search.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filter;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @continueText.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueText;

  /// No description provided for @welcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcome;

  /// No description provided for @welcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'En iyi işletmeleri keşfet'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Randevunu kolayca al, Herşey elinin altında'**
  String get welcomeSubtitle;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get signUp;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapmak istediğinizden emin misiniz?'**
  String get logoutConfirm;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'**
  String get logoutConfirmMessage;

  /// No description provided for @phoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı?'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get createAccount;

  /// No description provided for @selectAccountType.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Türünü Seç'**
  String get selectAccountType;

  /// No description provided for @customerAccount.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Hesabı'**
  String get customerAccount;

  /// No description provided for @companyAccount.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Hesabı'**
  String get companyAccount;

  /// No description provided for @accountTypeDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı hesabı ile hizmet alabilir, işletme hesabı ile işletmenizi ve şubelerinizi yönetebilirsiniz.'**
  String get accountTypeDescription;

  /// No description provided for @verificationCode.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu'**
  String get verificationCode;

  /// No description provided for @sendCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod Gönder'**
  String get sendCode;

  /// No description provided for @verifyCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Doğrula'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Tekrar Gönder'**
  String get resendCode;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @searchNav.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get searchNav;

  /// No description provided for @bookings.
  ///
  /// In tr, this message translates to:
  /// **'Randevularım'**
  String get bookings;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @favorites.
  ///
  /// In tr, this message translates to:
  /// **'Favoriler'**
  String get favorites;

  /// No description provided for @cart.
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get cart;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @secure.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli'**
  String get secure;

  /// No description provided for @fast.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı'**
  String get fast;

  /// No description provided for @easy.
  ///
  /// In tr, this message translates to:
  /// **'Kolay'**
  String get easy;

  /// No description provided for @myProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get editProfile;

  /// No description provided for @profileInfo.
  ///
  /// In tr, this message translates to:
  /// **'Profil Bilgileri'**
  String get profileInfo;

  /// No description provided for @companyInfo.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Bilgileri'**
  String get companyInfo;

  /// No description provided for @companyInfoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güncel şirket verileriniz'**
  String get companyInfoSubtitle;

  /// No description provided for @companyName.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Adı'**
  String get companyName;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @userType.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Tipi'**
  String get userType;

  /// No description provided for @totalBranches.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Şube'**
  String get totalBranches;

  /// No description provided for @activeBranches.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Şube'**
  String get activeBranches;

  /// No description provided for @branches.
  ///
  /// In tr, this message translates to:
  /// **'şube'**
  String get branches;

  /// No description provided for @myBranch.
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get myBranch;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Randevu ve sistem bildirimlerinizi buradan takip edebilirsiniz'**
  String get notificationsSubtitle;

  /// No description provided for @workingHours.
  ///
  /// In tr, this message translates to:
  /// **'Çalışma Saatleri'**
  String get workingHours;

  /// No description provided for @workingHoursSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Genel çalışma saatleri ayarları'**
  String get workingHoursSubtitle;

  /// No description provided for @services.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler'**
  String get services;

  /// No description provided for @servicesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sunulan hizmetleri yönetin'**
  String get servicesSubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In tr, this message translates to:
  /// **'Yardım & Destek'**
  String get helpSupport;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık sorulan sorular ve destek'**
  String get helpSupportSubtitle;

  /// No description provided for @profileLoadingError.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgileri yüklenirken hata oluştu'**
  String get profileLoadingError;

  /// No description provided for @profileLoading.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgileri yükleniyor...'**
  String get profileLoading;

  /// No description provided for @dataLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenirken hata oluştu'**
  String get dataLoadError;

  /// No description provided for @unknownError.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen hata'**
  String get unknownError;

  /// No description provided for @unknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmiyor'**
  String get unknown;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Dili'**
  String get appLanguage;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın görüntüleneceği dil'**
  String get appLanguageSubtitle;

  /// No description provided for @notificationSettings.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get notificationSettings;

  /// No description provided for @appointmentNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Bildirimleri'**
  String get appointmentNotifications;

  /// No description provided for @appointmentNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Randevu hatırlatmaları ve güncellemeleri'**
  String get appointmentNotificationsSubtitle;

  /// No description provided for @promotionNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Promosyon Bildirimleri'**
  String get promotionNotifications;

  /// No description provided for @promotionNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Özel teklifler ve kampanyalar'**
  String get promotionNotificationsSubtitle;

  /// No description provided for @emailNotifications.
  ///
  /// In tr, this message translates to:
  /// **'E-posta Bildirimleri'**
  String get emailNotifications;

  /// No description provided for @emailNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta ile bildirim al'**
  String get emailNotificationsSubtitle;

  /// No description provided for @account.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// No description provided for @resetSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Sıfırla'**
  String get resetSettings;

  /// No description provided for @resetSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ayarları varsayılan değerlere döndür'**
  String get resetSettingsSubtitle;

  /// No description provided for @resetSettingsConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Sıfırla'**
  String get resetSettingsConfirm;

  /// No description provided for @resetSettingsConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Tüm ayarları varsayılan değerlere döndürmek istediğinizden emin misiniz?'**
  String get resetSettingsConfirmMessage;

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @settingsResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar başarıyla sıfırlandı'**
  String get settingsResetSuccess;

  /// No description provided for @settingsResetError.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar sıfırlanırken bir hata oluştu'**
  String get settingsResetError;

  /// No description provided for @languageUpdateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Dil ayarı güncellendi'**
  String get languageUpdateSuccess;

  /// No description provided for @languageUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Dil ayarı güncellenirken bir hata oluştu'**
  String get languageUpdateError;

  /// No description provided for @settingUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Ayar güncellenirken bir hata oluştu'**
  String get settingUpdateError;

  /// No description provided for @logoutError.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapılırken bir hata oluştu'**
  String get logoutError;

  /// No description provided for @appointments.
  ///
  /// In tr, this message translates to:
  /// **'Randevular'**
  String get appointments;

  /// No description provided for @upcomingAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan Randevular'**
  String get upcomingAppointments;

  /// No description provided for @pastAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Randevular'**
  String get pastAppointments;

  /// No description provided for @noAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Randevu bulunamadı'**
  String get noAppointments;

  /// No description provided for @bookAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Al'**
  String get bookAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu İptal Et'**
  String get cancelAppointment;

  /// No description provided for @cancelAppointmentConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu randevuyu iptal etmek istediğinizden emin misiniz?'**
  String get cancelAppointmentConfirm;

  /// No description provided for @cancelButton.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get cancelButton;

  /// No description provided for @appointmentCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Randevu başarıyla iptal edildi'**
  String get appointmentCancelled;

  /// No description provided for @appointmentBooked.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Alındı!'**
  String get appointmentBooked;

  /// No description provided for @appointmentBookedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Randevunuz başarıyla alındı. Kısa süre içinde bir onay mesajı alacaksınız.'**
  String get appointmentBookedMessage;

  /// No description provided for @cancelFailed.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edilemedi'**
  String get cancelFailed;

  /// No description provided for @date.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get date;

  /// No description provided for @time.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get time;

  /// No description provided for @durationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get durationLabel;

  /// No description provided for @totalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get totalLabel;

  /// No description provided for @notes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get notes;

  /// No description provided for @verifiedProfessional.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanmış Profesyonel'**
  String get verifiedProfessional;

  /// No description provided for @backToHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfaya Dön'**
  String get backToHome;

  /// No description provided for @rescheduleAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu Yeniden Planla'**
  String get rescheduleAppointment;

  /// No description provided for @appointmentDetails.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Detayları'**
  String get appointmentDetails;

  /// No description provided for @appointmentDate.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Tarihi'**
  String get appointmentDate;

  /// No description provided for @appointmentTime.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Saati'**
  String get appointmentTime;

  /// No description provided for @service.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet'**
  String get service;

  /// No description provided for @price.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat'**
  String get price;

  /// No description provided for @duration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get duration;

  /// No description provided for @barber.
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get barber;

  /// No description provided for @salon.
  ///
  /// In tr, this message translates to:
  /// **'Salon'**
  String get salon;

  /// No description provided for @location.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get location;

  /// No description provided for @searchBarbers.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Ara'**
  String get searchBarbers;

  /// No description provided for @searchPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'İsim, konum veya hizmet ara...'**
  String get searchPlaceholder;

  /// No description provided for @nearbyBarbers.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki İşletmeler'**
  String get nearbyBarbers;

  /// No description provided for @topRated.
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Puanlı'**
  String get topRated;

  /// No description provided for @topRatedBarbers.
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Puanlılar'**
  String get topRatedBarbers;

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get noResults;

  /// No description provided for @barbersFound.
  ///
  /// In tr, this message translates to:
  /// **'işletme bulundu'**
  String get barbersFound;

  /// No description provided for @filters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In tr, this message translates to:
  /// **'Sırala'**
  String get sortBy;

  /// No description provided for @distance.
  ///
  /// In tr, this message translates to:
  /// **'Mesafe'**
  String get distance;

  /// No description provided for @rating.
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get rating;

  /// No description provided for @priceRange.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Aralığı'**
  String get priceRange;

  /// No description provided for @open.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get closed;

  /// No description provided for @products.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get products;

  /// No description provided for @addToCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepete Ekle'**
  String get addToCart;

  /// No description provided for @viewCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepeti Görüntüle'**
  String get viewCart;

  /// No description provided for @checkout.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme'**
  String get checkout;

  /// No description provided for @total.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get total;

  /// No description provided for @quantity.
  ///
  /// In tr, this message translates to:
  /// **'Adet'**
  String get quantity;

  /// No description provided for @emptyCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepetiniz boş'**
  String get emptyCart;

  /// No description provided for @continueShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışverişe Devam Et'**
  String get continueShopping;

  /// No description provided for @reviews.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get reviews;

  /// No description provided for @writeReview.
  ///
  /// In tr, this message translates to:
  /// **'Yorum Yaz'**
  String get writeReview;

  /// No description provided for @leaveReview.
  ///
  /// In tr, this message translates to:
  /// **'Yorum Bırak'**
  String get leaveReview;

  /// No description provided for @reviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Deneyiminiz nasıldı?'**
  String get reviewTitle;

  /// No description provided for @reviewSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Geri bildiriminiz diğer kullanıcılara yardımcı olur.'**
  String get reviewSubtitle;

  /// No description provided for @skip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get skip;

  /// No description provided for @dashboard.
  ///
  /// In tr, this message translates to:
  /// **'Panel'**
  String get dashboard;

  /// No description provided for @clients.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler'**
  String get clients;

  /// No description provided for @calendar.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get calendar;

  /// No description provided for @posts.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiler'**
  String get posts;

  /// No description provided for @addPost.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi Ekle'**
  String get addPost;

  /// No description provided for @addBranch.
  ///
  /// In tr, this message translates to:
  /// **'Şube Ekle'**
  String get addBranch;

  /// No description provided for @addService.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Ekle'**
  String get addService;

  /// No description provided for @addProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Ekle'**
  String get addProduct;

  /// No description provided for @errorLoadingData.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenirken hata oluştu'**
  String get errorLoadingData;

  /// No description provided for @errorSavingData.
  ///
  /// In tr, this message translates to:
  /// **'Veriler kaydedilirken hata oluştu'**
  String get errorSavingData;

  /// No description provided for @errorDeletingData.
  ///
  /// In tr, this message translates to:
  /// **'Veriler silinirken hata oluştu'**
  String get errorDeletingData;

  /// No description provided for @errorNoInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get errorNoInternet;

  /// No description provided for @errorTimeout.
  ///
  /// In tr, this message translates to:
  /// **'İstek zaman aşımına uğradı'**
  String get errorTimeout;

  /// No description provided for @errorUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen bir hata oluştu'**
  String get errorUnknown;

  /// No description provided for @errorBarbersLoad.
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler yüklenemedi'**
  String get errorBarbersLoad;

  /// No description provided for @errorLocationAccess.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı'**
  String get errorLocationAccess;

  /// No description provided for @onboardingTitle1.
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki İşletmeleri Keşfet'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In tr, this message translates to:
  /// **'Konumunuza en yakın, en iyi işletmeleri kolayca bulun ve inceleyin'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Randevu Al'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In tr, this message translates to:
  /// **'Favori işletmenizden birkaç dokunuşla randevu alın, zamanınızı yönetin'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Satın Al'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerin ürünlerini keşfedin ve kapınıza kadar teslimat ile satın alın'**
  String get onboardingDesc3;

  /// No description provided for @getStarted.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Başla'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get next;

  /// No description provided for @phoneLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ile Giriş'**
  String get phoneLoginTitle;

  /// No description provided for @phoneLoginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranız ve şifrenizle giriş yapın'**
  String get phoneLoginSubtitle;

  /// No description provided for @countryCode.
  ///
  /// In tr, this message translates to:
  /// **'Ülke Kodu'**
  String get countryCode;

  /// No description provided for @countryCodeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ülke kodu gerekli'**
  String get countryCodeRequired;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası gerekli'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası 10 haneli olmalı'**
  String get phoneNumberInvalid;

  /// No description provided for @enterPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi girin'**
  String get enterPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get passwordRequired;

  /// No description provided for @loginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginButton;

  /// No description provided for @signUpPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu?'**
  String get signUpPrompt;

  /// No description provided for @homeTab.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get homeTab;

  /// No description provided for @mapTab.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get mapTab;

  /// No description provided for @cartTab.
  ///
  /// In tr, this message translates to:
  /// **'Sepet'**
  String get cartTab;

  /// No description provided for @appointmentsTab.
  ///
  /// In tr, this message translates to:
  /// **'Randevu'**
  String get appointmentsTab;

  /// No description provided for @marketTab.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get marketTab;

  /// No description provided for @profileTab.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTab;

  /// No description provided for @myCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepetim'**
  String get myCart;

  /// No description provided for @cartEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Sepetiniz Boş'**
  String get cartEmpty;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Alışverişe başlamak için ürünleri sepete ekleyin'**
  String get cartEmptyMessage;

  /// No description provided for @startShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışverişe Başla'**
  String get startShopping;

  /// No description provided for @totalAmount.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Tutar'**
  String get totalAmount;

  /// No description provided for @quantityIncreaseError.
  ///
  /// In tr, this message translates to:
  /// **'Miktar artırılamadı'**
  String get quantityIncreaseError;

  /// No description provided for @quantityDecreaseError.
  ///
  /// In tr, this message translates to:
  /// **'Miktar azaltılamadı'**
  String get quantityDecreaseError;

  /// No description provided for @productRemoved.
  ///
  /// In tr, this message translates to:
  /// **'sepetten çıkarıldı'**
  String get productRemoved;

  /// No description provided for @productRemoveError.
  ///
  /// In tr, this message translates to:
  /// **'Ürün silinemedi'**
  String get productRemoveError;

  /// No description provided for @confirmCart.
  ///
  /// In tr, this message translates to:
  /// **'Sepeti Onayla'**
  String get confirmCart;

  /// No description provided for @checkoutComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme akışı yakında eklenecek'**
  String get checkoutComingSoon;

  /// No description provided for @deliveryType.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Tipi'**
  String get deliveryType;

  /// No description provided for @pickup.
  ///
  /// In tr, this message translates to:
  /// **'Mağazadan Al'**
  String get pickup;

  /// No description provided for @delivery.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat'**
  String get delivery;

  /// No description provided for @selectBranch.
  ///
  /// In tr, this message translates to:
  /// **'Şube Seçin'**
  String get selectBranch;

  /// No description provided for @deliveryAddress.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Adresi'**
  String get deliveryAddress;

  /// No description provided for @paymentMethod.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Yöntemi'**
  String get paymentMethod;

  /// No description provided for @cardPayment.
  ///
  /// In tr, this message translates to:
  /// **'Kredi/Banka Kartı'**
  String get cardPayment;

  /// No description provided for @cashPayment.
  ///
  /// In tr, this message translates to:
  /// **'Nakit'**
  String get cashPayment;

  /// No description provided for @cardNumber.
  ///
  /// In tr, this message translates to:
  /// **'Kart Numarası'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In tr, this message translates to:
  /// **'Son Kullanma Tarihi'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In tr, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cardHolderName.
  ///
  /// In tr, this message translates to:
  /// **'Kart Sahibi Adı'**
  String get cardHolderName;

  /// No description provided for @completePayment.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeyi Tamamla'**
  String get completePayment;

  /// No description provided for @processingPayment.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme işleniyor...'**
  String get processingPayment;

  /// No description provided for @orderPlaced.
  ///
  /// In tr, this message translates to:
  /// **'Siparişiniz Alındı'**
  String get orderPlaced;

  /// No description provided for @orderNumber.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Numarası'**
  String get orderNumber;

  /// No description provided for @orderSummary.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Özeti'**
  String get orderSummary;

  /// No description provided for @myOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get myOrders;

  /// No description provided for @orders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler'**
  String get orders;

  /// No description provided for @marketTitle.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get marketTitle;

  /// No description provided for @marketSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güzellik ve bakım ürünleri'**
  String get marketSubtitle;

  /// No description provided for @categories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// No description provided for @categoriesLoading.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler yükleniyor...'**
  String get categoriesLoading;

  /// No description provided for @noCategoriesFound.
  ///
  /// In tr, this message translates to:
  /// **'Kategori bulunamadı'**
  String get noCategoriesFound;

  /// No description provided for @featuredProducts.
  ///
  /// In tr, this message translates to:
  /// **'Öne Çıkanlar'**
  String get featuredProducts;

  /// No description provided for @seeAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Gör'**
  String get seeAll;

  /// No description provided for @allProducts.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Ürünler'**
  String get allProducts;

  /// No description provided for @productsLoading.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler yükleniyor...'**
  String get productsLoading;

  /// No description provided for @noProductsFound.
  ///
  /// In tr, this message translates to:
  /// **'Ürün bulunamadı'**
  String get noProductsFound;

  /// No description provided for @searchProductPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı veya kategori ara...'**
  String get searchProductPlaceholder;

  /// No description provided for @featuredProductsLoading.
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkan ürünler yükleniyor...'**
  String get featuredProductsLoading;

  /// No description provided for @searchBarberPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'İşletme, hizmet ara...'**
  String get searchBarberPlaceholder;

  /// No description provided for @activeStatus.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get activeStatus;

  /// No description provided for @mainBranchLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ana Şube'**
  String get mainBranchLabel;

  /// No description provided for @favoriteCompanies.
  ///
  /// In tr, this message translates to:
  /// **'Favori İşletmelerim'**
  String get favoriteCompanies;

  /// No description provided for @appointmentButton.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Al'**
  String get appointmentButton;

  /// No description provided for @detailsButton.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get detailsButton;

  /// No description provided for @barberDefaultName.
  ///
  /// In tr, this message translates to:
  /// **'İşletme'**
  String get barberDefaultName;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap ayarlarınızı yönetin'**
  String get profileSubtitle;

  /// No description provided for @manageAccountSettings.
  ///
  /// In tr, this message translates to:
  /// **'Hesap ayarlarınızı yönetin'**
  String get manageAccountSettings;

  /// No description provided for @comments.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get comments;

  /// No description provided for @myAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Randevularım'**
  String get myAppointments;

  /// No description provided for @myFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get myFavorites;

  /// No description provided for @pastFutureAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş ve gelecek randevular'**
  String get pastFutureAppointments;

  /// No description provided for @likedBarbers.
  ///
  /// In tr, this message translates to:
  /// **'Beğendiğim işletmeler'**
  String get likedBarbers;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @userNameLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get userNameLoading;

  /// No description provided for @userNameDefault.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı'**
  String get userNameDefault;

  /// No description provided for @showOnMap.
  ///
  /// In tr, this message translates to:
  /// **'Yol Tarifi Al'**
  String get showOnMap;

  /// No description provided for @ourServices.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetlerimiz'**
  String get ourServices;

  /// No description provided for @hour.
  ///
  /// In tr, this message translates to:
  /// **'sa'**
  String get hour;

  /// No description provided for @minutes.
  ///
  /// In tr, this message translates to:
  /// **'dakika'**
  String get minutes;

  /// No description provided for @minuteShort.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get minuteShort;

  /// No description provided for @free.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get free;

  /// No description provided for @serviceDefaultName.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet'**
  String get serviceDefaultName;

  /// No description provided for @noLocationInfo.
  ///
  /// In tr, this message translates to:
  /// **'Konum bilgisi yok'**
  String get noLocationInfo;

  /// No description provided for @noImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel Yok'**
  String get noImage;

  /// No description provided for @noFeatureInfo.
  ///
  /// In tr, this message translates to:
  /// **'Henüz özellik bilgisi bulunmuyor'**
  String get noFeatureInfo;

  /// No description provided for @commentsTab.
  ///
  /// In tr, this message translates to:
  /// **'Yorumlar'**
  String get commentsTab;

  /// No description provided for @postsTab.
  ///
  /// In tr, this message translates to:
  /// **'Posts'**
  String get postsTab;

  /// No description provided for @allFilters.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get allFilters;

  /// No description provided for @starsFilter.
  ///
  /// In tr, this message translates to:
  /// **'4+ Yıldız'**
  String get starsFilter;

  /// No description provided for @starsFilter45.
  ///
  /// In tr, this message translates to:
  /// **'4.5+ Yıldız'**
  String get starsFilter45;

  /// No description provided for @onlyOpenFilter.
  ///
  /// In tr, this message translates to:
  /// **'Sadece Açık'**
  String get onlyOpenFilter;

  /// No description provided for @barbersLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İşletmeler yüklenemedi'**
  String get barbersLoadError;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Konum İzni Gerekli'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki işletmeleri görebilmek için konum iznine ihtiyacımız var. İzin vermek için ayarlara gidebilirsiniz.'**
  String get locationPermissionMessage;

  /// No description provided for @later.
  ///
  /// In tr, this message translates to:
  /// **'Daha Sonra'**
  String get later;

  /// No description provided for @goToSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlara Git'**
  String get goToSettings;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim İzni Gerekli'**
  String get notificationPermissionRequired;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In tr, this message translates to:
  /// **'Randevu hatırlatmaları ve önemli bildirimler alabilmek için bildirim iznine ihtiyacımız var. İzin vermek için ayarlara gidebilirsiniz.'**
  String get notificationPermissionMessage;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi gerekli'**
  String get emailRequired;

  /// No description provided for @validEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin'**
  String get validEmail;

  /// No description provided for @phoneNumber10Digits.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası 10 haneli olmalı'**
  String get phoneNumber10Digits;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @january.
  ///
  /// In tr, this message translates to:
  /// **'Ocak'**
  String get january;

  /// No description provided for @february.
  ///
  /// In tr, this message translates to:
  /// **'Şubat'**
  String get february;

  /// No description provided for @march.
  ///
  /// In tr, this message translates to:
  /// **'Mart'**
  String get march;

  /// No description provided for @april.
  ///
  /// In tr, this message translates to:
  /// **'Nisan'**
  String get april;

  /// No description provided for @may.
  ///
  /// In tr, this message translates to:
  /// **'Mayıs'**
  String get may;

  /// No description provided for @june.
  ///
  /// In tr, this message translates to:
  /// **'Haziran'**
  String get june;

  /// No description provided for @july.
  ///
  /// In tr, this message translates to:
  /// **'Temmuz'**
  String get july;

  /// No description provided for @august.
  ///
  /// In tr, this message translates to:
  /// **'Ağustos'**
  String get august;

  /// No description provided for @september.
  ///
  /// In tr, this message translates to:
  /// **'Eylül'**
  String get september;

  /// No description provided for @october.
  ///
  /// In tr, this message translates to:
  /// **'Ekim'**
  String get october;

  /// No description provided for @november.
  ///
  /// In tr, this message translates to:
  /// **'Kasım'**
  String get november;

  /// No description provided for @december.
  ///
  /// In tr, this message translates to:
  /// **'Aralık'**
  String get december;

  /// No description provided for @welcomeBack.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Hoşgeldin'**
  String get welcomeBack;

  /// No description provided for @welcomeBackSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabına giriş yap ve keşfetmeye devam et'**
  String get welcomeBackSubtitle;

  /// No description provided for @emailPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresinizi girin'**
  String get emailPlaceholder;

  /// No description provided for @accountVerification.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Doğrulama'**
  String get accountVerification;

  /// No description provided for @accountVerificationMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu telefon numarası ile kayıt olmuş olabilirsiniz, ancak SMS doğrulaması yapılmamış. SMS doğrulama sayfasına gitmek ister misiniz?'**
  String get accountVerificationMessage;

  /// No description provided for @smsSendError.
  ///
  /// In tr, this message translates to:
  /// **'SMS gönderilemedi'**
  String get smsSendError;

  /// No description provided for @noServicesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Hizmet Yok'**
  String get noServicesYet;

  /// No description provided for @noServicesMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu işletme için henüz hizmet tanımlanmamış'**
  String get noServicesMessage;

  /// No description provided for @barberSalon.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Salonu'**
  String get barberSalon;

  /// No description provided for @addedToFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere eklendi'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkarıldı'**
  String get removedFromFavorites;

  /// No description provided for @markAllAsRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Okundu İşaretle'**
  String get markAllAsRead;

  /// No description provided for @notificationsLoading.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler yükleniyor...'**
  String get notificationsLoading;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir Hata Oluştu'**
  String get errorOccurred;

  /// No description provided for @notificationsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler yüklenirken bir hata oluştu'**
  String get notificationsLoadError;

  /// No description provided for @customerRegisterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Kaydı'**
  String get customerRegisterTitle;

  /// No description provided for @customerRegisterSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı oluşturun ve işletmeleri keşfetmeye başlayın'**
  String get customerRegisterSubtitle;

  /// No description provided for @companyRegisterTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Kaydı'**
  String get companyRegisterTitle;

  /// No description provided for @companyRegisterSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletmenizi kaydedin ve şubelerinizi yönetin'**
  String get companyRegisterSubtitle;

  /// No description provided for @personalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get personalInfo;

  /// No description provided for @firstName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get lastName;

  /// No description provided for @firstNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad gereklidir'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Soyad gereklidir'**
  String get lastNameRequired;

  /// No description provided for @enterFirstName.
  ///
  /// In tr, this message translates to:
  /// **'Adınızı girin'**
  String get enterFirstName;

  /// No description provided for @enterLastName.
  ///
  /// In tr, this message translates to:
  /// **'Soyadınızı girin'**
  String get enterLastName;

  /// No description provided for @enterEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresinizi girin'**
  String get enterEmail;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'555 555 5555'**
  String get enterPhoneNumber;

  /// No description provided for @enterPasswordPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi girin'**
  String get enterPasswordPlaceholder;

  /// No description provided for @confirmPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre tekrarı gerekli'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDoNotMatch;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi tekrar girin'**
  String get enterConfirmPassword;

  /// No description provided for @gender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get gender;

  /// No description provided for @selectGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet Seçin'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get male;

  /// No description provided for @female.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get female;

  /// No description provided for @other.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get other;

  /// No description provided for @none.
  ///
  /// In tr, this message translates to:
  /// **'Belirtmek istemiyorum'**
  String get none;

  /// No description provided for @corporate.
  ///
  /// In tr, this message translates to:
  /// **'Kurumsal'**
  String get corporate;

  /// No description provided for @messages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get messages;

  /// No description provided for @welcomeCompany.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcomeCompany;

  /// No description provided for @welcomeCompanySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İşletmenizin yönetim paneli'**
  String get welcomeCompanySubtitle;

  /// No description provided for @activeAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Randevu'**
  String get activeAppointments;

  /// No description provided for @recentBranches.
  ///
  /// In tr, this message translates to:
  /// **'Son Eklenen Şubeler'**
  String get recentBranches;

  /// No description provided for @quickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı İşlemler'**
  String get quickActions;

  /// No description provided for @noBranchesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz şube eklenmemiş'**
  String get noBranchesYet;

  /// No description provided for @noBranchesMessage.
  ///
  /// In tr, this message translates to:
  /// **'İlk şubenizi eklemek için \"Yeni Şube\" butonuna tıklayın'**
  String get noBranchesMessage;

  /// No description provided for @branchesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Şubeler yüklenemedi'**
  String get branchesLoadError;

  /// No description provided for @inactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get inactive;

  /// No description provided for @newBranch.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şube'**
  String get newBranch;

  /// No description provided for @searchBranchPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Şube adı giriniz'**
  String get searchBranchPlaceholder;

  /// No description provided for @branchCount.
  ///
  /// In tr, this message translates to:
  /// **'şube'**
  String get branchCount;

  /// No description provided for @branch.
  ///
  /// In tr, this message translates to:
  /// **'Şube'**
  String get branch;

  /// No description provided for @enterBranchName.
  ///
  /// In tr, this message translates to:
  /// **'Şube adı giriniz'**
  String get enterBranchName;

  /// No description provided for @appointmentCount.
  ///
  /// In tr, this message translates to:
  /// **'randevu'**
  String get appointmentCount;

  /// No description provided for @allBranches.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Şubeler'**
  String get allBranches;

  /// No description provided for @dayAbbreviationMon.
  ///
  /// In tr, this message translates to:
  /// **'Pzt'**
  String get dayAbbreviationMon;

  /// No description provided for @dayAbbreviationTue.
  ///
  /// In tr, this message translates to:
  /// **'Sal'**
  String get dayAbbreviationTue;

  /// No description provided for @dayAbbreviationWed.
  ///
  /// In tr, this message translates to:
  /// **'Çar'**
  String get dayAbbreviationWed;

  /// No description provided for @dayAbbreviationThu.
  ///
  /// In tr, this message translates to:
  /// **'Per'**
  String get dayAbbreviationThu;

  /// No description provided for @dayAbbreviationFri.
  ///
  /// In tr, this message translates to:
  /// **'Cum'**
  String get dayAbbreviationFri;

  /// No description provided for @dayAbbreviationSat.
  ///
  /// In tr, this message translates to:
  /// **'Cmt'**
  String get dayAbbreviationSat;

  /// No description provided for @dayAbbreviationSun.
  ///
  /// In tr, this message translates to:
  /// **'Paz'**
  String get dayAbbreviationSun;

  /// No description provided for @monthAbbreviationJan.
  ///
  /// In tr, this message translates to:
  /// **'Oca'**
  String get monthAbbreviationJan;

  /// No description provided for @monthAbbreviationFeb.
  ///
  /// In tr, this message translates to:
  /// **'Şub'**
  String get monthAbbreviationFeb;

  /// No description provided for @monthAbbreviationMar.
  ///
  /// In tr, this message translates to:
  /// **'Mar'**
  String get monthAbbreviationMar;

  /// No description provided for @monthAbbreviationApr.
  ///
  /// In tr, this message translates to:
  /// **'Nis'**
  String get monthAbbreviationApr;

  /// No description provided for @monthAbbreviationMay.
  ///
  /// In tr, this message translates to:
  /// **'May'**
  String get monthAbbreviationMay;

  /// No description provided for @monthAbbreviationJun.
  ///
  /// In tr, this message translates to:
  /// **'Haz'**
  String get monthAbbreviationJun;

  /// No description provided for @monthAbbreviationJul.
  ///
  /// In tr, this message translates to:
  /// **'Tem'**
  String get monthAbbreviationJul;

  /// No description provided for @monthAbbreviationAug.
  ///
  /// In tr, this message translates to:
  /// **'Ağu'**
  String get monthAbbreviationAug;

  /// No description provided for @monthAbbreviationSep.
  ///
  /// In tr, this message translates to:
  /// **'Eyl'**
  String get monthAbbreviationSep;

  /// No description provided for @monthAbbreviationOct.
  ///
  /// In tr, this message translates to:
  /// **'Eki'**
  String get monthAbbreviationOct;

  /// No description provided for @monthAbbreviationNov.
  ///
  /// In tr, this message translates to:
  /// **'Kas'**
  String get monthAbbreviationNov;

  /// No description provided for @monthAbbreviationDec.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get monthAbbreviationDec;

  /// No description provided for @canceled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get canceled;

  /// No description provided for @details.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get details;

  /// No description provided for @customerMessages.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Mesajları'**
  String get customerMessages;

  /// No description provided for @selectBranchToViewMessages.
  ///
  /// In tr, this message translates to:
  /// **'Mesajları görüntülemek için önce bir şube seçin'**
  String get selectBranchToViewMessages;

  /// No description provided for @messagesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar yüklenemedi'**
  String get messagesLoadError;

  /// No description provided for @noMessagesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok'**
  String get noMessagesYet;

  /// No description provided for @barberInfo.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Bilgileri'**
  String get barberInfo;

  /// No description provided for @currentCompanyData.
  ///
  /// In tr, this message translates to:
  /// **'Güncel şirket verileriniz'**
  String get currentCompanyData;

  /// No description provided for @barberName.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Adı'**
  String get barberName;

  /// No description provided for @manageServices.
  ///
  /// In tr, this message translates to:
  /// **'Sunulan hizmetleri yönetin'**
  String get manageServices;

  /// No description provided for @generalWorkingHoursSettings.
  ///
  /// In tr, this message translates to:
  /// **'Genel çalışma saatleri ayarları'**
  String get generalWorkingHoursSettings;

  /// No description provided for @editBranch.
  ///
  /// In tr, this message translates to:
  /// **'Şube Düzenle'**
  String get editBranch;

  /// No description provided for @editService.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Düzenle'**
  String get editService;

  /// No description provided for @editProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Düzenle'**
  String get editProduct;

  /// No description provided for @required.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu'**
  String get required;

  /// No description provided for @cash.
  ///
  /// In tr, this message translates to:
  /// **'Nakit'**
  String get cash;

  /// No description provided for @creditCard.
  ///
  /// In tr, this message translates to:
  /// **'Kredi Kartı'**
  String get creditCard;

  /// No description provided for @monday.
  ///
  /// In tr, this message translates to:
  /// **'Pazartesi'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In tr, this message translates to:
  /// **'Salı'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In tr, this message translates to:
  /// **'Çarşamba'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In tr, this message translates to:
  /// **'Perşembe'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In tr, this message translates to:
  /// **'Cuma'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In tr, this message translates to:
  /// **'Cumartesi'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In tr, this message translates to:
  /// **'Pazar'**
  String get sunday;

  /// No description provided for @open247.
  ///
  /// In tr, this message translates to:
  /// **'7/24 Açık'**
  String get open247;

  /// No description provided for @passwordLengthError.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordLengthError;

  /// No description provided for @branchNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Şube bulunamadı'**
  String get branchNotFound;

  /// No description provided for @noBranchMatchSearch.
  ///
  /// In tr, this message translates to:
  /// **'Arama kriterlerinize uygun şube bulunamadı'**
  String get noBranchMatchSearch;

  /// No description provided for @addFirstBranchMessage.
  ///
  /// In tr, this message translates to:
  /// **'İlk şubenizi eklemek için + butonuna tıklayın'**
  String get addFirstBranchMessage;

  /// No description provided for @appointmentCountSingular.
  ///
  /// In tr, this message translates to:
  /// **'randevu'**
  String get appointmentCountSingular;

  /// No description provided for @appointmentsLoading.
  ///
  /// In tr, this message translates to:
  /// **'Randevularınız yükleniyor...'**
  String get appointmentsLoading;

  /// No description provided for @noAppointmentsMatchFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtreye uygun randevu bulunamadı'**
  String get noAppointmentsMatchFilter;

  /// No description provided for @noAppointmentsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz randevu yok'**
  String get noAppointmentsYet;

  /// No description provided for @tryDifferentDateOrBranch.
  ///
  /// In tr, this message translates to:
  /// **'Farklı bir tarih veya şube seçerek tekrar deneyin'**
  String get tryDifferentDateOrBranch;

  /// No description provided for @appointmentsWillAppearHere.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler randevu aldığında burada görünecek'**
  String get appointmentsWillAppearHere;

  /// No description provided for @cancelAppointmentForCustomer.
  ///
  /// In tr, this message translates to:
  /// **'{customerName} adlı müşterinin randevusunu iptal etmek istediğinizden emin misiniz?'**
  String cancelAppointmentForCustomer(String customerName);

  /// No description provided for @appointmentCancelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Randevuyu İptal Et'**
  String get appointmentCancelTitle;

  /// No description provided for @dakika.
  ///
  /// In tr, this message translates to:
  /// **'dakika'**
  String get dakika;

  /// No description provided for @customerInformation.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Bilgileri'**
  String get customerInformation;

  /// No description provided for @appointmentInformation.
  ///
  /// In tr, this message translates to:
  /// **'Randevu Bilgileri'**
  String get appointmentInformation;

  /// No description provided for @dateAndTime.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve Saat'**
  String get dateAndTime;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'İsim Soyisim'**
  String get fullName;

  /// No description provided for @branchesLoading.
  ///
  /// In tr, this message translates to:
  /// **'Şubeler yükleniyor...'**
  String get branchesLoading;

  /// No description provided for @noBranchesFoundYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz şube bulunamadı'**
  String get noBranchesFoundYet;

  /// No description provided for @messagesLoading.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar yükleniyor...'**
  String get messagesLoading;

  /// No description provided for @anErrorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu'**
  String get anErrorOccurred;

  /// No description provided for @noMessagesYetForBranch.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir mesajınız yok'**
  String get noMessagesYetForBranch;

  /// No description provided for @customerMessagesWillAppearHere.
  ///
  /// In tr, this message translates to:
  /// **'Müşterilerinizden gelen mesajlar\nburada görünecek'**
  String get customerMessagesWillAppearHere;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu almak için telefon numaranızı girin'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordVerifyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kodu Doğrula'**
  String get forgotPasswordVerifyTitle;

  /// No description provided for @forgotPasswordVerifySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonunuza gönderilen doğrulama kodunu girin'**
  String get forgotPasswordVerifySubtitle;

  /// No description provided for @forgotPasswordResetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Sıfırla'**
  String get forgotPasswordResetTitle;

  /// No description provided for @forgotPasswordResetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi sıfırlamak için bilgilerinizi girin'**
  String get forgotPasswordResetSubtitle;

  /// No description provided for @smsCodeSent.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu gönderildi'**
  String get smsCodeSent;

  /// No description provided for @smsCodeSentMessage.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranıza bir doğrulama kodu gönderildi'**
  String get smsCodeSentMessage;

  /// No description provided for @codeVerified.
  ///
  /// In tr, this message translates to:
  /// **'Kod doğrulandı'**
  String get codeVerified;

  /// No description provided for @codeVerifiedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kodunuz başarıyla doğrulandı'**
  String get codeVerifiedMessage;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama başarılı'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetSuccessMessage.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz başarıyla sıfırlandı. Artık yeni şifrenizle giriş yapabilirsiniz.'**
  String get passwordResetSuccessMessage;

  /// No description provided for @enterSmsCode.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodunu girin'**
  String get enterSmsCode;

  /// No description provided for @smsCodeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu gerekli'**
  String get smsCodeRequired;

  /// No description provided for @smsCodeInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu 6 haneli olmalı'**
  String get smsCodeInvalid;

  /// No description provided for @newPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifrenizi girin'**
  String get enterNewPassword;

  /// No description provided for @iban.
  ///
  /// In tr, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @enterIban.
  ///
  /// In tr, this message translates to:
  /// **'IBAN numaranızı girin'**
  String get enterIban;

  /// No description provided for @ibanRequired.
  ///
  /// In tr, this message translates to:
  /// **'IBAN gerekli'**
  String get ibanRequired;

  /// No description provided for @resetPasswordButton.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Sıfırla'**
  String get resetPasswordButton;

  /// No description provided for @backToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Sayfasına Dön'**
  String get backToLogin;

  /// No description provided for @continueWithoutSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Üye olmadan devam et'**
  String get continueWithoutSignUp;

  /// No description provided for @mustSignUpFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce üye olmalısınız'**
  String get mustSignUpFirst;

  /// No description provided for @mustSignUpFirstMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sepete ürün eklemek için önce üye olmanız gerekiyor.'**
  String get mustSignUpFirstMessage;

  /// No description provided for @goToSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get goToSignUp;

  /// No description provided for @pleaseSignInOrSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapın ya da kayıt olun'**
  String get pleaseSignInOrSignUp;

  /// No description provided for @pleaseSignInOrSignUpMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu özelliği kullanmak için giriş yapmanız veya kayıt olmanız gerekiyor.'**
  String get pleaseSignInOrSignUpMessage;

  /// No description provided for @toUseFeature.
  ///
  /// In tr, this message translates to:
  /// **'{featureName} özelliğini kullanmak için.'**
  String toUseFeature(String featureName);

  /// No description provided for @referenceCode.
  ///
  /// In tr, this message translates to:
  /// **'Referans Kodu'**
  String get referenceCode;

  /// No description provided for @referenceCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'6 haneli kod girin'**
  String get referenceCodeHint;

  /// No description provided for @referenceCodeOptional.
  ///
  /// In tr, this message translates to:
  /// **'Referans Kodu (Opsiyonel)'**
  String get referenceCodeOptional;

  /// No description provided for @referenceNumberCopied.
  ///
  /// In tr, this message translates to:
  /// **'Referans numarası kopyalandı'**
  String get referenceNumberCopied;

  /// No description provided for @myReferenceNumber.
  ///
  /// In tr, this message translates to:
  /// **'Referans Numaram'**
  String get myReferenceNumber;

  /// No description provided for @referralInviteHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir arkadaşınız sizi davet ettiyse kodunu girin'**
  String get referralInviteHint;

  /// No description provided for @employees.
  ///
  /// In tr, this message translates to:
  /// **'Çalışanlar'**
  String get employees;

  /// No description provided for @followingList.
  ///
  /// In tr, this message translates to:
  /// **'Takip Ettiklerim'**
  String get followingList;

  /// No description provided for @followingListSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Takip ettiğiniz işletmeler'**
  String get followingListSubtitle;

  /// No description provided for @myAddresses.
  ///
  /// In tr, this message translates to:
  /// **'Adreslerim'**
  String get myAddresses;

  /// No description provided for @deliveryAddresses.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Adresleri'**
  String get deliveryAddresses;

  /// No description provided for @invoiceAddresses.
  ///
  /// In tr, this message translates to:
  /// **'Fatura Adresleri'**
  String get invoiceAddresses;

  /// No description provided for @noAddressYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz adres eklenmemiş'**
  String get noAddressYet;

  /// No description provided for @addAddressPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Yeni adres eklemek için alttaki butona tıklayın'**
  String get addAddressPrompt;

  /// No description provided for @addNewAddress.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Adres Ekle'**
  String get addNewAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In tr, this message translates to:
  /// **'Adresi Sil'**
  String get deleteAddress;

  /// No description provided for @deleteAddressConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu adresi silmek istediğinizden emin misiniz?'**
  String get deleteAddressConfirm;

  /// No description provided for @addressDeletedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Adres başarıyla silindi'**
  String get addressDeletedSuccess;

  /// No description provided for @editAddress.
  ///
  /// In tr, this message translates to:
  /// **'Adres Düzenle'**
  String get editAddress;

  /// No description provided for @addressType.
  ///
  /// In tr, this message translates to:
  /// **'Adres Tipi'**
  String get addressType;

  /// No description provided for @invoice.
  ///
  /// In tr, this message translates to:
  /// **'Fatura'**
  String get invoice;

  /// No description provided for @addressName.
  ///
  /// In tr, this message translates to:
  /// **'Adres Adı'**
  String get addressName;

  /// No description provided for @addressNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ev, İş, Anne Evi'**
  String get addressNameHint;

  /// No description provided for @addressNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Adres adı gereklidir'**
  String get addressNameRequired;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @phoneRequired.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası gereklidir'**
  String get phoneRequired;

  /// No description provided for @phoneMustBe10Digits.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası 10 haneli olmalıdır'**
  String get phoneMustBe10Digits;

  /// No description provided for @country.
  ///
  /// In tr, this message translates to:
  /// **'Ülke'**
  String get country;

  /// No description provided for @selectCountry.
  ///
  /// In tr, this message translates to:
  /// **'Ülke seçin'**
  String get selectCountry;

  /// No description provided for @countryRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ülke seçimi gereklidir'**
  String get countryRequired;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'Şehir'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In tr, this message translates to:
  /// **'Şehir seçin'**
  String get selectCity;

  /// No description provided for @selectCountryFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce ülke seçin'**
  String get selectCountryFirst;

  /// No description provided for @cityRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şehir seçimi gereklidir'**
  String get cityRequired;

  /// No description provided for @address.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı adres bilgisi'**
  String get addressHint;

  /// No description provided for @addressRequired.
  ///
  /// In tr, this message translates to:
  /// **'Adres gereklidir'**
  String get addressRequired;

  /// No description provided for @addressUpdatedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Adres başarıyla güncellendi'**
  String get addressUpdatedSuccess;

  /// No description provided for @addressAddedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Adres başarıyla eklendi'**
  String get addressAddedSuccess;

  /// No description provided for @selectCountryError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir ülke seçin'**
  String get selectCountryError;

  /// No description provided for @selectCityError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir şehir seçin'**
  String get selectCityError;

  /// No description provided for @errorLoadingCountries.
  ///
  /// In tr, this message translates to:
  /// **'Ülkeler yüklenirken hata'**
  String get errorLoadingCountries;

  /// No description provided for @errorLoadingCities.
  ///
  /// In tr, this message translates to:
  /// **'Şehirler yüklenirken hata'**
  String get errorLoadingCities;

  /// No description provided for @viewAllOrdersHere.
  ///
  /// In tr, this message translates to:
  /// **'Tüm siparişlerinizi buradan görüntüleyin'**
  String get viewAllOrdersHere;

  /// No description provided for @allOrders.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get allOrders;

  /// No description provided for @pendingOrders.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get pendingOrders;

  /// No description provided for @completedOrders.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get completedOrders;

  /// No description provided for @cancelledOrders.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancelledOrders;

  /// No description provided for @noOrders.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Yok'**
  String get noOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sipariş vermediniz'**
  String get noOrdersYet;

  /// No description provided for @noPendingOrders.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Sipariş Yok'**
  String get noPendingOrders;

  /// No description provided for @noPendingOrdersDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen siparişleriniz burada görünecek'**
  String get noPendingOrdersDesc;

  /// No description provided for @noCompletedOrders.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan Sipariş Yok'**
  String get noCompletedOrders;

  /// No description provided for @noCompletedOrdersDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan siparişleriniz burada görünecek'**
  String get noCompletedOrdersDesc;

  /// No description provided for @noCancelledOrders.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edilen Sipariş Yok'**
  String get noCancelledOrders;

  /// No description provided for @noCancelledOrdersDesc.
  ///
  /// In tr, this message translates to:
  /// **'İptal ettiğiniz siparişler burada görünecek'**
  String get noCancelledOrdersDesc;

  /// No description provided for @ordersLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler yüklenemedi'**
  String get ordersLoadError;

  /// No description provided for @helpAndSupport.
  ///
  /// In tr, this message translates to:
  /// **'Yardım & Destek'**
  String get helpAndSupport;

  /// No description provided for @contact.
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get contact;

  /// No description provided for @mondayToFriday.
  ///
  /// In tr, this message translates to:
  /// **'Pazartesi - Cuma: 09:00 - 18:00'**
  String get mondayToFriday;

  /// No description provided for @sendSupportRequest.
  ///
  /// In tr, this message translates to:
  /// **'Destek Talebi Gönder'**
  String get sendSupportRequest;

  /// No description provided for @faq.
  ///
  /// In tr, this message translates to:
  /// **'Sıkça Sorulan Sorular'**
  String get faq;

  /// No description provided for @faqLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Sık sorulan sorular yüklenirken bir hata oluştu.'**
  String get faqLoadError;

  /// No description provided for @noFaqYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz sık sorulan soru bulunmuyor.'**
  String get noFaqYet;

  /// No description provided for @whatsappOpenError.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp açılamadı, lütfen manuel olarak arayın.'**
  String get whatsappOpenError;

  /// No description provided for @aboutApp.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutApp;

  /// No description provided for @businessAppointmentApp.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Randevu Uygulaması'**
  String get businessAppointmentApp;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'En yakın işletmeyi bulun, randevu alın ve güzel görünün.'**
  String get appTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In tr, this message translates to:
  /// **'M&W, işletme ve randevu yönetimi için tasarıanmış modern bir mobil uygulamadır. Kullanıcılarımıza en yakın işletmeleri bulma, randevu alma ve hizmetleri kolaylıkla yönetme imkanı sunuyoruz. Uygulamamiz, hem müşteriler hem de işletmeler için kullanıcı dostu bir deneyim sağlamayı hedeflemektedir.'**
  String get aboutDescription;

  /// No description provided for @legalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Yasal Bilgiler'**
  String get legalInfo;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel verilerinizin korunması'**
  String get privacyPolicyDesc;

  /// No description provided for @termsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get termsOfUse;

  /// No description provided for @termsOfUseDesc.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kullanım şartları'**
  String get termsOfUseDesc;

  /// No description provided for @termsAcceptance.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları\'nı okudum ve kabul ediyorum'**
  String get termsAcceptance;

  /// No description provided for @termsAcceptanceRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için Kullanım Koşulları\'nı kabul etmelisiniz'**
  String get termsAcceptanceRequired;

  /// No description provided for @socialMedia.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal Medya'**
  String get socialMedia;

  /// No description provided for @manageAllAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Tüm randevularını buradan yönet'**
  String get manageAllAppointments;

  /// No description provided for @upcoming.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get past;

  /// No description provided for @cancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancelled;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan Randevu Yok'**
  String get noUpcomingAppointments;

  /// No description provided for @sortNearest.
  ///
  /// In tr, this message translates to:
  /// **'En Yakın'**
  String get sortNearest;

  /// No description provided for @sortHighestRated.
  ///
  /// In tr, this message translates to:
  /// **'En Yüksek Puanlı'**
  String get sortHighestRated;

  /// No description provided for @mapLoading.
  ///
  /// In tr, this message translates to:
  /// **'Harita yükleniyor...'**
  String get mapLoading;

  /// No description provided for @plusMore.
  ///
  /// In tr, this message translates to:
  /// **'+{count} daha'**
  String plusMore(int count);

  /// No description provided for @following.
  ///
  /// In tr, this message translates to:
  /// **'Takip Ediliyor'**
  String get following;

  /// No description provided for @follow.
  ///
  /// In tr, this message translates to:
  /// **'Takip Et'**
  String get follow;

  /// No description provided for @followers.
  ///
  /// In tr, this message translates to:
  /// **'{count} Takipçi'**
  String followers(int count);

  /// No description provided for @noPostsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz paylaşım bulunmuyor'**
  String get noPostsYet;

  /// No description provided for @noPostsMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu salon henüz hiç gönderi paylaşmamış'**
  String get noPostsMessage;

  /// No description provided for @noCommentsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yorum yok'**
  String get noCommentsYet;

  /// No description provided for @features.
  ///
  /// In tr, this message translates to:
  /// **'Özellikler'**
  String get features;

  /// No description provided for @createNewAppointment.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir randevu oluşturun'**
  String get createNewAppointment;

  /// No description provided for @noPastAppointments.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Randevu Yok'**
  String get noPastAppointments;

  /// No description provided for @completedAppointmentsWillAppearHere.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan randevularınız burada görünecek'**
  String get completedAppointmentsWillAppearHere;

  /// No description provided for @noCancelledAppointments.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edilen Randevu Yok'**
  String get noCancelledAppointments;

  /// No description provided for @cancelledAppointmentsWillAppearHere.
  ///
  /// In tr, this message translates to:
  /// **'İptal ettiğiniz randevular burada görünecek'**
  String get cancelledAppointmentsWillAppearHere;

  /// No description provided for @pleaseWait.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bekleyin'**
  String get pleaseWait;

  /// No description provided for @appointmentsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Randevular yüklenemedi'**
  String get appointmentsLoadError;

  /// No description provided for @appointmentCancelledSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Randevu başarıyla iptal edildi'**
  String get appointmentCancelledSuccess;

  /// No description provided for @thankYouForRating.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeniz için teşekkürler!'**
  String get thankYouForRating;

  /// No description provided for @deleteChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbeti Sil'**
  String get deleteChat;

  /// No description provided for @deleteEmployee.
  ///
  /// In tr, this message translates to:
  /// **'Çalışanı Sil'**
  String get deleteEmployee;

  /// No description provided for @deletePost.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiyi Sil'**
  String get deletePost;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı Sil'**
  String get deleteAccount;

  /// No description provided for @editProfileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil Düzenle'**
  String get editProfileTitle;

  /// No description provided for @editIban.
  ///
  /// In tr, this message translates to:
  /// **'IBAN Bilgilerinizi Düzenleyin'**
  String get editIban;

  /// No description provided for @editProductTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü Düzenle'**
  String get editProductTitle;

  /// No description provided for @addNewImages.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Görseller Ekle'**
  String get addNewImages;

  /// No description provided for @addNewImage.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Resim Ekle'**
  String get addNewImage;

  /// No description provided for @branchNotFoundError.
  ///
  /// In tr, this message translates to:
  /// **'Şube bulunamadı. Lütfen önce şube oluşturun.'**
  String get branchNotFoundError;

  /// No description provided for @branchInfoNotAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Şube bilgileri mevcut değil'**
  String get branchInfoNotAvailable;

  /// No description provided for @companyInfoNotFound.
  ///
  /// In tr, this message translates to:
  /// **'İşletme bilgisi bulunamadı. Lütfen sayfayı yenileyin.'**
  String get companyInfoNotFound;

  /// No description provided for @serviceNameSearch.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet adı ara...'**
  String get serviceNameSearch;

  /// No description provided for @servicesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler yüklenemedi'**
  String get servicesLoadError;

  /// No description provided for @serviceNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet bulunamadı'**
  String get serviceNotFound;

  /// No description provided for @newServiceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Hizmet Ekle'**
  String get newServiceTitle;

  /// No description provided for @profileSettings.
  ///
  /// In tr, this message translates to:
  /// **'Profil Ayarları'**
  String get profileSettings;

  /// No description provided for @editIbanSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'IBAN bilgilerinizi güncelleyin'**
  String get editIbanSubtitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil bilgilerinizi düzenleyin'**
  String get editProfileSubtitle;

  /// No description provided for @changePhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Değiştir'**
  String get changePhone;

  /// No description provided for @changePhoneSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranızı değiştirin'**
  String get changePhoneSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı Sil'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı tamamen sistem üzerinden silmek istiyor musunuz? Bu işlem geri döndürülemez bütün kayıtlarınız sistem üzerinden silinir...'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @accountDeleteSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız başarıyla silindi'**
  String get accountDeleteSuccess;

  /// No description provided for @userDataLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bilgileri yüklenemedi'**
  String get userDataLoadError;

  /// No description provided for @editProfilePageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil Düzenle'**
  String get editProfilePageTitle;

  /// No description provided for @editProfileHeader.
  ///
  /// In tr, this message translates to:
  /// **'Profil Bilgilerinizi Düzenleyin'**
  String get editProfileHeader;

  /// No description provided for @editProfileSubHeader.
  ///
  /// In tr, this message translates to:
  /// **'Bilgilerinizi güncelleyebilirsiniz'**
  String get editProfileSubHeader;

  /// No description provided for @passwordOptionalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre (Değiştirmek istemiyorsanız boş bırakın)'**
  String get passwordOptionalLabel;

  /// No description provided for @newPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifre'**
  String get newPasswordHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni şifreyi tekrar girin'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordMinLengthError;

  /// No description provided for @reEnterPasswordError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen şifreyi tekrar girin'**
  String get reEnterPasswordError;

  /// No description provided for @passwordsDoNotMatchError.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor'**
  String get passwordsDoNotMatchError;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Profil başarıyla güncellendi'**
  String get profileUpdateSuccess;

  /// No description provided for @changePhonePageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Değiştir'**
  String get changePhonePageTitle;

  /// No description provided for @smsVerificationCode.
  ///
  /// In tr, this message translates to:
  /// **'SMS Doğrulama Kodu'**
  String get smsVerificationCode;

  /// No description provided for @newPhoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Telefon Numarası'**
  String get newPhoneNumber;

  /// No description provided for @enterSmsVerificationCode.
  ///
  /// In tr, this message translates to:
  /// **'Yeni telefon numaranıza gönderilen doğrulama kodunu girin'**
  String get enterSmsVerificationCode;

  /// No description provided for @enterNewPhoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranızı değiştirmek için yeni numaranızı girin'**
  String get enterNewPhoneNumber;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu'**
  String get verificationCodeLabel;

  /// No description provided for @verificationCodeHint.
  ///
  /// In tr, this message translates to:
  /// **'6 haneli kodu girin'**
  String get verificationCodeHint;

  /// No description provided for @verificationCodeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu gereklidir'**
  String get verificationCodeRequired;

  /// No description provided for @verificationCodeLengthError.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu 6 haneli olmalıdır'**
  String get verificationCodeLengthError;

  /// No description provided for @waitForNewCode.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kod göndermek için {seconds} saniye bekleyin'**
  String waitForNewCode(int seconds);

  /// No description provided for @sendSms.
  ///
  /// In tr, this message translates to:
  /// **'SMS Gönder'**
  String get sendSms;

  /// No description provided for @companyServiceInfo.
  ///
  /// In tr, this message translates to:
  /// **'Firma Hizmeti Bilgileri'**
  String get companyServiceInfo;

  /// No description provided for @addServiceButton.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Ekle'**
  String get addServiceButton;

  /// No description provided for @serviceAddError.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet eklenirken hata oluştu'**
  String get serviceAddError;

  /// No description provided for @referenceNumberCopiedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Referans numarası kopyalandı'**
  String get referenceNumberCopiedMessage;

  /// No description provided for @appointmentSystemNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Randevu ve sistem bildirimlerinizi buradan takip edebilirsiniz'**
  String get appointmentSystemNotifications;

  /// No description provided for @companyType.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Tipi'**
  String get companyType;

  /// No description provided for @newEmployee.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Çalışan Ekle'**
  String get newEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In tr, this message translates to:
  /// **'Çalışan Düzenle'**
  String get editEmployee;

  /// No description provided for @companyInfoLoadError.
  ///
  /// In tr, this message translates to:
  /// **'İşletme bilgisi yüklenemedi'**
  String get companyInfoLoadError;

  /// No description provided for @postDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiyi Sil'**
  String get postDeleteTitle;

  /// No description provided for @chatDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get chatDelete;

  /// No description provided for @pleaseSelectBranch.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir şube seçin'**
  String get pleaseSelectBranch;

  /// No description provided for @connectionTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı zaman aşımına uğradı'**
  String get connectionTimeout;

  /// No description provided for @businessType.
  ///
  /// In tr, this message translates to:
  /// **'İşletme Tipi'**
  String get businessType;

  /// No description provided for @admin.
  ///
  /// In tr, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @ibanStartExact.
  ///
  /// In tr, this message translates to:
  /// **'IBAN TR ile başlamalıdır'**
  String get ibanStartExact;

  /// No description provided for @ibanLengthExact.
  ///
  /// In tr, this message translates to:
  /// **'IBAN 24 rakam içermelidir'**
  String get ibanLengthExact;

  /// No description provided for @ibanDigitsOnly.
  ///
  /// In tr, this message translates to:
  /// **'IBAN sadece rakam içermelidir'**
  String get ibanDigitsOnly;

  /// No description provided for @ibanUpdateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'IBAN başarıyla güncellendi'**
  String get ibanUpdateSuccess;

  /// No description provided for @youCanUpdateIban.
  ///
  /// In tr, this message translates to:
  /// **'IBAN bilginizi güncelleyebilirsiniz'**
  String get youCanUpdateIban;

  /// No description provided for @employeeAddedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Çalışan başarıyla eklendi'**
  String get employeeAddedSuccess;

  /// No description provided for @employeeUpdatedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Çalışan başarıyla güncellendi'**
  String get employeeUpdatedSuccess;

  /// No description provided for @phoneHint.
  ///
  /// In tr, this message translates to:
  /// **'Telefon (5XX...)'**
  String get phoneHint;

  /// No description provided for @phoneNotEditable.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası düzenlenemez'**
  String get phoneNotEditable;

  /// No description provided for @status.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get status;

  /// No description provided for @statusPending.
  ///
  /// In tr, this message translates to:
  /// **'Onay Bekliyor'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylandı'**
  String get statusApproved;

  /// No description provided for @statusBanned.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklandı'**
  String get statusBanned;

  /// No description provided for @newPasswordOptional.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre (Boş bırakılabilir)'**
  String get newPasswordOptional;

  /// No description provided for @companyServiceInfoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni firma hizmeti eklemek için gerekli bilgileri doldurun'**
  String get companyServiceInfoSubtitle;

  /// No description provided for @errorLoadingCompanies.
  ///
  /// In tr, this message translates to:
  /// **'Firmalar yüklenemedi'**
  String get errorLoadingCompanies;

  /// No description provided for @errorLoadingServices.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler yüklenemedi'**
  String get errorLoadingServices;

  /// No description provided for @singlePrice.
  ///
  /// In tr, this message translates to:
  /// **'Tek Fiyat'**
  String get singlePrice;

  /// No description provided for @priceCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat (₺)'**
  String get priceCurrency;

  /// No description provided for @minPrice.
  ///
  /// In tr, this message translates to:
  /// **'Min Fiyat (₺)'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In tr, this message translates to:
  /// **'Max Fiyat (₺)'**
  String get maxPrice;

  /// No description provided for @priceRequired.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat gerekli'**
  String get priceRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir fiyat girin'**
  String get invalidPrice;

  /// No description provided for @minPriceRequired.
  ///
  /// In tr, this message translates to:
  /// **'Min fiyat gerekli'**
  String get minPriceRequired;

  /// No description provided for @maxPriceRequired.
  ///
  /// In tr, this message translates to:
  /// **'Max fiyat gerekli'**
  String get maxPriceRequired;

  /// No description provided for @maxPriceError.
  ///
  /// In tr, this message translates to:
  /// **'Max fiyat min fiyattan büyük olmalı'**
  String get maxPriceError;

  /// No description provided for @pleaseSelectService.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen hizmet seçin'**
  String get pleaseSelectService;

  /// No description provided for @invalidDuration.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli bir süre girin'**
  String get invalidDuration;

  /// No description provided for @companyServiceAddedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Firma hizmeti başarıyla eklendi'**
  String get companyServiceAddedSuccess;

  /// No description provided for @updateServiceInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet Bilgilerini Güncelle'**
  String get updateServiceInfo;

  /// No description provided for @updateServiceInfoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Firma hizmeti bilgilerini güncelleyin'**
  String get updateServiceInfoSubtitle;

  /// No description provided for @update.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get update;

  /// No description provided for @deleteServiceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hizmeti Sil'**
  String get deleteServiceTitle;

  /// No description provided for @deleteServiceConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu hizmeti silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'**
  String get deleteServiceConfirm;

  /// No description provided for @companyServiceUpdatedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Firma hizmeti başarıyla güncellendi'**
  String get companyServiceUpdatedSuccess;

  /// No description provided for @serviceUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet güncellenirken hata oluştu'**
  String get serviceUpdateError;

  /// No description provided for @noNotificationsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bildirim yok'**
  String get noNotificationsYet;

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In tr, this message translates to:
  /// **'Tüm bildirimler okundu olarak işaretlendi'**
  String get allNotificationsMarkedRead;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yeni randevular, sistem güncellemeleri ve önemli duyurular burada görünecek'**
  String get notificationsEmptyDesc;

  /// No description provided for @unreadNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Okunmamış Bildirimler'**
  String get unreadNotifications;

  /// No description provided for @readNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Okunmuş Bildirimler'**
  String get readNotifications;

  /// No description provided for @newLabel.
  ///
  /// In tr, this message translates to:
  /// **'YENİ'**
  String get newLabel;

  /// No description provided for @readLabel.
  ///
  /// In tr, this message translates to:
  /// **'Okundu'**
  String get readLabel;

  /// No description provided for @unreadNotificationCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} okunmamış bildirim'**
  String unreadNotificationCount(int count);

  /// No description provided for @customerMessagesEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'İşletmelerle konuşmaya başlamak için randevu aldıktan sonra mesajlaşabilirsiniz'**
  String get customerMessagesEmptyDesc;

  /// No description provided for @unknownCompany.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen İşletme'**
  String get unknownCompany;

  /// No description provided for @deleteCompanyChatConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{companyName} ile olan tüm mesajları silmek istediğinizden emin misiniz?'**
  String deleteCompanyChatConfirm(String companyName);

  /// No description provided for @deleteCustomerChatConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{customerName} ile olan tüm mesajları silmek istediğinizden emin misiniz?'**
  String deleteCustomerChatConfirm(String customerName);

  /// No description provided for @now.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi'**
  String get now;

  /// No description provided for @min.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get min;

  /// No description provided for @day.
  ///
  /// In tr, this message translates to:
  /// **'g'**
  String get day;

  /// No description provided for @customerNotificationsEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Randevularınız, siparişleriniz ve önemli duyurular burada görünecek'**
  String get customerNotificationsEmptyDesc;

  /// No description provided for @customer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get customer;

  /// No description provided for @justNow.
  ///
  /// In tr, this message translates to:
  /// **'Az önce'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika önce'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat önce'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce'**
  String daysAgo(int days);

  /// No description provided for @yesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get yesterday;

  /// No description provided for @chatDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet silindi'**
  String get chatDeleted;

  /// No description provided for @chatDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet silinirken hata oluştu'**
  String get chatDeleteError;

  /// No description provided for @fileSizeError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya boyutu 5MB\'dan küçük olmalıdır'**
  String get fileSizeError;

  /// No description provided for @imagePickError.
  ///
  /// In tr, this message translates to:
  /// **'Resim seçilirken hata oluştu'**
  String get imagePickError;

  /// No description provided for @selectCategoryError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir kategori seçin'**
  String get selectCategoryError;

  /// No description provided for @selectImageError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen en az bir resim seçin'**
  String get selectImageError;

  /// No description provided for @productCreatedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Ürün başarıyla oluşturuldu'**
  String get productCreatedSuccess;

  /// No description provided for @newProductTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Ürün'**
  String get newProductTitle;

  /// No description provided for @productImages.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Görselleri'**
  String get productImages;

  /// No description provided for @pickImage.
  ///
  /// In tr, this message translates to:
  /// **'Resim Seç'**
  String get pickImage;

  /// No description provided for @productName.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Adı'**
  String get productName;

  /// No description provided for @productNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Adı'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Espresso Çekirdeği'**
  String get productNameHint;

  /// No description provided for @productNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen ürün adı giriniz'**
  String get productNameRequired;

  /// No description provided for @productNameMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Ürün adı en az 2 karakter olmalıdır'**
  String get productNameMinLength;

  /// No description provided for @description.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get description;

  /// No description provided for @productDescriptionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Açıklaması'**
  String get productDescriptionLabel;

  /// No description provided for @productDescriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Ürün hakkında detaylı bilgi...'**
  String get productDescriptionHint;

  /// No description provided for @productDescriptionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen ürün açıklaması giriniz'**
  String get productDescriptionRequired;

  /// No description provided for @productDescriptionMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama en az 10 karakter olmalıdır'**
  String get productDescriptionMinLength;

  /// No description provided for @priceHint.
  ///
  /// In tr, this message translates to:
  /// **'0.00'**
  String get priceHint;

  /// No description provided for @commissionRate.
  ///
  /// In tr, this message translates to:
  /// **'Komisyon Oranı (%{rate})'**
  String commissionRate(String rate);

  /// No description provided for @estimatedEarnings.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini Kazanç'**
  String get estimatedEarnings;

  /// No description provided for @category.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Seçin'**
  String get selectCategory;

  /// No description provided for @createProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü Oluştur'**
  String get createProduct;

  /// No description provided for @productsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler yüklenemedi'**
  String get productsLoadError;

  /// No description provided for @noProductsAddedYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ürün eklenmemiş'**
  String get noProductsAddedYet;

  /// No description provided for @noProductsMatchSearch.
  ///
  /// In tr, this message translates to:
  /// **'Arama kriterlerinize uygun ürün bulunamadı'**
  String get noProductsMatchSearch;

  /// No description provided for @addProductExample.
  ///
  /// In tr, this message translates to:
  /// **'İlk ürününüzü eklemek için + butonuna tıklayın'**
  String get addProductExample;

  /// No description provided for @deleteProductTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü Sil'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{productName}\" ürününü silmek istediğinizden emin misiniz?'**
  String deleteProductConfirm(String productName);

  /// No description provided for @productDeletedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Ürün silindi'**
  String get productDeletedSuccess;

  /// No description provided for @productUpdatedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Ürün başarıyla güncellendi'**
  String get productUpdatedSuccess;

  /// No description provided for @currentImages.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Görseller'**
  String get currentImages;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
