# Arvenato Ön Muhasebe

Gelir, gider, cari, banka, stok, teklif, personel, fatura ve ajanda takibi yapan; bilgisayarda ve telefonda uygulama olarak kurulabilen ön muhasebe programı.

## Nasıl çalışır?

- **Uygulama dosyaları** (`index.html`, `config.js`, `sw.js`, `manifest.webmanifest` ve simge dosyaları) GitHub Pages üzerinde ücretsiz yayınlanır.
- **Kayıtlar** Supabase veritabanında tutulur. Herkes kendi e-posta ve şifresiyle giriş yapar ve yalnızca üyesi olduğu firmanın kayıtlarını görür.
- Bilgisayarda girilen kayıt telefonda anında görünür.

## Kurulum adımları

1. **Veritabanı** — `schema.sql` dosyasının tamamını Supabase panelinde *SQL Editor > New query* bölümüne yapıştırıp *Run* deyin. (Bu adım yapıldı.)
2. **Yayınlama** — Bu klasördeki dosyaları GitHub'da bir depoya yükleyin, *Settings > Pages* bölümünden *Branch: main / root* seçip kaydedin. Birkaç dakika sonra uygulama `https://KULLANICIADI.github.io/DEPOADI/` adresinde açılır.
3. **Giriş adresleri** — Supabase panelinde *Authentication > URL Configuration* bölümünde *Site URL* alanına uygulama adresini yazın ve aynı adresi *Redirect URLs* listesine ekleyin. Böylece kayıt onayı ve şifre sıfırlama e-postalarındaki bağlantılar uygulamaya döner.
4. **İlk giriş** — Uygulamayı açın, *Hesap oluştur* ile kaydolun, e-postanızdaki onay bağlantısına tıklayın, giriş yapın ve firmanızı oluşturun.
5. **Eski kayıtları taşıma** — Eski programda (claude.ai) üstteki *Yedek al* düğmesiyle `.json` yedeği indirin. Yeni uygulamada *Hesabım > Yedekten geri yükle* ile bu dosyayı seçin.
6. **Uygulama olarak kurma** — Bilgisayarda Chrome adres çubuğundaki *Yükle* simgesine tıklayın. Android'de Chrome menüsünden *Ana ekrana ekle*, iPhone'da Safari'de *Paylaş > Ana Ekrana Ekle*.

## Çalışan ekleme

Çalışan önce uygulamada *Hesap oluştur* ile kaydolur. Firma sahibi *Hesabım > Kullanıcılar* bölümünden çalışanın e-postasını yazıp ekler.

## Güncellemeler

Kod değişiklikleri GitHub deposuna gönderildiğinde uygulama birkaç dakika içinde güncellenir; cihazlar bir sonraki açılışta yeni sürüme geçer. Veriler Supabase'de kaldığı için güncellemelerden etkilenmez.

## Güvenlik notları

- `config.js` içindeki anahtar *publishable* (yayınlanabilir) anahtardır; tarayıcıda görünmesi normaldir. Veriler satır düzeyinde güvenlik (RLS) kurallarıyla korunur.
- Supabase'in **service_role / secret** anahtarını hiçbir dosyaya yazmayın, kimseyle paylaşmayın.
- Bu program resmi e-Fatura / e-Arşiv düzenlemez; ön muhasebe kaydı tutar.
