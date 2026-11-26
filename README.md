# BACKSTAGE // Bağımsız Müzik, Demo Paylaşım ve İş Birliği Platformu (MVP)

"Spotify'dan önceki durak" vizyonuyla geliştirilmiş; bağımsız müzisyenlerin ham demolarını, yeni çıkacak şarkılarının kesitlerini ve orijinal parçalarını paylaştığı, **Myspace'in kişiselleştirilebilir profil ruhunu** modern, karanlık mod (dark-mode) ve ses odaklı (audio-first) bir **Mobil + Web (Flutter + Firebase)** deneyimiyle birleştiren sosyal keşif ve iş birliği (collab) uygulaması.

---

## 🚀 Teknoloji Yığını ve Mimari

- **Ön Yüz (Mobil & Web Tek Kod Tabanı):** Flutter 3.x (Android, iOS, Web PWA ve Masaüstü uyumlu responsive tasarım)
- **Arka Uç & Veritabanı:** Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`) + **Offline-First Hibrit Katman** (`SharedPreferences` + dahili gerçek zamanlı PCM WAV stüdyo synth ses motoru sayesinde Firebase anahtarları girilmeden önce bile kutudan çıktığı anda gerçek ses ve verilerle çalışır).
- **Ses Motoru (`lib/services/audio_engine.dart`):**
  - Kullanıcıların yüklediği `MP3 / WAV / M4A` ses dosyalarını oynatır.
  - Dahili demolar için türe göre (`Rock`, `Rap`, `Indie`, `Elektronik`) gerçek zamanlı çok katmanlı PCM WAV ses dalgası sentezler.
  - Etkileşimli **Waveform (Ses Dalgası)** üzerinde tıklayarak veya sürükleyerek saniye bazlı sarma (seeking) sağlar.

---

## ✨ Tamamlanan Modüller ve Özellikler

### 1. Keşif Akışı (Audio-First Feed) — `lib/screens/feed_screen.dart`
- Üst kısımda hızlı tür (`Tümü`, `Indie`, `Rock`, `Rap`, `Elektronik`, `Pop`, `Alternatif`) filtreleri.
- Dikey kaydırılabilir ses kartları: Kapak görseli, sanatçı bilgisi, tür rozeti, etiketler (`#demo`, `#taslak`, `#orijinal`), beğeni, kaydetme ve yorum aksiyonları.
- **Etkileşimli Ses Dalgası (`lib/widgets/interactive_waveform.dart`)** ve **Saniye Bazlı Yorumlar (Timestamped Comments):**
  - Kullanıcılar parçanın belirli bir saniyesine (örn. `0:24`) nokta atışı yorum bırakabilir.
  - Yorumlar ses dalgası (waveform) üzerinde saniye rozetleriyle işaretlenir; rozete tıklandığında parça doğrudan o saniyeye sarar.

### 2. Modern "Myspace Odası" (Özelleştirilebilir Profil) — `lib/screens/myspace_profile_screen.dart`
- **Özel Oda Teması / Gradyan Seçimi:** `Midnight Neon`, `Cyber Studio`, `Analog Tape`, `Synthwave Blue`, `Sunset Lo-Fi`.
- **İmza Parça (Pinned Track):** Profilin en üstünde sabitlenen ve tek tıkla etkileşimli ses dalgasıyla çalınabilen parça alanı.
- **İş Birliği (Collab) Durumu:** `"İş Birliğine Açık"` rozeti/anahtarı ve seçilebilir müzikal roller (`Vokal`, `Beatmaker`, `Gitarist`, `Mix/Mastering`, `Söz Yazarı`, `Prodüktör` vb.).
- **Erken Destekçi (Early Supporter) Rozeti:** Bir sanatçıyı takipçi sayısı `100`'ün altındayken takip eden kullanıcılara otomatik olarak `"Early Supporter"` rozeti tanımlanır ve hem profillerde hem de saniye bazlı yorumlarda gösterilir.

### 3. Parça Yükleme Akışı (Zorunlu Telif Onaylı Upload) — `lib/screens/upload_screen.dart`
- Ses dosyası (`MP3 / WAV / M4A`) ve kapak görseli yükleme.
- Parça adı, tür seçimi, etiketler ve açıklama.
- **Zorunlu Yasal Onay Kutusu:**
  > *"Yüklediğim ses ve görsel içeriğin tüm telif ve yayın haklarına sahip olduğumu, üçüncü şahıs haklarını ihlal etmediğini beyan ve kabul ederim."*
- Onay kutusu işaretlenmeden yükleme butonu aktif olmaz; onaylandığında zaman damgası (`copyright_accepted_at`) ve kullanıcı ID'si (`user_id`) veritabanına loglanır.

### 4. Müzik Odaklı Sosyal Katman (DM & Collab) — `lib/screens/messages_screen.dart`
- Parça kartlarından ve Myspace odalarından doğrudan **"İş Birliği Teklif Et / Mesaj At"** butonu ile sohbet başlatma.
- Normal mesaj veya hedef rol (`Vokal`, `Gitarist`, `Beatmaker` vb.) ve referans demo içeren **İş Birliği Teklifi (`is_collab_request: true`)** gönderme.

### 5. Yasal Uyumluluk, Telif (DMCA / 5651) ve Mağaza Güvenliği (UGC)
- **Uyar-Kaldır (Report) Mekanizması (`lib/widgets/report_dialog.dart`):** Her parçanın, yorumun ve profilin menüsünde `Telif Hakkı İhlali (DMCA/5651)`, `Uygunsuz İçerik` ve `Spam` sebepleriyle bildirim yapabilme.
- **Kullanıcı Engelleme (Block):** Profil, akış veya sohbet ekranından tek tıkla `"Kullanıcıyı Engelle"`. Engellenen kullanıcının parçaları, yorumları ve mesajları anında gizlenir.
- **Kayıt Aşamasında Zorunlu Sözleşme (`lib/screens/auth_screen.dart`):** `"Kullanım Koşulları ve Gizlilik Politikası"` onay kutusu işaretlenmeden kayıt tamamlanamaz.
- **Basit Admin / Moderasyon Paneli (`lib/screens/admin_panel_screen.dart`):**
  - Yalnızca `role: "admin"` olan kullanıcılar erişebilir.
  - Şikayet edilen içeriklerin listesi, sebebi ve tarih/saat bilgisi.
  - Tek tıkla **İçeriği Yayından Kaldır (`Soft-Delete / is_hidden: true`)** ve **Kullanıcıyı Askıya Al** aksiyonları.
  - Tüm parçaların yasal telif onay zaman damgalarını (`copyright_accepted_at`) denetleme listesi.

---

## ▶️ Çalıştırma Komutları

```bash
# Bağımlılıkları yükle
flutter pub get

# Web (Chrome) üzerinde çalıştır
flutter run -d chrome

# Windows masaüstü uygulaması olarak çalıştır
flutter run -d windows

# Uçtan uca birim ve akış testlerini çalıştır
flutter test
```
