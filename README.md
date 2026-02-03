# M&W - İşletme Randevu Uygulaması

M&W, Kadın kuaförü, erkek berberi, uniseks (karma) kuaför ve evcil hayvan kuaförü işletmelerinin kayıt olabileceği, kullanıcıların bu işletmelere randevu alabileceği kapsamlı bir mobil uygulamadır.

Bu proje, modern mobil uygulama geliştirme standartlarına uygun olarak **Flutter** kullanılarak geliştirilmiştir.

##  Mağaza Bağlantıları

Uygulama yayındadır ve aşağıdaki bağlantılardan indirilebilir:

*   [**Apple App Store**](https://apps.apple.com/tr/app/m-w/id6754393973?l=tr)
*   [**Google Play Store**](https://play.google.com/store/apps/details?id=com.mw.barbershop.dev)

##  Proje Hakkında

Bu uygulama, kullanıcılar ve işletmeler arasında köprü kurarak randevu süreçlerini dijitalleştirir. İşletmeler profillerini oluşturup tanıtabilirken, kullanıcılar puan ve yorum bırakabilir, konumlarına en yakın ve en yüksek puanlı işletmeleri bulabilirler.

###  Temel Özellikler

*   **Kapsamlı İşletme Kategorileri:** Kadın Kuaförü, Erkek Berberi, Uniseks Kuaför ve Evcil Hayvan Kuaförü.
*   **Kullanıcı İşlemleri:** Google veya E-posta/Telefon ile güvenli giriş ve kayıt.
*   **Randevu Yönetimi:** Kullanıcılar için kolay randevu alma, işletmeler için çalışma saati ve tatil yönetimi.
*   **Puanlama ve Yorum:** Gerçek kullanıcı deneyimlerine dayalı 5 üzerinden puanlama ve yorum sistemi.
*   **Gelişmiş Arama ve Filtreleme:** İşletme türü, konum ve puana göre detaylı arama.
*   **Navigasyon Entegrasyonu:** Seçilen işletmeye harita üzerinden (Google/Apple Maps) yol tarifi.
*   **Favoriler:** Beğenilen işletmeleri favorilere ekleme.
*   **Çoklu Dil Desteği:** 25+ dil desteği ile global kullanım.
*   **Ödeme Sistemleri:** Nakit ve kredi kartı ile ödeme seçenekleri.
*   **Bildirimler:** Randevu hatırlatmaları ve durum güncellemeleri için anlık bildirimler.

##  Kullanılan Teknolojiler

Proje geliştirilirken güncel ve popüler kütüphaneler tercih edilmiştir:

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Dil:** [Dart](https://dart.dev/)
*   **State Management (Durum Yönetimi):** [Provider](https://pub.dev/packages/provider)
*   **Backend & Servisler:**
    *   **Node.js:** Özel backend mimarisi ve REST API servisleri.
    *   **Firebase:** Authentication (Kimlik Doğrulama) ve Messaging (FCM).
    *   **REST API:** Dio paketi ile güçlü entegrasyon.
*   **Harita & Konum:**
    *   google_maps_flutter
    *   geolocator
    *   geocoding
*   **Depolama:**
    *   shared_preferences
    *   flutter_secure_storage
*   **Diğer Önemli Paketler:**
    *   `flutter_localizations`: Çoklu dil desteği için.
    *   `cached_network_image`: Resim önbellekleme.
    *   `image_picker` & `flutter_image_compress`: Görsel işlemleri.
    *   `url_launcher`: Dış bağlantı yönetimi.

##  Kurulum

Projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyin:

1.  **Depoyu klonlayın:**
    ```bash
    git clone [repository_url]
    ```

2.  **Bağımlılıkları yükleyin:**
    ```bash
    flutter pub get
    ```

3.  **Uygulamayı çalıştırın:**
    ```bash
    flutter run
    ```

##  Ekran Görüntüleri

<img width="1920" height="1440" alt="287shots_so" src="https://github.com/user-attachments/assets/4e25aed8-eb53-44a0-b3f1-dc2c99f82cda" />
<img width="1920" height="1440" alt="638shots_so" src="https://github.com/user-attachments/assets/794e2159-fbc7-4bed-9b2f-2819cb346950" />
<img width="1920" height="1440" alt="390shots_so" src="https://github.com/user-attachments/assets/d533a078-c819-4c12-9d19-da1f29b52e3e" />
<img width="1920" height="1440" alt="283shots_so" src="https://github.com/user-attachments/assets/95eeda29-4e19-4813-89a7-38399fe68c36" />



---
Geliştirici: Berke Şeker
