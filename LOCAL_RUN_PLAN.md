# Local Run Plan

Bu dosya, projeyi bu Mac'te yerelde calistirmak icin hazirlandi.
Amac: her oturumda nerede kaldigimizi tek yerden gorebilmek.

## Proje Ozeti

- Backend: Node.js + Express API
- Veritabani: PostgreSQL
- AI: Google Gemini
- Mobil istemci: Flutter

Klasor yapisi:

- `receipt_scanner/`: backend API
- `receipt_scanner/mobile_app/`: Flutter istemcisi

## Bu Mac'teki Durum

12 Nisan 2026 itibariyla kontrol edilen ortam:

- macOS: `26.1`
- CPU: `arm64`
- Node.js: `v24.14.0`
- npm: `11.9.0`
- Flutter: kurulu degil
- psql: kurulu degil

## Simdiye Kadar Yapilanlar

### 1. Proje tarandi

Durum: tamamlandi

Notlar:

- Ana uygulamanin `receipt_scanner` klasorunde oldugu tespit edildi.
- `package.json` backend'in `server.js` ile calistigini gosteriyor.
- `mobile_app/pubspec.yaml` Flutter tarafinin ayri bir istemci oldugunu dogruluyor.

### 2. Backend gereksinimleri incelendi

Durum: tamamlandi

Notlar:

- Backend, `.env` uzerinden su degiskenleri bekliyor:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `GEMINI_API_KEY`
  - opsiyonel `PORT`
- API saglik endpoint'i: `GET /api/health`
- Bu proje klasorunde `.env` zaten var; yani sifirdan olusturmak yerine mevcut degerler dogrulanarak ilerleniyor.

### 3. Kod-veritabani uyumsuzluklari bulundu

Durum: tamamlandi

Bulunan problemler:

- Auth kodu `users` tablosunu bekliyordu ama `schema.sql` icinde yoktu.
- Backend `receipts.vendor_name` kolonunu kullaniyordu ama `schema.sql` icinde yoktu.

### 4. Bu Mac'e uygun auth fallback'i eklendi

Durum: tamamlandi

Yapilanlar:

- `bcrypt` paketinin bu makinede native olarak takildigi tespit edildi.
- Sebep: mevcut `node_modules/bcrypt` icinde `darwin-arm64` binary yok.
- Cozum olarak `src/services/passwordService.js` eklendi.
- Servis mantigi:
  - native `bcrypt` varsa onu kullan
  - yoksa yerel calisma icin `scrypt` fallback kullan
- `src/routes/auth.js` bu yeni servis uzerinden calisacak sekilde guncellendi.

### 5. Veritabani semasi guncellendi

Durum: tamamlandi

Yapilanlar:

- `pgcrypto` extension eklendi
- `users` tablosu eklendi
- `receipts.vendor_name` kolonu eklendi
- `users` icin index, trigger ve RLS policy eklendi

### 6. Kod dogrulandi

Durum: tamamlandi

Calisan kontroller:

- `node -c server.js`
- `node -c src/routes/auth.js`
- `node -c src/services/passwordService.js`
- `require('./src/routes/auth')` artik takilmadan yukleniyor

### 7. Runtime dogrulamasi denendi

Durum: kismi

Notlar:

- Bu oturumdaki sandbox, `listen()` cagrisini engelledi.
- Bu nedenle API'nin burada gercek port acarak calistigi dogrulanamadi.
- Alinan hata: `EPERM listen ... 3000`
- Bu, proje kodundan cok ortam kisiti oldugunu gosteriyor.

### 8. Mevcut `.env` ve DB baglantisi kontrol edildi

Durum: tamamlandi

Notlar:

- `.env` dosyasinda gerekli ana ayarlar zaten bulundu.
- Zayif varsayilan `JWT_SECRET` guclu rastgele bir degerle degistirildi.
- `DATABASE_URL`, `127.0.0.1:5433/receipt_scanner` uzerine isaret ediyor.
- Sandbox disindan yapilan baglanti testinde sonuc:
  - `ECONNREFUSED 127.0.0.1:5433`
- Sonuc: ayarlar mevcut ama PostgreSQL servisi su anda calismiyor.

### 9. Mevcut Postgres kurulumu arastirildi

Durum: tamamlandi

Notlar:

- `brew`, `docker`, `psql`, `postgres`, `pg_ctl`, `initdb` komutlari PATH uzerinde bulunmadi.
- `/Applications`, `/Library`, `/opt` ve kullanici dizininde hizli taramalarda belirgin bir Postgres kurulumu bulunmadi.
- Sonuc: su an en olasi senaryo, bu Mac'te aktif ve hazir bir Postgres kurulumunun olmamasi.

### 10. Harici / baska calisan DATABASE_URL arastirildi

Durum: tamamlandi

Notlar:

- Proje ve yakin ayar dosyalarinda ek bir `postgresql://...` veya `DATABASE_URL` kaydi aranip kontrol edildi.
- Sonuc:
  - kullanilabilir ikinci bir baglanti bilgisi bulunmadi
  - proje sadece mevcut `.env` icindeki lokal ama calismayan `127.0.0.1:5433` baglantisini biliyor
- Kullanici tercihi olarak "2. yol", yani baska calisan bir PostgreSQL instance'ina gecis secildi.
- Sonraki gerekli girdi: calisan `DATABASE_URL`

### 11. Harici DATABASE_URL girdisi beklendi

Durum: kismi

Notlar:

- Kullanicidan harici PostgreSQL baglanti bilgisi istendi.
- Gelen deger:
  - `postgresql://user:password@host:5432/dbname`
- Bu deger format olarak dogru olsa da gercek baglanti bilgisi degil; yer tutucu degerlerden olusuyor.
- Sonraki gerekli girdi:
  - gercek kullanici adi
  - gercek parola
  - gercek host
  - gercek veritabani adi

### 12. Yerel PostgreSQL kuruldu ve calistirildi

Durum: tamamlandi

Notlar:

- Harici kullanilabilir `DATABASE_URL` bulunamadigi icin yerel kurulum yoluna gecildi.
- Resmi `Postgres.app` indirildi ve kullanici alanina kuruldu:
  - `~/Applications/Postgres.app`
- PostgreSQL 16 araclari bu paket icinden kullanildi.
- Veri dizini olusturuldu:
  - `~/.local/share/postgres/receipt_scanner-16`
- Yerel servis `5433` portunda ayaga kaldirildi.
- Yardimci script'ler eklendi:
  - `scripts/start_local_postgres.sh`
  - `scripts/stop_local_postgres.sh`

### 13. Veritabani hazirlandi

Durum: tamamlandi

Notlar:

- `receipt_scanner` veritabani olusturuldu.
- `schema.sql` basariyla uygulandi.
- Mevcut `.env`, calisan lokal baglantiya guncellendi.

### 14. RLS uyumsuzlugu giderildi

Durum: tamamlandi

Notlar:

- Schema icindeki RLS bolumu, uygulama kodu `app.current_shop_id` set etmedigi icin auth ve CRUD akisiyla uyumsuzdu.
- RLS varsayilan olarak kapali hale getirildi.
- Mevcut lokal veritabaninda da RLS devre disi birakildi.

### 15. Backend ve temel auth akisi dogrulandi

Durum: tamamlandi

Notlar:

- `GET /api/health` basarili cevap verdi.
- `POST /api/auth/register` basarili calisti.
- `POST /api/auth/login` basarili calisti.
- JWT ile `GET /api/dashboard/summary` basarili calisti.

### 16. Mevcut web istemcisi servis edildi

Durum: tamamlandi

Notlar:

- `mobile_app/build/web` altindaki mevcut Flutter web build'i statik olarak servis edildi.
- Yerel web adresi:
  - `http://127.0.0.1:8080`
- Yardimci script eklendi:
  - `scripts/start_web_client.sh`

### 17. Screenshot / web decode sorunu icin kaynak kod duzeltildi

Durum: tamamlandi

Notlar:

- Web tarafinda `flutter_image_compress` decode/compression hatasi verirse:
  - uygulama artik orijinal dosya byte'larina fallback yapiyor
  - orijinal dosyanin desteklenen uzantisi korunuyor
- Bu sayede PNG screenshot gibi dosyalar compression adiminda patlasa bile upload akisi devam edebiliyor.
- Guncellenen kaynaklar:
  - `mobile_app/lib/services/receipt_api_service.dart`
  - `mobile_app/lib/screens/dashboard_screen.dart`
  - `mobile_app/lib/screens/history_screen.dart`

### 18. Flutter SDK kuruldu ve web build yeniden alindi

Durum: tamamlandi

Notlar:

- Flutter SDK lokal olarak kuruldu:
  - `~/development/flutter`
- Projeye uygun guncel SDK ile web build tekrar uretildi.
- Guncel bundle icinde yeni stringler dogrulandi:
  - screenshot fallback log mesaji
  - guest dashboard/history sign-in mesajlari

### 19. Düsük maliyetli test stratejisi uygulandi

Durum: tamamlandi

Notlar:

- Gemini API maliyetini minimumda tutmak icin gercek receipt scan testi bu asamada kasitli olarak yapilmadi.
- Bunun yerine su dusuk maliyetli dogrulamalar yapildi:
  - Flutter unit/widget testleri
  - web build basarisi
  - build ciktisi icinde yeni kod izlerinin aranmasi
  - backend health/auth/dashboard endpoint testleri
- Kural:
  - Bundan sonraki Gemini tabanli testlerde once maliyetsiz veya dusuk maliyetli dogrulama yap
  - gerekirse en sonda tek bir kontrollu gercek scan denemesi yap

### 20. Son dogrulama sonuclari

Durum: tamamlandi

Test edilenler:

- `scripts/start_local_postgres.sh`
- `GET /api/health`
- `POST /api/auth/login`
- `flutter test`
- `flutter build web --release`
- `scripts/start_web_client.sh`
- guncel `build/web/main.dart.js` icinde yeni fix stringlerinin varligi

Sonuclar:

- Lokal PostgreSQL ayaga kalkti
- API saglik endpoint'i calisti
- Login endpoint'i calisti
- Flutter testleri gecti
- Web build basariyla alindi
- Web istemci script'i 8090 portunda test edildi
- Yeni fixlerin derlenmis bundle'a girdigi dogrulandi

### 21. 2026-04-12 tekrar dogrulama (dusuk maliyetli)

Durum: tamamlandi

Calistirilan komutlar:

- `flutter test`
- `flutter build web --release`
- `curl http://127.0.0.1:3000/api/health`
- `curl -X POST http://127.0.0.1:3000/api/auth/login ...`
- `curl -I http://127.0.0.1:8080/`
- `rg` ile `build/web/main.dart.js` icinde screenshot fallback ve guest ekran stringlerinin aranmasi

Sonuclar:

- Flutter testleri tekrar gecti
- Web build tekrar basariyla alindi
- API health endpoint'i tekrar `status: ok` dondu
- Login endpoint'i tekrar token uretip cevap verdi
- Web istemcisi 8080 portunda erisilebilir durumda kaldi
- Derlenmis bundle icinde su izler tekrar goruldu:
  - `Web compression failed, uploading original file instead`
  - `receipt.png`
  - `Sign in to view your receipts`
  - `Sign in to view your dashboard`

Not:

- Gemini API maliyeti olusturmamak icin bu tekrar dogrulama turunde gercek `/api/receipts/scan` cagrisi yine bilincli olarak yapilmadi.
- Screenshot kabul duzeltmesi kaynak kod, test ve derlenmis bundle seviyesinde dogrulandi.
- `scripts/start_local_postgres.sh` icindeki varsayilan local-dev parola ifadesi notr bir degere cekildi ve script tekrar basariyla calistirildi.

### 22. Para birimi akisi TRY / TL olacak sekilde duzeltildi

Durum: tamamlandi

Yapilanlar:

- Backend tarafinda shop currency kavrami aktif olarak response'lara eklendi:
  - `auth/login`
  - `auth/register`
  - `dashboard/summary`
  - `dashboard/history`
  - `receipts/scan`
  - `receipts/import`
- Yeni shop default currency degeri `TRY` olarak sabitlendi.
- Flutter tarafinda ortak currency formatter eklendi.
- Dashboard, history, result dialog ve edit ekranindaki tum hardcoded `USD` / `GBP` / `£` / `$` gosterimleri kaldirildi.
- Scan sonucu modeli currency bilgisini okuyacak sekilde genislletildi.
- Auth session icine `shop currency` kalici olarak kaydedildi.

Lokal veri duzeltmesi:

- Lokal PostgreSQL icinde mevcut `shops.currency` kayitlari `USD` -> `TRY` olarak guncellendi.
- `shops.currency` kolonunun varsayilan degeri de `TRY` olacak sekilde degistirildi.

Dusuk maliyetli dogrulamalar:

- `node -c` ile backend route/config syntax kontrolu
- SQL ile `shops.currency` verisinin `TRY` oldugunun kontrolu
- `POST /api/auth/login` cevabinda `currency: "TRY"` dogrulamasi
- `GET /api/dashboard/summary` cevabinda `currency: "TRY"` dogrulamasi
- Receipt bulunan tenant icin `GET /api/dashboard/history` cevabinda receipt ve top-level `currency: "TRY"` dogrulamasi
- `flutter test`
- `flutter build web --release`
- Derlenmis `build/web/main.dart.js` icinde `TRY`, `₺` ve `auth_shop_currency` izlerinin aranmasi

Not:

- Bu duzeltme ve dogrulama turunde de Gemini maliyeti olusturan gercek scan testi yapilmadi.

### 23. Receipt-level coklu para birimi otomasyonu kuruldu

Durum: tamamlandi

Amac:

- Para birimi bilgisini artik shop seviyesinde varsaymak yerine her receipt icin ayri tespit etmek
- Farkli currency ile odeme yapilan receipt'lerin history, result ve dashboard ekranlarinda ayni ve dogru degerle gorunmesini saglamak
- Gelecekte benzer hata tekrarlarsa manual override ile duzeltmeyi kalici hale getirmek

Yapilanlar:

- Backend tarafinda genel currency normalize yardimcilari genisletildi:
  - ISO currency code normalize etme
  - sembolden code cikarimi
  - code -> symbol donusumu
  - `TL -> TRY` gibi alias cozumleri
- Yeni `currencyDetectionService` eklendi:
  - `currency_code`
  - `currency_symbol`
  - `currency_source`
  - `currency_confidence`
  alanlarini tek receipt icin cozer hale getirildi
- Celişkili durumda benzersiz symbol, Gemini'nin yanlis code cevabini override edecek sekilde guclendirildi
  - ornek: symbol `₺` ise `USD` yerine `TRY`
- Gemini prompt/schema receipt currency'yi tek API cagrisinda donecek sekilde genisletildi
  - ek bir Gemini cagrisi eklenmedi
  - maliyet artisi yaratilmadi
- `receipts` tablosuna yeni kolonlar tanimlandi:
  - `currency_code`
  - `currency_symbol`
  - `currency_source`
  - `currency_confidence`
- Dashboard artik receipt-level currency ile calisiyor:
  - `availableCurrencies`
  - `activeCurrency`
  - `hasMixedCurrencies`
  response alanlari eklendi
  - chart ve total'lar secilen currency'ye gore filtreleniyor
- History, result dialog, edit ve dashboard ekranlari receipt-level currency alanlarini kullanacak sekilde guncellendi
- Edit ekranina `Currency Code` alani eklendi
  - manual duzeltme `manual_override` olarak DB'ye yaziliyor
  - `currency_confidence = 1.000` oluyor

Kalici/local migration:

- Tekrar kullanilabilir idempotent migration script eklendi:
  - `scripts/apply_receipt_currency_migration.js`
- Script su islemleri yapiyor:
  - eksik kolonlari `receipts` tablosuna ekliyor
  - index olusturuyor
  - mevcut receipt kayitlarini shop currency uzerinden backfill ediyor
  - eksik symbol/source/confidence alanlarini dolduruyor

Dusuk maliyetli dogrulamalar:

- `node -c` ile backend degisen dosyalarinin syntax kontrolu
- `node --test test/currency_detection.test.js`
  - ambiguous symbol + explicit code
  - unique symbol override
  - symbol inference
  - fallback to shop currency
- `node scripts/apply_receipt_currency_migration.js`
  - lokal DB'de 1 receipt backfill edildi
- `flutter test`
- `flutter build web --release`
- Derlenmis `build/web/main.dart.js` icinde yeni currency alanlarinin izleri arandi:
  - `activeCurrency`
  - `availableCurrencies`
  - `currency_symbol`
  - `currency_source`
  - `manual_override`
- API smoke testleri:
  - `GET /api/health`
  - `POST /api/auth/login`
  - `GET /api/dashboard/summary`
  - `GET /api/dashboard/history`
- Ek manuel-override smoke testi:
  - `POST /api/receipts/import`
  - `PUT /api/receipts/:id`
  - `DELETE /api/receipts/:id`
  - sonuc: `manual_override` ve `currency_confidence = 1.000` dogrulandi

Canli lokal durum:

- History API'den donen mevcut receipt icin:
  - `currency_code = TRY`
  - `currency_symbol = ₺`
  - `currency_source = shop_default`
  - `currency_confidence = 0.350`
- Dashboard summary su anda:
  - `activeCurrency = TRY`
  - `availableCurrencies = [TRY]`
  - `total_spend = 1300.98`

Maliyet notu:

- Bu turda da gercek `/api/receipts/scan` testi yapilmadi
- Gemini maliyeti olusturmayan yollar tercih edildi:
  - import endpoint
  - node unit test
  - flutter test/build
  - API smoke test
- Gercek Gemini scan ancak gerekirse tek kontrollu cagrida yapilmali

### 24. Turkce line item kategorileri ve JSON extraction semasi gelistirildi

Durum: tamamlandi

Amac:

- Gemini'den donen receipt JSON'unun line item bazinda daha duzenli olmasi
- `category` alaninin kontrollu ve Turkce bir listeden secilmesi
- Kullaniciya Flutter edit ekraninda kategori duzeltme imkani verilmesi

Yapilanlar:

- Backend icin izinli kategori listesi tanimlandi:
  - `Gıda`
  - `Kırtasiye`
  - `Ulaşım/Yol`
  - `Elektronik`
  - `Sağlık`
  - `Eğlence`
  - `Diğer`
- Yeni backend kategori normalize katmani eklendi:
  - legacy / English category degerlerini Turkce listeye map ediyor
  - bos veya belirsiz degerlerde `item_name` ve vendor baglamindan tahmin ediyor
  - sonuc yine izinli listeye dusuyor
- Gemini prompt/schema guncellendi:
  - saf JSON donus zorunlulugu netlestirildi
  - `vendor_name`
  - `receipt_date`
  - `currency_code`
  - `currency_symbol`
  - `total_amount`
  - `tax_amount`
  - `line_items`
  alanlari daha net tarif edildi
  - `line_items.category` icin enum listesi eklendi
- Receipt save/import/scan/update akislarinda line item kategorileri normalize edilmeye baslandi
- Dashboard category breakdown ve history response'lari da normalize kategori ile donmeye basladi
- Flutter tarafinda kategori listesi icin ayri config eklendi
- Edit ekranina line item bazinda `Kategori` dropdown'i eklendi
  - serbest metin yerine secilebilir kontrollu kategori geldi
  - eski `Electronics`, `Apparel`, `Shopping` gibi degerler acilista normalize edilip dropdown'a dusuyor

Dusuk maliyetli dogrulamalar:

- `node -c` ile degisen backend dosyalari kontrol edildi
- `node --test test/currency_detection.test.js test/receipt_categories.test.js`
- `flutter test`
- `flutter build web --release`
- Build cikti bundle'inda kategori listesi ve dropdown label'lari arandi
- Maliyetsiz API smoke testi:
  - `POST /api/receipts/import` ile ornek receipt eklendi
  - `Electronics` -> `Elektronik`
  - bos kategori + `Defter` -> `Kırtasiye`
  - `GET /api/dashboard/summary?currency=EUR` icinde normalize kategoriler dogrulandi
  - `GET /api/dashboard/history` icinde normalize line item kategorileri dogrulandi
  - test receipt'i silindi

Not:

- Bu turda da gercek Gemini `/api/receipts/scan` testi yapilmadi
- Maliyet olusturmamak icin import endpoint ve unit testler kullanildi

## Lokal Calistirma Plani

### Asama 1. Backend'i ayaga kaldirma

Durum: tamamlandi

Yapilacaklar:

1. `.env` ayarlarini dogrula
2. PostgreSQL'i bu Mac'te calisir hale getir veya erisilebilir bir Postgres baglantisi sagla
3. `schema.sql` dosyasini veritabanina uygula
4. Backend'i normal terminalden calistir
5. `GET /api/health` ile saglik kontrolu yap

Ornek `.env` yapisi:

```env
GEMINI_API_KEY=buraya_gercek_anahtar
DATABASE_URL=postgresql://user:password@localhost:5432/receipt_scanner
JWT_SECRET=guclu_bir_gizli_anahtar
PORT=3000
```

Backend calistirma komutu:

```bash
cd "/Users/ibrahimdogan/Desktop/ap for hakan/receipt_scanner"
node server.js
```

Saglik kontrolu:

```bash
curl http://localhost:3000/api/health
```

Beklenen sonuc:

- JSON cevap
- `status: "ok"`
- Gercek durum: tamamlandi

### Asama 2. Veritabanini hazirlama

Durum: tamamlandi

Yapilacaklar:

1. Kullanilacak Postgres yolunu sec
2. Servisi baslat
3. `receipt_scanner` adli veritabanini olustur
4. `schema.sql` dosyasini uygula

Ornek komutlar:

```bash
createdb receipt_scanner
psql "postgresql://localhost/receipt_scanner" -f schema.sql
```

Not:

- `psql` PATH uzerinde degil ama `Postgres.app` icinden kullaniliyor.
- Lokal servis su anda `127.0.0.1:5433` uzerinde calisiyor.
- DB bootstrap artik `scripts/start_local_postgres.sh` ile tekrar edilebilir.

### Asama 3. Auth ve temel API akisi

Durum: tamamlandi

Yapilacaklar:

1. `POST /api/auth/register` test et
2. `POST /api/auth/login` test et
3. JWT ile korumali endpoint'leri test et

Beklenen sonuc:

- kullanici olusmali
- token donmeli
- `shopId` donmeli

### Asama 4. Gemini ile receipt scan testi

Durum: bekliyor

Yapilacaklar:

1. Gecerli `GEMINI_API_KEY` tanimla
2. Ornek bir fis resmi ile `/api/receipts/scan` endpoint'ini test et
3. Sonucun DB'ye yazildigini dogrula

Not:

- AI akisinin calismasi icin gercek API anahtari gerekiyor.
- Maliyet notu:
  - Once client-side ve backend disi yollarla dogrula
  - Gerekirse en fazla tek kontrollu scan testi yap

### Asama 5. Flutter istemcisi

Durum: kismi

Yapilacaklar:

1. Flutter SDK kur
2. `flutter doctor` temiz ciksin
3. `mobile_app` icinde dependency'leri kur
4. Uygulamayi iOS simulator veya web'de calistir

Komutlar:

```bash
cd "/Users/ibrahimdogan/Desktop/ap for hakan/receipt_scanner/mobile_app"
flutter pub get
flutter run
```

Not:

- `mobile_app/lib/config/app_config.dart` localhost uzerinden `3000` portuna bakiyor.
- Flutter bu makinede artik kurulu.
- Buna ragmen mevcut derlenmis web build gecici olarak servis edilebiliyor.
- Kaynak koddan yeni web build de alinabildi.

## Kararlar ve Teknik Notlar

- Node `v24.14.0` backend icin su anda kullanilabilir gorunuyor.
- Bu makinede esas problem Node surumu degil, `bcrypt` native binary uyumsuzlugu idi.
- Eklenen `scrypt` fallback yerel gelistirme icin yeterli.
- Mevcut kullanicilarin hash formatina gore:
  - yeni olusan kullanicilar fallback ortaminda `scrypt$...` formatinda kaydolur
  - native `bcrypt` olan baska ortamlarda bcrypt hash'leri calismaya devam eder

## Acik Blokajlar

- [ ] Gemini ile gercek receipt scan akisi henuz test edilmedi
- [ ] Screenshot fallback davranisi tarayicida manuel UX seviyesinde henuz elle denenmedi

## Sonraki Oturumda Ilk Yapilacak Is

Onerilen ilk hedef:

1. `scripts/start_local_postgres.sh` ile DB'yi ayaga kaldir
2. `node server.js` ile API'yi baslat
3. `scripts/start_web_client.sh` ile web istemcisini ac
4. Once PNG/JPG screenshot ile UI davranisini manuel dogrula
5. Sonra maliyeti minimum tutacak sekilde tek bir gercek `/api/receipts/scan` testi yap

### 25. Runtime yeniden baslatma kontrolu

Durum: tamamlandi

Tarih:

- 15 Nisan 2026

Notlar:

- "Uygulama calismiyor" sikayeti uzerine lokal servisler kontrol edildi.
- Tespit:
  - `3000` API portunda listener yoktu
  - `8080` web portunda listener yoktu
  - `5433` PostgreSQL portunda listener yoktu
- Sorunun kod kaynakli degil, servislerin kapali kalmasi oldugu dogrulandi.
- Asagidaki sirayla servisler yeniden ayaga kaldirildi:
  1. `./scripts/start_local_postgres.sh`
  2. `node server.js`
  3. `./scripts/start_web_client.sh`
- Yeniden baslatma sonrasi dogrulamalar:
  - `GET http://127.0.0.1:3000/api/health` -> `200` ve `{"status":"ok"}`
  - `GET http://127.0.0.1:8080` -> `200`
- Sonuc:
  - API yeniden calisiyor
  - Web istemcisi yeniden servis ediliyor
  - Bu tip durumda once port listener kontrolu yapmak en hizli ilk adim

### 26. Coklu dil destegi (i18n) eklendi

Durum: tamamlandi

Tarih:

- 24 Nisan 2026

Notlar:

- Veritabani:
  - `users` tablosuna `preferred_language` kolonu eklendi
  - varsayilan deger `tr`
  - schema buna gore guncellendi
  - lokal DB'ye migration uygulandi:
    - `scripts/apply_preferred_language_migration.js`
- Backend:
  - `src/config/languages.js` eklendi
  - register/login akisina `preferredLanguage` dahil edildi
  - yeni endpoint eklendi:
    - `PUT /api/auth/preferences`
  - receipt scan prompt'u artik kullanicinin dil tercihine gore uretiliyor
  - desteklenen diller:
    - `tr`
    - `en`
    - `de`
  - line item category alanlari kanonik key mantigina tasindi
  - API cevaplari artik `category_key` + gosterim amacli `category` tasiyabiliyor
- Flutter:
  - `flutter_localizations` ve `intl` eklendi
  - `mobile_app/lib/l10n/` altina `app_tr.arb`, `app_en.arb`, `app_de.arb` eklendi
  - `MaterialApp` locale aware hale getirildi
  - auth session icinde `preferredLanguage` saklanmaya baslandi
  - dashboard'a anlik language switcher eklendi
  - sabit metinler ana ekranlar icin ARB dosyalarina tasindi:
    - scan
    - login
    - register
    - dashboard
    - history
    - edit receipt
    - result dialog
- Kategori altyapisi:
  - backend ve Flutter tarafinda kanonik category key kullaniliyor:
    - `food`
    - `stationery`
    - `transport`
    - `electronics`
    - `health`
    - `entertainment`
    - `other`
  - UI gosterimi aktif dile gore yerellesiyor
  - eski Turkce / Ingilizce degerler normalize edilerek calisiyor
- Dogrulama:
  - `node --test` gecti
  - `flutter test` gecti
  - `flutter build web --release` gecti
  - `GET /api/health` -> `200`
  - `GET /` (web 8080) -> `200`
  - kayit testi:
    - `preferredLanguage: "de"` ile hesap olustu
  - preference update testi:
    - `PUT /api/auth/preferences` ile dil `en` yapildi
  - tekrar login testinde `preferredLanguage: "en"` dondu
- Maliyet notu:
  - bu turda gercek `/api/receipts/scan` Gemini cagrisi bilerek calistirilmadi
  - prompt ve dil davranisi unit test + auth/preference smoke test ile dogrulandi

### 27. Arapca (`ar`) dil destegi eklendi

Durum: tamamlandi

Tarih:

- 24 Nisan 2026

Notlar:

- Backend:
  - desteklenen dil listesine `ar` eklendi
  - Gemini prompt dili ve category enum'lari artik Arapca da uretebiliyor
  - receipt category normalize mantigi Unicode harflerle calisacak sekilde genislestirildi
- Flutter:
  - `AppLanguages` artik `tr`, `en`, `de`, `ar` destekliyor
  - yeni locale dosyasi eklendi:
    - `mobile_app/lib/l10n/app_ar.arb`
  - mevcut ARB dosyalarina `arabic` dil etiketi eklendi
  - dashboard language switcher Arapca secenegini gosteriyor
  - Arapca kategori alias'lari eklendi
  - Arapca locale aktifken tema yazilari `Noto Naskh Arabic` ile uretiliyor
- Dogrulama:
  - `node --test` gecti
  - `flutter test` gecti
  - `flutter build web --release` gecti
  - generated l10n dosyalarinda `app_localizations_ar.dart` olustu
  - build bundle icinde Arapca locale ve font izleri goruldu
  - canli auth smoke testi:
    - `POST /api/auth/register` -> `preferredLanguage: "ar"`
    - `POST /api/auth/login` -> `preferredLanguage: "ar"`
- Operasyon notu:
  - canli smoke test sirasinda ilk API cevabi eski Node surecinden geldigi icin `tr` dondu
  - API sureci yeniden baslatildi ve tekrar testte `ar` dogrulandi
  - guncel lokal API oturumu `node server.js` ile yeniden acildi
- Maliyet notu:
  - bu turda da gercek Gemini scan cagrisi yapilmadi
  - sadece test/build ve auth smoke ile dogrulama yapildi

### 28. Dil secici gorunumu bayrak emojileriyle iyilestirildi

Durum: tamamlandi

Tarih:

- 24 Nisan 2026

Notlar:

- Flutter dashboard language switcher gorsel olarak iyilestirildi
- Dil seceneklerine ulke bayrak emojileri eklendi:
  - `tr` -> `🇹🇷`
  - `en` -> `🇬🇧`
  - `de` -> `🇩🇪`
  - `ar` -> `🇸🇦`
- App bar icindeki dil acici artik:
  - secili dilin bayragini gosteriyor
  - secili dil kodunu (`TR`, `EN`, `DE`, `AR`) gosteriyor
  - onceki sade ikon yerine daha belirgin bir chip/pill gorunumu kullaniyor
- Dropdown satirlari artik:
  - bayrak emojisini
  - dil adini
  - gerekiyorsa native adini
  - secili durumda check icon'unu
    birlikte gosteriyor
- Dogrulama:
  - `flutter test` gecti
  - `flutter build web --release` gecti
- Not:
  - degisiklik web build'e yazildi; acik tarayici sekmesinde yenileme yeterli

### 29. Dil secici tum sekmelere tasindi

Durum: tamamlandi

Tarih:

- 24 Nisan 2026

Notlar:

- Dil secici ortak Flutter widget'ina tasindi:
  - `mobile_app/lib/widgets/language_switcher_button.dart`
- Bu sayede ayni gorunum ve davranis su ekranlarda ortak kullaniliyor:
  - `Dashboard`
  - `Scan`
  - `History`
- `Dashboard` ekranindaki onceki inline menu mantigi kaldirildi ve ortak widget'a gecildi
- `Scan` ekraninda alan daralmasini onlemek icin compact varyant kullanildi
- `History` ekraninin `SliverAppBar` actions kismina dil secici eklendi
- Dogrulama:
  - `flutter test` gecti
  - `flutter build web --release` gecti
- Not:
  - yeni gorunum web build'e yazildi; tarayicida yenileme yeterli

### 30. PostgreSQL RLS ile multi-tenant izolasyon aktif edildi

Durum: tamamlandi

Tarih:

- 24 Nisan 2026

Notlar:

- SQL / schema:
  - `shops`, `users`, `receipts`, `line_items` tablolarinda RLS aktif edildi
  - tum bu tablolarda `FORCE ROW LEVEL SECURITY` aktif edildi
  - `tenant_isolation` policy'leri eklendi
  - policy mantigi:
    - `shop_id = current_setting('app.current_shop_id', true)::uuid`
- Backend:
  - `src/config/db.js` tenant-aware hale getirildi
  - yeni yardimcilar:
    - `queryWithTenant(shopId, queryText, values)`
    - `withTenantClient(shopId, callback)`
    - `queryAsPrivileged(...)`
    - `withPrivilegedClient(...)`
  - auth register/login akisi artik ayrik auth/bypass pool ile calisiyor
  - `auth/preferences` tenant pool altina alindi
  - `receipts`, `dashboard` ve `receiptService` tenant transaction helper'larini kullanacak sekilde guncellendi
- Roller / env:
  - uygulama rolu:
    - `turk_patent`
    - `NOBYPASSRLS`
  - auth/bootstrap rolu:
    - `turk_patent_auth`
    - `BYPASSRLS`
  - `.env` guncellendi:
    - `DATABASE_URL=postgresql://turk_patent@127.0.0.1:5433/receipt_scanner`
    - `AUTH_DATABASE_URL=postgresql://turk_patent_auth@127.0.0.1:5433/receipt_scanner`
    - `ADMIN_DATABASE_URL=postgresql://ibrahimdogan@127.0.0.1:5433/receipt_scanner`
  - `scripts/start_local_postgres.sh` auth rolunu da olusturacak sekilde guncellendi
- Migration:
  - yeni script eklendi:
    - `scripts/apply_rls_migration.js`
  - mevcut lokal DB'ye basariyla uygulandi
  - migration sonucu:
    - `shops`, `users`, `receipts`, `line_items` icin `rowsecurity=true`
    - `force_rls=true`
- Dogrulama:
  - `node --test` gecti
  - syntax kontrolleri gecti:
    - `src/config/db.js`
    - `src/routes/auth.js`
    - `src/routes/receipts.js`
    - `src/routes/dashboard.js`
    - `src/services/receiptService.js`
    - `scripts/apply_rls_migration.js`
  - dogrudan DB testi:
    - app rolu `turk_patent` tenant set edilmeden `receipts` tablosunda `0` satir gordu
    - `app.current_shop_id` set edilince ilgili tenant icin sadece kendi satirlarini gordu
  - API smoke testi:
    - iki ayri tenant kaydi olusturuldu
    - `POST /api/receipts/import` her tenant icin ayri calisti
    - `GET /api/dashboard/history` her tenant icin yalnizca kendi receipt'ini dondurdu
    - `GET /api/dashboard/summary` toplam ve sayi degerlerini tenant bazinda dogru dondurdu
- Operasyon notu:
  - API yeni env ve yeni DB helper'lariyla yeniden baslatildi
- web istemcisi tekrar degistirilmedi; mevcut `8080` servisi calismaya devam ediyor

### 31. JPG/PNG yanina PDF e-fatura ve dijital fis okuma destegi eklendi

Durum: tamamlandi

Tarih:

- 25 Nisan 2026

Notlar:

- Backend:
  - yeni ortak dosya tipi konfigurasyonu eklendi:
    - `src/config/receiptFiles.js`
  - kabul edilen receipt upload tipleri backend tarafinda su hale getirildi:
    - `image/jpeg`
    - `image/png`
    - `image/webp`
    - `application/pdf`
  - `multer` file filter artik MIME tipi veya uzantidan PDF'i normalize edebiliyor
  - upload hata mesajlari request diline gore yerellestirildi:
    - `unsupportedFileType`
    - `missingFile`
  - `src/services/geminiService.js` artik gelen dosyayi image/PDF olarak dinamik `mimeType` ile Gemini'ye gonderiyor
  - prompt metni "image" yerine "receipt, invoice, image, or PDF file" olacak sekilde guncellendi
- Flutter:
  - `mobile_app/pubspec.yaml` icine:
    - `file_picker`
    - `http_parser`
      eklendi
  - `mobile_app/lib/services/receipt_api_service.dart` yeniden duzenlendi:
    - kamera cekimi ile secilen gorseller tek akista toplandi
    - dosya secici JPG/JPEG/PNG/PDF kabul ediyor
    - PDF secilirse gorsel sikistirma tamamen bypass ediliyor
    - multipart upload artik dogru `contentType` ile gidiyor
  - `mobile_app/lib/screens/scan_screen.dart` artik:
    - mobilde `Fotograf Cek` butonu gosteriyor
    - tum platformlarda `JPG, PNG veya PDF Yukle` butonu gosteriyor
    - secilen gorseli preview olarak gosteriyor
    - secilen PDF'i ikonlu dosya karti olarak gosteriyor
    - analizden once secili dosyayi degistirme imkani veriyor
  - yeni tarama metinleri tum desteklenen dillere eklendi:
    - `en`
    - `tr`
    - `de`
    - `ar`
- Testler:
  - yeni backend test dosyasi:
    - `test/receipt_file_support.test.js`
  - yeni Flutter widget testi:
    - `mobile_app/test/scan_screen_test.dart`
  - mevcut Flutter upload testi PDF senaryosunu kapsayacak sekilde guncellendi
- Dokumantasyon:
  - `rules.md` icinde referans verilen ama repoda olmayan temel dokumanlar olusturuldu:
    - `README.md`
    - `test.md`
    - `docs/DOCUMENTATION.md`
    - `docs/API_REFERENCE.md`
    - `docs/DEPLOYMENT.md`
    - `docs/DATABASE_SCHEMA.md`
    - `docs/FILE_INDEX.md`
- Dogrulama:
  - syntax kontrolleri gecti:
    - `src/config/receiptFiles.js`
    - `src/middleware/upload.js`
    - `src/services/geminiService.js`
    - `src/routes/receipts.js`
    - `server.js`
  - Node testleri gecti:
    - `node --test test/i18n_prompt.test.js test/receipt_file_support.test.js test/receipt_categories.test.js test/currency_detection.test.js`
  - Flutter bagimlilikleri guncellendi:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter pub get`
  - Flutter testleri gecti:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - web build gecti:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`
  - API ve web smoke:
    - `GET /api/health` -> `ok`
    - `http://127.0.0.1:8080` -> `200 OK`
  - maliyetsiz upload smoke:
    - bos `POST /api/receipts/scan` istegi Turkce `missingFile` mesaji dondu
    - `text/plain` multipart istegi Turkce `unsupportedFileType` mesaji dondu
  - build bundle izleri:
    - `Upload JPG, PNG, or PDF`
    - `PDF Document`
- Operasyon notu:
  - smoke test sirasinda `3000` portunda eski API surecinin calistigi fark edildi
  - eski surec kapatildi ve `node server.js` ile API yeniden baslatildi
  - guncel API session'i yeni upload/PDF kodunu servis ediyor
- Maliyet notu:
  - bu turda gercek Gemini scan cagrisi bilerek yapilmadi
  - PDF destegi unit test, widget test, build ve Gemini'ye gitmeyen upload smoke kontrolleriyle dogrulandi

## 32. 2026-04-26 - Web cokus + upload/pick dosya secici onarimi

- Problem belirtileri:
  - web uygulamasi beyaz ekranda aciliyordu
  - `JPG, PNG veya PDF Yukle` butonu tiklandiginda dosya secici acilmiyor gibi davraniyordu
  - PDF ozelligi eklendikten sonra scan akisi tamamen kirik gorunuyordu
- Kok neden 1:
  - Flutter web icin son `build/web` ciktisi eksik uretilmis durumdaydi
  - `flutter_bootstrap.js`, `main.dart.js`, `favicon.png` ve `manifest.json` eksik oldugu icin tarayici `404` alip beyaz ekrana dusuyordu
  - ayni projeyi bosluk iceren klasor yolundan dogrudan `flutter build web --release` ile build etmek bu makinede zaman zaman eksik artifact birakiyor
- Kok neden 2:
  - `mobile_app/lib/services/receipt_file_picker_web.dart` icindeki browser picker `named parameter` ile yazilmisti
  - `ReceiptApiService.pickReceiptFile()` ise bunu `Future<ReceiptSelection?> Function(List<String>)` gibi `positional` imza bekleyen bir akista kullaniyordu
  - bunun sonucu web runtime tarafinda picker binding patliyor, buton tiklansa da file chooser guvenilir sekilde acilmiyordu
- Kod duzeltmeleri:
  - `mobile_app/lib/services/receipt_api_service.dart`
    - web picker cagrisi override/non-override diye acik iki dala ayrildi
    - dinamik/uyumsuz function tear-off akisi kaldirildi
  - `mobile_app/lib/services/receipt_file_picker_web.dart`
    - `pickReceiptFileFromBrowser` imzasi `List<String>` positional parametreye cekildi
  - `mobile_app/lib/services/receipt_file_picker_stub.dart`
    - stub imzasi web implementasyonu ile ayni hale getirildi
  - yeni script: `scripts/build_web_client.sh`
    - proje icin no-space bir `/tmp/receipt_scanner_web_build` alias olusturup `flutter build web --release` bu alias uzerinden calisiyor
    - boylece `build/web` altinda eksik bootstrap/entrypoint kalma sorunu pratikte engelleniyor
  - `scripts/start_web_client.sh`
    - server acilmadan once `flutter_bootstrap.js` ve `main.dart.js` varligi kontrol ediliyor
    - build bozuksa erken ve net hata mesaji veriyor
- Dogrulama:
  - Flutter testleri gecti:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - web build iki farkli sekilde dogrulandi:
    - normal `flutter build web --release`
    - yeni `./scripts/build_web_client.sh`
  - `build/web` altinda su dosyalarin geri geldigi dogrulandi:
    - `flutter_bootstrap.js`
    - `main.dart.js`
    - `manifest.json`
    - `favicon.png`
  - `WEB_PORT=8090 ./scripts/start_web_client.sh` ile alternatif portta statik servis acildi
  - `curl -I http://127.0.0.1:8090` -> `200 OK`
  - gecici Playwright smoke testleriyle tarayici davranisi dogrulandi:
    - uygulama artik beyaz ekran yerine yukleniyor
    - accessibility katmani acildiktan sonra `JPG, PNG veya PDF Yukle` butonu file chooser aciyor
    - secilen `PNG` dosyasi scan istegine donusuyor
    - secilen `PDF` dosyasi scan istegine donusuyor
    - her iki smoke testte de page-level runtime hata gorulmedi
- Operasyon notu:
  - gercek `/api/receipts/scan` cagrisi kucuk test PNG ile `Gemini INVALID_ARGUMENT` verdi; bu dosya cok kucuk/temsili oldugu icin AI tarafinda islenemedi
  - bu nedenle son dogrulama Gemini maliyeti yaratmadan, API route'unu mocklayarak yapildi
  - local API `3000` ve mevcut web `8080` akista tutuldu
  - ek acilan debug surecleri (`3001`, `8090`) test sonrasi kapatildi

## Guncelleme Kurali

Bu dosya her ilerleme adiminda guncellenecek.
Yeni oturumda once bu dosya okunacak, sonra bir sonraki `Durum: bekliyor` veya `Durum: kismi` maddesinden devam edilecek.

## 33. 2026-04-27 - KUTE esinli arayuz animasyon sistemi

- Talep:
  - `kute.js-master` icindeki animasyon prototiplerinden uygulamaya en uygun hareket dilini secip Flutter arayuzune uygulamak
- Inceleme:
  - kaynak olarak `README.md` ve demo JS dosyalari incelendi:
    - `docs/assets/js/transformFunctions.js`
    - `docs/assets/js/shadowProperties.js`
    - `docs/assets/js/backgroundPosition.js`
  - uygulamanin mevcut dili karanlik, kart-merkezli ve analitik oldugu icin:
    - `svgMorph` veya `textWrite` gibi daha gosterisli prototipler uygun bulunmadi
    - ana referans olarak `transformFunctions` secildi
    - destekleyici gorunus dili olarak `shadowProperties` ve `backgroundPosition` hissi uyarlandi
- Secilen animasyon yorumu:
  - sayfa gecislerinde yatay/derinlik hissi veren slide + fade
  - bolumlerin yuklenirken kademeli reveal hareketi
  - kartlarda hover/tap sirasinda hafif lift + glow
  - ekran arka planinda yavas hareket eden aurora/orb drift
- Kod degisiklikleri:
  - yeni motion widget'lari eklendi:
    - `mobile_app/lib/widgets/animated_backdrop.dart`
    - `mobile_app/lib/widgets/motion_reveal.dart`
    - `mobile_app/lib/widgets/hover_lift_card.dart`
  - `mobile_app/lib/main.dart`
    - `IndexedStack` gorunumu yerine state'i koruyan animasyonlu screen fade/slide gecisi eklendi
  - `mobile_app/lib/screens/scan_screen.dart`
    - sabit arka plan yerine animasyonlu backdrop kullanildi
    - baslik, alt metin, dosya format paneli ve aksiyon butonlari staggered reveal ile aciliyor
    - secili dosya/PDF kartlari hover lift ile canlandirildi
  - `mobile_app/lib/screens/dashboard_screen.dart`
    - ozet kartlari, para birimi paneli ve trend chart motion reveal + hover lift ile guncellendi
    - dashboard arka plani animasyonlu backdrop ile senkronize edildi
  - `mobile_app/lib/screens/history_screen.dart`
    - liste kartlari reveal ile sirali giriyor
    - kartlar hover lift efekti aliyor
    - expanded detay alani `AnimatedSize` ile daha akici aciliyor
  - `docs/FILE_INDEX.md`
    - yeni motion widget dosyalari indekslendi
  - yeni widget testi:
    - `mobile_app/test/motion_widgets_test.dart`
- Dogrulama:
  - format:
    - `/Users/ibrahimdogan/development/flutter/bin/dart format ...`
  - Flutter test:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - Flutter web build:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`
  - Sonuc:
    - testler gecti
    - web build gecti
- Dokumantasyon notu:
  - runtime, API, env veya veri modeli degismedigi icin `README.md`, `API_REFERENCE.md`, `DEPLOYMENT.md`, `DATABASE_SCHEMA.md` guncellemesi gerekmedi

## 34. 2026-04-27 - Sekme animasyonu cakisimi onarimi

- Problem belirtileri:
  - yeni motion sisteminden sonra `Tarama`, `Panel` ve `Gecmis` sekmeleri temiz ayrilmiyordu
  - aktif sekme degisse bile onceki ekranin icerigi arka planda gorunmeye devam ediyordu
  - ozellikle `Gecmis` ve `Tarama` arasinda gecince ekranlar ust uste binmis gibi hissediliyordu
- Kok neden:
  - `mobile_app/lib/main.dart` icindeki yeni tab gecisi, tum sayfalari ayni `Stack` icinde tutup gorunurlugu `AnimatedOpacity` ile yonetiyordu
  - ekranlarin `Scaffold` arka planlari seffaf oldugu ve her biri kendi `AnimatedBackdrop` katmanini cizdigi icin, pratikte opacity/paint davranisi temiz bir izolasyon hissi vermedi
  - sonuc olarak state korunurken goruntu izolasyonu bozuldu
- Kod duzeltmeleri:
  - `mobile_app/lib/main.dart`
    - coklu `Positioned.fill + AnimatedOpacity + AnimatedSlide` yapi kaldirildi
    - yerine state koruyan `IndexedStack` geri getirildi
    - tab degisiminde yalnizca aktif ekranin kisa bir `FadeTransition + SlideTransition` ile giris yapmasi saglandi
  - yeni regresyon testi:
    - `mobile_app/test/main_shell_navigation_test.dart`
    - login session mock'lanarak `Tarama -> Gecmis` gecisinde onceki ekran metninin artik gorunmedigi dogrulandi
- Dogrulama:
  - format:
    - `/Users/ibrahimdogan/development/flutter/bin/dart format mobile_app/lib/main.dart mobile_app/test/main_shell_navigation_test.dart`
  - Flutter test:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test test/main_shell_navigation_test.dart`
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - Flutter web build:
    - `./scripts/build_web_client.sh`
  - Gercek tarayici smoke testi:
    - Playwright ile `http://127.0.0.1:8080` uzerinde canli tur atildi
    - login yapildi
    - `Tarama -> Panel -> Gecmis -> Tarama` sekme dongusu tekrarlandi
    - artik ekranlar birbirinin arkasinda gorunmuyor
    - page-level runtime exception gorulmedi
- Operasyon notu:
  - headless Chromium tarafinda yalnizca Flutter CanvasKit/WebGL'e ait `GPU stall due to ReadPixels` warning loglari goruldu
  - bunlar uygulama exception'i degil; `pageerror` listesi bosti

## 35. 2026-04-27 - Turkce karakter duzeltmesi

- Problem belirtileri:
  - Turkce seciliyken bazi arayuz metinleri ASCII fallback ile gorunuyordu
  - ornekler:
    - `JPG, PNG veya PDF Yukle`
    - `Fotograf cek veya ... detaylari AI cikarsin`
    - `Fis`, `Gecmis`, `Giris Yap`, `Turkce`
- Kok neden:
  - `mobile_app/lib/l10n/app_tr.arb` dosyasindaki Turkce ceviriler buyuk oranda Turkce karakter kullanmadan yazilmisti
  - uygulama l10n jenerasyonu bu kaynagi birebir kullandigi icin hatali yazi tum Turkce UI'a yayiliyordu
- Kod duzeltmeleri:
  - `mobile_app/lib/l10n/app_tr.arb`
    - Turkce kullaniciya gorunen metinler `ş, ğ, ü, ö, ç, ı, İ` karakterleriyle duzeltildi
  - `mobile_app/lib/config/app_languages.dart`
    - dil secicide `Turkce` yerine `Türkçe` gosterilecek sekilde guncellendi
  - testler guncellendi:
    - `mobile_app/test/scan_screen_test.dart`
    - `mobile_app/test/guest_screens_test.dart`
    - `mobile_app/test/main_shell_navigation_test.dart`
  - l10n jenerasyonu tekrar calistirildi:
    - `flutter gen-l10n`
- Dogrulama:
  - Flutter test:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - Flutter web build:
    - `./scripts/build_web_client.sh`
  - API/Web smoke:
    - `curl http://127.0.0.1:3000/api/health`
    - `curl -I http://127.0.0.1:8080`
  - Gercek tarayici kontrolu:
    - Playwright ile ana sayfa acildi
    - accessibility katmani etkinlestirildi
    - `Fiş Tarayıcı`
    - `JPG, PNG veya PDF Yükle`
    - `Fotoğraf çek veya JPG, PNG ya da PDF yükle; detayları AI çıkarsın`
    - metinlerinin body text icinde gercekten gorundugu dogrulandi

## 36. 2026-04-27 - Hover reaksiyonunun tiklanabilir alanlarla sinirlanmasi

- Problem belirtileri:
  - motion katmani eklendikten sonra web'de bircok kart ve buton fare ustune gelince reaksiyon veriyordu
  - kullanici beklentisi, bu reaksiyonun yalnizca tiklanabilir alanlarda ve tiklama/basma aninda gorunmesiydi
- Kok neden:
  - `HoverLiftCard` wrapper'i hover'i varsayilan olarak aktif sayacak sekilde tasarlanmisti
  - Flutter butonlari da tema seviyesinde varsayilan hover overlay kullanmaya devam ediyordu
- Kod duzeltmeleri:
  - `mobile_app/lib/widgets/hover_lift_card.dart`
    - wrapper iki ayri moda bolundu:
      - `enableHover`
      - `enablePress`
    - varsayilan davranis pasif hale getirildi
    - artik yalnizca acikca isaretlenen alanlar reaksiyon aliyor
  - `mobile_app/lib/screens/history_screen.dart`
    - receipt karti icin sadece `enablePress: true` birakildi
  - `mobile_app/lib/screens/dashboard_screen.dart`
    - para birimi chip'leri icin sadece `enablePress: true` birakildi
  - `mobile_app/lib/main.dart`
    - `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`, `SegmentedButton` tema overlay'leri hover durumunda seffaf olacak sekilde ayarlandi
    - press/focus geri bildirimi korundu
  - test:
    - `mobile_app/test/motion_widgets_test.dart`
    - hover'in pasif, press'in ise acikca etkinlestirilen kartta aktif oldugu regression testi eklendi
- Dogrulama:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test test/motion_widgets_test.dart`
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - `./scripts/build_web_client.sh`
  - Playwright ile ana sayfada `JPG, PNG veya PDF Yükle` butonunun hover oncesi/sonrasi klibi alindi
  - goruntu karsilastirmasinda butonun hover'da artik gorunur bir reaksiyon vermedigi dogrulandi

## 37. 2026-04-27 - Aksiyon butonlari ve panel sekmeleri icin hover geri bildiriminin geri acilmasi

- Talep:
  - panel gecis sekmeleri hover geri bildirimi alsin
  - aksiyon isteyen butonlar:
    - PDF/foto yukleme
    - dil degistirme
    - giris/cikis
  - ayni sekilde hover overlay animasyonu alsin
- Uygulanan degisiklikler:
  - `mobile_app/lib/main.dart`
    - tema seviyesinde `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`, `SegmentedButton` icin hover overlay tekrar aktif edildi
    - `NavigationBarThemeData.overlayColor` eklenerek alt panel sekmelerine hover geri bildirimi verildi
  - `mobile_app/lib/widgets/language_switcher_button.dart`
    - `PopupMenuButton.style` ile dil secici trigger'ina hover/press overlay eklendi
  - `mobile_app/lib/screens/scan_screen.dart`
    - ust bardaki `Giris Yap` / `Cikis Yap` pill'i `InkWell` tabanli hale getirilip hover overlay kazandirildi
  - `mobile_app/test/motion_widgets_test.dart`
    - action control theme overlay regression testi eklendi
- Dogrulama:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test test/motion_widgets_test.dart`
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - `./scripts/build_web_client.sh`
  - Playwright ile hover klipleri alinarak asagidaki alanlar canli dogrulandi:
    - `JPG, PNG veya PDF Yükle`
    - `Giriş Yap`
    - dil secici
    - `Panel` sekmesi

## 38. 2026-04-27 - Tarama ekranina canli kamera capture ozelliginin eklenmesi

- Talep:
  - Scan ekraninda dosya yuklemenin yanina anlik kamera taramasi eklensin
  - web tarafinda once kamera erisim izni istensin
  - izin sonrasi canli preview acilsin ve kullanici fis goruntusunu yakalayabilsin
- Uygulanan degisiklikler:
  - okuma sirasi:
    - `rules.md`
    - `README.md`
    - `test.md`
    - `docs/FILE_INDEX.md`
  - `mobile_app/lib/screens/scan_screen.dart`
    - kamera butonu web dahil tum platformlarda gorunur hale getirildi
    - web'de `showLiveCameraCaptureDialog(...)`, mobilde mevcut `image_picker` kamera akisi kullanilacak sekilde branch eklendi
    - secili dosya varken de tekrar kamera ile cekim yapilabilmesi icin ikinci aksiyon satirina kamera butonu eklendi
  - `mobile_app/lib/widgets/live_camera_capture_dialog_web.dart`
    - browser `getUserMedia` tabanli canli kamera bottom sheet'i aktif kullanima alindi
    - ilk ekranda kullanicidan manuel olarak izin isteyen CTA eklendi
    - izin verilince `HtmlElementView` icinde canli `VideoElement` preview gosteriliyor
    - capture aninda canvas uzerinden JPEG frame uretilip `ReceiptSelection` olarak scan akisina donuluyor
    - stream kapama, hata mapleme ve unsupported/denied durumlari eklendi
    - bu Flutter/Dart web surumunde gerekli iki uyumluluk duzeltmesi yapildi:
      - `playsInline` yerine `setAttribute('playsinline', 'true')`
      - `CanvasElement.toBlob('image/jpeg', 0.92)` future tabanli imzaya gore kullanildi
  - `mobile_app/lib/widgets/live_camera_capture_dialog_stub.dart`
    - non-web derleme icin conditional import fallback'i korunuyor
  - `mobile_app/lib/l10n/app_en.arb`
  - `mobile_app/lib/l10n/app_tr.arb`
  - `mobile_app/lib/l10n/app_de.arb`
  - `mobile_app/lib/l10n/app_ar.arb`
    - kamera izin, preview ve capture akisi icin yeni metinler eklendi
  - `mobile_app/test/scan_screen_test.dart`
    - scan ekraninda kamera butonunun yerel metinlerle gorundugunu dogrulayan regresyon beklentileri eklendi
  - `README.md`
    - uygulama kapsamina canli kamera capture destegi not edildi
  - `docs/FILE_INDEX.md`
    - yeni web kamera widget dosyalari dokumante edildi
- Dogrulama:
  - l10n jenerasyonu:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter gen-l10n`
  - format:
    - `/Users/ibrahimdogan/development/flutter/bin/dart format mobile_app/lib/screens/scan_screen.dart mobile_app/lib/widgets/live_camera_capture_dialog_stub.dart mobile_app/lib/widgets/live_camera_capture_dialog_web.dart mobile_app/test/scan_screen_test.dart`
  - Flutter test:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - Flutter web build:
    - `./scripts/build_web_client.sh`
  - API/Web saglik:
    - `curl http://127.0.0.1:3000/api/health`
    - `curl -I http://127.0.0.1:8080`
  - Gercek browser smoke:
    - temp klasorde `playwright-core` ile sistem Chrome kullanildi
    - Flutter web semantics placeholder'i JS ile tiklanarak erişilebilirlik agaci acildi
    - sahte kamera izin/device flag'leri ile `Kamerayı Aç -> Kamera Erişimine İzin Ver -> Fişi Yakala` zinciri gercekten calistirildi
    - `/api/receipts/scan` istegi Gemini maliyeti olusmamasi icin browser route interception ile mock JSON dondu
    - `Mock Market` sonuc dialogu acildi
    - tam olarak 1 adet scan POST atildigi dogrulandi
    - page error ve anlamli console error gorulmedi
- Notlar:
  - Flutter web canvas tabanli oldugu icin browser otomasyonunda once `flt-semantics-placeholder` uzerinden semantics agacini etkinlestirmek gerekiyor
  - canli scan dogrulamasi bu turda gercek Gemini cagrisina baglanmadan tamamlandi; maliyet kuralina uyuldu

## 39. 2026-04-27 - Line item bazli transaction date destegi

- Talep:
  - banka hesap dokumleri ve cok tarihli faturalarda her line item icin ayrik tarih tutulmasi
  - backend prompt/schema, DB kaydi ve Flutter detay gorunumu buna gore guncellensin
- Uygulanan degisiklikler:
  - `schema.sql`
    - `line_items.transaction_date DATE NULL` kolonu eklendi
    - kolon aciklamasi schema comment katmanina yazildi
  - `scripts/apply_line_item_transaction_date_migration.js`
    - idempotent migration script eklendi
    - mevcut satirlarda `transaction_date` bos ise parent `receipts.receipt_date` ile backfill yapiliyor
  - `src/config/receiptCategories.js`
    - `normalizeReceiptLineItems(...)` artik line item bazli `transaction_date` normalize ediyor
    - gecersiz veya eksik satir tarihi varsa `receipt_date` fallback'i uygulaniyor, o da yoksa `null`
  - `src/services/geminiService.js`
    - Gemini response schema line item objelerine `transaction_date` eklendi
    - prompt, banka hesap dokumlerinde satir bazli tarihi yakalama talimati ile guncellendi
  - `src/services/receiptService.js`
    - receipt save insert'i `transaction_date` kolonunu yazacak sekilde guncellendi
  - `src/routes/receipts.js`
    - `scan`, `import` ve `update` akislarinda line item normalization receipt-date fallback ile yapiliyor
    - update akisi line item reinsert sirasinda `transaction_date` de sakliyor
  - `src/routes/dashboard.js`
    - history cevabindaki `line_items` JSON objelerine `transaction_date` eklendi
  - `mobile_app/lib/models/scan_result.dart`
    - `LineItem.transactionDate` eklendi
    - JSON parse/toJson akisi guncellendi
  - `mobile_app/lib/utils/receipt_date_format.dart`
    - line item tarihlerini locale-aware `dd-MM-yyyy` formatina ceviren kucuk util eklendi
  - `mobile_app/lib/widgets/result_dialog.dart`
    - scan sonucu detay dialogunda item adinin altinda transaction date gosteriliyor
  - `mobile_app/lib/screens/history_screen.dart`
    - history expanded detail listesinde item adinin altinda transaction date gosteriliyor
  - `mobile_app/lib/screens/edit_receipt_screen.dart`
    - mevcut line item transaction date degerleri update payload'inda korunuyor
    - yeni item eklenirse backend fallback'i kullanabilsin diye alan bos birakiliyor
  - dokumantasyon:
    - `README.md`
    - `docs/DATABASE_SCHEMA.md`
    - `docs/API_REFERENCE.md`
    - `docs/FILE_INDEX.md`
  - testler:
    - `test/i18n_prompt.test.js`
    - `test/receipt_categories.test.js`
    - `mobile_app/test/currency_format_test.dart`
    - `mobile_app/test/result_dialog_test.dart`
- Dogrulama:
  - format:
    - `/Users/ibrahimdogan/development/flutter/bin/dart format mobile_app/lib/models/scan_result.dart mobile_app/lib/screens/history_screen.dart mobile_app/lib/screens/edit_receipt_screen.dart mobile_app/lib/widgets/result_dialog.dart mobile_app/lib/utils/receipt_date_format.dart mobile_app/test/currency_format_test.dart mobile_app/test/result_dialog_test.dart`
  - backend testleri:
    - `node --test test/i18n_prompt.test.js test/receipt_categories.test.js`
  - migration:
    - `node scripts/apply_line_item_transaction_date_migration.js`
    - sonuc: `Backfilled 28 line item(s).`
  - Flutter test:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - Flutter web build:
    - `./scripts/build_web_client.sh`
  - backend syntax sanity:
    - `node --check src/config/receiptCategories.js`
    - `node --check src/services/geminiService.js`
    - `node --check src/services/receiptService.js`
    - `node --check src/routes/receipts.js`
    - `node --check src/routes/dashboard.js`
    - `node --check scripts/apply_line_item_transaction_date_migration.js`
  - API smoke:
    - `curl http://127.0.0.1:3000/api/health`
  - Dusuk maliyetli gercek akıs smoke:
    - gecici hesap ile `POST /api/auth/register`
    - `POST /api/receipts/import` icinde:
      - ilk line item icin acik `transaction_date=2026-04-27`
      - ikinci line item icin tarih bos
    - beklenti:
      - import cevabinda tarihler `['2026-04-27', '2026-04-30']`
      - `GET /api/dashboard/history` cevabinda ayni tarihler geri donsun
    - sonuc: dogrulandi
    - cleanup:
      - test shop'u admin DB baglantisi ile silindi
- Notlar:
  - import smoke ilk denemede eski API process'i yeni kodu tasimadigi icin `transaction_date` null dondu
  - API `server.js` yeniden baslatildiktan sonra ayni smoke temiz gecti
  - bu turda gercek Gemini cagrisi yapilmadi; maliyet kurali korundu

## 40. 2026-04-28 - Dashboard trend chart icin aylik/yillik haftalik drill-down

- Talep:
  - aylik veya yillik summary'de tek cubukta toplanan gecmiste, cubuga tiklayinca alttaki haftalik gecmislerin ayni cubugun icinden acilarak gorunmesi
- Uygulanan degisiklikler:
  - backend:
    - `src/services/dashboardTrendService.js`
      - dashboard period konfiglerini ortak yardimciya tasidi
      - aylik ve yillik ozetler icin haftalik drill-down destek metadatasini ekledi
      - top-level trend row'larini `drilldown` listeleriyle zenginlestiren helper eklendi
    - `src/routes/dashboard.js`
      - `/api/dashboard/summary` icinde aylik/yillik trend icin ek haftalik aggregate sorgusu eklendi
      - response `trend` satirlari artik gerekirse `drilldown: [{ date, label_date, total }]` donebiliyor
  - Flutter:
    - `mobile_app/lib/utils/dashboard_trend.dart`
      - nested trend bucket parse eden typed util eklendi
    - `mobile_app/lib/widgets/dashboard_trend_chart.dart`
      - trend chart ayri widget'a tasindi
      - aylik/yillik aggregate bar'a tap ile expand/collapse davranisi eklendi
      - haftalik cubuklar ayni group icinde aciliyor
      - expanded durumda parent toplam silhouette'i icin faint background rod kullaniliyor
      - chart animasyonu `easeOutCubic` ile yumusatildi
      - tooltip'ler top-level veya haftalik detay tarihini ve tutari gosteriyor
    - `mobile_app/lib/screens/dashboard_screen.dart`
      - eski inline chart kodu yeni widget'a baglandi
  - Dokumantasyon:
    - `docs/API_REFERENCE.md`
    - `docs/FILE_INDEX.md`
  - Testler:
    - `test/dashboard_trend_service.test.js`
    - `mobile_app/test/dashboard_trend_test.dart`
    - `mobile_app/test/dashboard_trend_chart_test.dart`
- Dogrulama:
  - backend syntax:
    - `node -c src/routes/dashboard.js`
    - `node -c src/services/dashboardTrendService.js`
  - backend unit:
    - `node --test test/dashboard_trend_service.test.js`
    - `node --test test/*.test.js`
  - Flutter format:
    - `/Users/ibrahimdogan/development/flutter/bin/dart format mobile_app/lib/screens/dashboard_screen.dart mobile_app/lib/utils/dashboard_trend.dart mobile_app/lib/widgets/dashboard_trend_chart.dart mobile_app/test/dashboard_trend_test.dart mobile_app/test/dashboard_trend_chart_test.dart`
  - Flutter test:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test mobile_app/test/dashboard_trend_test.dart mobile_app/test/dashboard_trend_chart_test.dart`
    - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - Flutter web build:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`
  - API/Web saglik:
    - `curl http://127.0.0.1:3000/api/health`
  - Dusuk maliyetli API smoke:
    - gecici tenant ile iki farkli haftaya dusen iki receipt `POST /api/receipts/import` ile kaydedildi
    - `GET /api/dashboard/summary?period=monthly`
      - beklenti: tek aylik bucket + `drilldown.length === 2`
    - `GET /api/dashboard/summary?period=yearly`
      - beklenti: tek yillik bucket + `drilldown.length === 2`
    - sonuc: dogrulandi
    - cleanup:
      - gecici test shop'u `ADMIN_DATABASE_URL` uzerinden silindi
- Notlar:
  - ilk smoke denemesinde `3000` portunda eski API process'i calistigi icin yeni `drilldown` alani response'ta yoktu
  - eski process kapatildi ve `node server.js` ile yeni backend yeniden baslatildi
  - bu turda gercek Gemini cagrisi yapilmadi; maliyet kurali korundu

## 2026-04-30 - Firebase Migration

- Hedef:
  - PostgreSQL + JWT/bcrypt + yerel receipt dosya akisini Firebase Auth + Firestore + Firebase Cloud Storage mimarisine tasimak
- Yapilanlar:
  - Backend:
    - `package.json`
      - dogrudan `pg`, `bcrypt`, `jsonwebtoken` bagimliliklari kaldirildi
      - `firebase-admin` aktif backend data/auth katmani olarak birakildi
    - `src/config/firebaseAdmin.js`
      - Firebase Admin bootstrap eklendi
      - service account JSON, parcali env alanlari veya `GOOGLE_APPLICATION_CREDENTIALS` destekleniyor
    - `src/config/db.js`
      - Firestore collection helper katmani olarak yeniden yazildi
    - `src/middleware/firebaseAuth.js`
      - Flutter'dan gelen Firebase ID Token `verifyIdToken` ile dogrulaniyor
    - `src/routes/auth.js`
      - register/login artik Firebase token aliyor
      - Firestore `shops` ve `users` dokumanlarini bootstrap ediyor
    - `src/routes/receipts.js`
      - receipt dosyalari artik Firebase Cloud Storage'a yukleniyor
      - download URL `scanned_image_url`, path ise `scanned_image_path` olarak kaydediliyor
    - `src/routes/dashboard.js`
      - tum SQL sorgulari silindi
      - summary/history artik Firestore receipt dokumanlarindan in-memory aggregate ile uretiliyor
    - `src/services/firestoreDataService.js`
      - `shops`, `users`, `receipts` CRUD ve tenant context buraya toplandi
    - `src/services/firestoreDashboardService.js`
      - Firestore receipts -> dashboard summary/history aggregate servisi eklendi
    - `src/services/geminiService.js`
      - Gemini artik buffer veya Firebase Storage download URL'sinden receipt okuyabilecek sekilde genislestirildi
    - `src/services/storageService.js`
      - Cloud Storage upload/delete helper eklendi
    - `src/services/passwordService.js`
      - tamamen kaldirildi
  - Flutter:
    - `mobile_app/pubspec.yaml`
      - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` eklendi
    - `mobile_app/lib/config/firebase_runtime_options.dart`
      - Firebase client config `--dart-define` ile okunuyor
    - `mobile_app/lib/services/firebase_bootstrap.dart`
      - Firebase Core init korumali sekilde eklendi
    - `mobile_app/lib/services/auth_service.dart`
      - register/login Firebase Auth uzerinden calisiyor
      - basarili login/register sonrasi Firebase ID Token backend'e gonderiliyor
      - token yenileme, prefs persist ve guest receipt import akisi yeni yapida korundu
    - `mobile_app/lib/services/dashboard_service.dart`
      - backend cagrilarinda taze Firebase token header'a ekleniyor
    - `mobile_app/lib/services/receipt_api_service.dart`
      - scan upload istegi artik async auth header builder kullaniyor
    - `mobile_app/lib/screens/login_screen.dart`
    - `mobile_app/lib/screens/register_screen.dart`
      - Firebase auth hata kodlari artik lokalize mesajlara map ediliyor
    - `mobile_app/lib/utils/auth_error_message.dart`
      - auth hata lokalizasyon mapper'i eklendi
    - `mobile_app/lib/l10n/*.arb`
      - yeni auth hata metinleri `tr/en/de/ar` icin eklendi
  - Dokumantasyon:
    - `README.md`, `.env.example`, `schema.sql`
    - `docs/API_REFERENCE.md`, `docs/DATABASE_SCHEMA.md`, `docs/DEPLOYMENT.md`, `docs/FILE_INDEX.md`
      - tumu Firebase mimarisine gore guncellendi
- Testler:
  - backend syntax:
    - `node -c server.js`
    - `node -c src/routes/auth.js`
    - `node -c src/routes/receipts.js`
    - `node -c src/routes/dashboard.js`
    - `node -c src/services/firestoreDataService.js`
    - `node -c src/services/firestoreDashboardService.js`
    - `node -c src/services/geminiService.js`
  - backend unit:
    - `node --test test/*.test.js`
      - yeni `test/firestore_dashboard_service.test.js` dahil gecti
  - Flutter tooling:
    - `flutter gen-l10n`
    - `dart format` secili degisen Dart dosyalari uzerinde gecti
  - Flutter test:
    - ilk `flutter test` denemesi Flutter toolchain shader yazma crash'i verdi:
      - `Could not write file to "build/unit_test_assets/shaders/ink_sparkle.frag"`
      - crash log: `mobile_app/flutter_01.log`
    - ayni path olustuktan sonra tekrar denenen tam test:
      - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
      - sonuc: gecti
    - tekil yeni test:
      - `/Users/ibrahimdogan/development/flutter/bin/flutter test test/auth_error_message_test.dart`
      - sonuc: gecti
  - Flutter web build:
    - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`
      - sonuc: gecti
  - Paket kontrolu:
    - `npm install`
    - `npm ls firebase-admin bcrypt jsonwebtoken pg`
      - sonuc: `firebase-admin` dogrudan bagimli; `bcrypt` ve `pg` kaldirildi
      - not: `jsonwebtoken`, `firebase-admin` alt bagimliligi olarak transitif gorunmeye devam ediyor
  - API health:
    - `node server.js`
    - `curl http://127.0.0.1:3000/api/health`
      - sonuc:
        - `status: ok`
        - `firebaseAdminConfigured: false`
    - test amacli process `Ctrl+C` ile kapatildi
- Blocker / Dikkat:
  - Bu workspace icinde gercek Firebase service account ve Flutter client `--dart-define` degerleri olmadigi icin:
    - Firestore canli smoke
    - Firebase Auth register/login canli smoke
    - Cloud Storage canli upload smoke
    - backend `verifyIdToken` ile gercek e2e auth smoke
    dogrudan dogrulanamadi
  - Kod seviyesinde gecis tamamlandi; canli Firebase e2e icin bir sonraki adim gercek proje credential/config setini saglamak

## 2026-05-06 - Firebase Admin Key Path

- Istek:
  - Firebase Admin SDK anahtar yolunu proje icinde `./firebase-service-account.json` olacak sekilde ayarlamak
- Yapilanlar:
  - `.env` icine `GOOGLE_APPLICATION_CREDENTIALS=./firebase-service-account.json` eklendi
  - `.env.example` ayni default yol ile guncellendi
  - `src/config/firebaseAdmin.js` relative `GOOGLE_APPLICATION_CREDENTIALS` yolunu proje kokune gore resolve edecek sekilde guncellendi
  - `.gitignore` icine `firebase-service-account.json` eklendi
  - `README.md` ve `docs/DEPLOYMENT.md` local varsayilan key path bilgisini yansitacak sekilde guncellendi
- Dogrulama:
  - `node -c src/config/firebaseAdmin.js`
  - `FIREBASE_STORAGE_BUCKET=test-bucket node -e "require('dotenv').config(); const { ensureFirebaseAdmin } = require('./src/config/firebaseAdmin'); console.log('before=' + process.env.GOOGLE_APPLICATION_CREDENTIALS); ensureFirebaseAdmin(); console.log('after=' + process.env.GOOGLE_APPLICATION_CREDENTIALS);"`
  - Sonuc:
    - env degeri baslangicta `./firebase-service-account.json` olarak yuklendi
    - `ensureFirebaseAdmin()` sonrasi path `/Users/ibrahimdogan/Desktop/receipt scanner/receipt_scanner/firebase-service-account.json` absolute yoluna resolve edildi

## 2026-05-07 - Flutter Firebase Config Fallback Fix

- Problem:
  - `flutter run` ile acilan web istemcisinde login denemesi `Firebase bu yapi icin henuz yapilandirilmadi.` hatasi veriyordu
  - kok neden: `mobile_app/lib/config/firebase_runtime_options.dart` yalnizca `--dart-define` degerlerini okuyordu
  - oysa projede gecerli `mobile_app/lib/firebase_options.dart` zaten mevcut
- Duzeltme:
  - `firebase_runtime_options.dart` runtime override varsa onu, yoksa `DefaultFirebaseOptions.currentPlatform` fallback'ini kullanacak sekilde guncellendi
  - boylece `flutter run` ve standart web build, ek define verilmeden de Firebase client config bulabiliyor
  - `README.md` ve `docs/DEPLOYMENT.md` yeni davranisla senkronize edildi
  - regresyon testi olarak `mobile_app/test/firebase_runtime_options_test.dart` eklendi
- Dogrulama:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test test/firebase_runtime_options_test.dart`
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - `/Users/ibrahimdogan/development/flutter/bin/flutter build web --release`

## 2026-05-07 - White Screen Startup Fix

- Problem:
  - `flutter run -d chrome` uzerinde uygulama bazen tamamen beyaz sayfada kaliyor ve hicbir widget render etmiyordu
  - kok neden: `main()` icinde `runApp` oncesi `FirebaseBootstrap.ensureInitialized()` ve `AuthService.loadSavedSession()` await ediliyordu
  - bu baslangic zinciri yavasladiginda ya da takildiginda Flutter hic cizilmiyordu
- Duzeltme:
  - `runApp(const ReceiptScannerApp())` artik hemen cagriliyor
  - session yukleme arka planda `AppStartupService.bootstrap()` ile best-effort calisiyor
  - bootstrap icine timeout korumasi eklendi; boylece baslangic future'i sonsuza kadar beklemiyor
  - regresyon testi olarak `mobile_app/test/app_startup_service_test.dart` eklendi
- Dogrulama:
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test test/app_startup_service_test.dart`
  - `/Users/ibrahimdogan/development/flutter/bin/flutter test`
  - `flutter run -d chrome --web-port=52923` uzerinde hot restart sonrasi sayfa HTML'i ve debug oturumu kontrol edildi

## 2026-05-07 - Login Debug With Real Account

- Test edilen hesap:
  - email: kullanici tarafindan paylasildi
  - password: kullanici tarafindan paylasildi
- Bulgular:
  - Firebase web API ile ilk login denemesi `PASSWORD_LOGIN_DISABLED` dondu
  - Identity Platform config uzerinden `signIn.email.enabled=true` ve `passwordRequired=true` acildi
  - sonraki login denemesi `INVALID_LOGIN_CREDENTIALS` dondu
  - Firebase Admin service account key yerelde olusturuldu ve `.env` icine `FIREBASE_STORAGE_BUCKET=reecaiptscanner.firebasestorage.app` eklendi
  - `admin.auth().getUserByEmail(...)` sonucu `auth/user-not-found` dondu
- Sonuc:
  - mevcut durumda bu e-posta Firebase Auth icinde kayitli degil; bu nedenle verilen sifre ile login olmasi teknik olarak mumkun degil
  - backend tarafindaki eksik admin config de ayrica giderildi; siradaki adim kullanici kaydi olusturmak veya dogru sifreyi kullanmak

## 2026-05-08 - Firebase Web Bootstrap Cleanup

- Problem:
  - Flutter Web build icinde login denemesinde `Firebase is not configured for this build yet.` uyarisi tekrar goruluyordu.
  - Firebase client init akisi `main.dart` disinda dolayli bir helper'a bagliydi; bu da hangi config kaynaginin kullanildigini belirsizlestiriyordu.
  - Workspace icinde eski PostgreSQL migration scriptleri, local Postgres helper scriptleri ve eski auth shim dosyalari hala duruyordu.
- Duzeltme:
  - `mobile_app/lib/main.dart` artik `WidgetsFlutterBinding.ensureInitialized()` sonrasinda dogrudan `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` cagiriyor.
  - Firebase init hata ve stack trace bilgileri `developer.log` ve `debugPrintStack` ile console'a ayrintili yazdiriliyor.
  - `mobile_app/lib/services/firebase_bootstrap.dart` sadece `firebase_options.dart` tabanli guarded init mantigi ve hata kaydi tutacak sekilde sadeleştirildi.
  - Ilk denemeden sonra gercek kok nedenin Flutter web plugin registrant zinciri oldugu bulundu; `firebase_core_web`, `firebase_auth_web`, `cloud_firestore_web` ve `firebase_storage_web` icin manuel web registrant eklendi.
  - Bu kayit `mobile_app/lib/services/firebase_web_plugin_registrant.dart` uzerinden hem `main.dart` startup'inda hem de fallback bootstrap icinde cagriliyor.
  - `mobile_app/web/index.html` icine Firebase App/Auth/Firestore/Storage SDK scriptleri eklendi.
  - Kullanilmayan `firebase_runtime_options.dart`, eski Firebase runtime test'i, `jwtAuth.js`, `shopAuth.js`, PostgreSQL migration scriptleri ve local Postgres start/stop scriptleri silindi.
  - `.env` icinden eski `DATABASE_URL`, `AUTH_DATABASE_URL`, `ADMIN_DATABASE_URL` ve `JWT_SECRET` baglanti kalintilari kaldirildi.
  - `README.md`, `docs/DEPLOYMENT.md`, `docs/DATABASE_SCHEMA.md` ve `docs/FILE_INDEX.md` yeni duruma gore guncellendi.
- Dogrulama:
  - `flutter test`
  - `flutter build web --release`
  - `curl -I https://www.gstatic.com/firebasejs/12.7.0/firebase-app-compat.js`
  - `curl http://127.0.0.1:3000/api/health`
  - `curl -I http://127.0.0.1:8080`
  - Headless Chrome ile `http://127.0.0.1:8080` yuklenip console loglari incelendi; artik `FirebaseCoreHostApi.initializeCore` channel-error'i gorulmuyor, yerine Firebase web modullerinin yüklendigi loglaniyor.

## 2026-05-08 - Firestore User/Shop Bootstrap Recovery

- Problem:
  - Firebase Auth login artik geciyordu ancak Firestore'da `users` ve `shops` belgeleri eksik oldugunda uygulama ilerleyemiyordu.
  - `createShopAndUserSession()` sadece tam context varsa degil, bazi eksik durumlarda da erken dondugu icin yari kurulu hesaplar otomatik iyilesmiyordu.
  - `login` cevabi eksik shop durumunda sadece genel bir hata veriyordu; Flutter tarafi da kullaniciyi setup ekranina yonlendiremiyordu.
- Duzeltme:
  - `src/services/firestoreDataService.js` icinde `hasCompleteSessionContext()` ve `buildSuggestedShopName()` eklendi.
  - `createShopAndUserSession()` artik kullanici var ama shop eksik gibi yari kurulu hesaplari transaction icinde onariyor; hem `users` hem `shops` belgelerini merge ederek tamamliyor.
  - `src/routes/auth.js` icinde `POST /api/auth/login` eksik Firestore profilinde artik `404 code=account_setup_required` ve `suggestedShopName` donuyor.
  - Yeni `POST /api/auth/setup-shop` endpoint'i eklendi; mevcut Firebase kullanicisi icin varsayilan magaza kurulumunu tamamliyor.
  - `mobile_app/lib/services/auth_service.dart` icinde `account_setup_required` durumunda Firebase session korunuyor ve `completeShopSetup()` ile backend setup endpoint'ine gidiliyor.
  - `mobile_app/lib/screens/login_screen.dart` artik bu durumda duz Snackbar yerine setup dialogu aciyor.
  - Yeni `mobile_app/lib/screens/shop_setup_screen.dart` kullaniciya e-posta bilgisi, magaza adi alani ve `Yeni Magaza Olustur` aksiyonu sunuyor.
  - `firestore.rules` test mode olarak olusturuldu ve `firebase deploy --only firestore:rules --project reecaiptscanner` ile canli projeye deploy edildi.
- Dogrulama:
  - `node --test test/*.test.js`
  - `flutter test`
  - `flutter build web --release`
  - `curl http://127.0.0.1:3000/api/health`
  - `firebase deploy --only firestore:rules --project reecaiptscanner`
  - Gecici iki Firebase Auth kullanicisi ile canli smoke test calistirildi:
    - auth-only kullanici icin `POST /api/auth/login` => `404 account_setup_required`
    - ayni kullanici icin `POST /api/auth/setup-shop` => `200`, shop ve user belgeleri olustu
    - sonraki `POST /api/auth/login` => `200`
    - ikinci kullanici icin `POST /api/auth/register` => `201`, hem `users` hem `shops` belgeleri ayni anda olustu
  - Smoke test sonunda gecici Auth hesaplari ve Firestore belgeleri temizlendi.

## 2026-05-08 - Receipt Scan Internal Server Error Fix

- Problem:
  - `/api/receipts/scan` cagrisi login sonrasi `500 Internal Server Error` donuyordu.
  - Canli logda Gemini parse adimi basariliydi, hata daha sonra Firebase Storage upload adiminda cikti:
    - `ApiError: The specified bucket does not exist.`
  - Bu hata olunca kullanici sadece generic kirmizi toast goruyordu.
- Duzeltme:
  - `server.js` startup tarafina runtime kontrolleri eklendi:
    - `firebase-service-account.json` yolu resolve edilip okunabilirligi dogrulaniyor
    - `uploads/` klasoru otomatik olusturuluyor ve yazma izni test ediliyor
    - Firebase credential source, storage bucket ve Gemini config durumu console'a yaziliyor
    - global error handler artik request metodu/yolu ile birlikte tam `console.error(err)` stack trace basiyor
    - `/uploads` static olarak servis ediliyor
  - `src/config/firebaseAdmin.js` icinde Admin config kontrolu storage bucket'tan ayrildi; service account path yoksa net hata veriyor, bucket diagnostics export ediliyor.
  - `src/services/geminiService.js` icinde `GEMINI_API_KEY` yoksa net hata veriliyor ve Gemini request hatalari mime/language bilgisiyle zenginlestiriliyor.
  - `src/services/storageService.js` icinde Firebase Cloud Storage upload basarisiz olursa local `uploads/` klasorune fallback kayit eklendi.
  - `src/config/runtimePaths.js` ile local upload path/url/prefix yardimcilari eklendi.
- Dogrulama:
  - `node -c server.js src/config/firebaseAdmin.js src/services/geminiService.js src/services/storageService.js src/config/runtimePaths.js`
  - `node --test test/*.test.js`
  - `curl http://127.0.0.1:3000/api/health`
  - Canli authenticated PDF scan smoke testi:
    - temp Firebase kullanicisi olusturuldu
    - `POST /api/auth/register` ile Firestore profile/shop hazirlandi
    - `/Users/ibrahimdogan/Downloads/ticket.pdf` ile `POST /api/receipts/scan` => `201`
    - response icinde vendor `turna.com`, currency `TRY`, valid `scanned_image_url` ve `scanned_image_path` dondu
    - temp receipt/user/shop temizlendi
  - Ayrica maliyetsiz storage fallback testi:
    - kasitli gecersiz bucket adi ile `uploadReceiptBuffer()` cagrildi
    - upload hatasi loglandi ama dosya `local:shops/...` path'i ve `http://127.0.0.1:3000/uploads/...` URL'i ile yerel fallback'e dustu
    - temp local dosya silindi

## 2026-05-08 - Render Firebase Service Account Env Bootstrap

- Problem:
  - Render ortaminda `firebase-service-account.json` dosyasi bulunmadigi icin file-path tabanli Admin bootstrap kiriliyordu.
  - Hosted deploy tarafinda service account bilgisinin tek satir JSON env degiskeni olarak verilmesi gerekiyor.
- Duzeltme:
  - `src/config/firebaseAdmin.js` artik once `FIREBASE_SERVICE_ACCOUNT` env degiskenini parse ediyor.
  - `FIREBASE_SERVICE_ACCOUNT` gecersiz JSON ise net hata mesaji veriyor.
  - Legacy uyumluluk icin `FIREBASE_SERVICE_ACCOUNT_JSON`, field-based env'ler ve local `GOOGLE_APPLICATION_CREDENTIALS` fallback'i korunuyor.
  - Diagnostics alaninda hangi credential kaynaginin kullanildigi (`env_firebase_service_account`, `google_application_credentials` vb.) artik gorunuyor.
  - `.env.example`, `README.md` ve `docs/DEPLOYMENT.md` Render icin yeni tercih edilen env anahtarini gosterecek sekilde guncellendi.
- Dogrulama:
  - `node -c src/config/firebaseAdmin.js`
  - `node --test test/*.test.js`
  - Env smoke testi:
    - `FIREBASE_SERVICE_ACCOUNT` tek satir JSON olarak verildi
    - `getFirebaseAdminDiagnostics().credentialSource === 'env_firebase_service_account'`
    - `hasFirebaseAdminConfig() === true`

## 2026-05-09 - Main-Only Git Workflow

- Problem:
  - Kullanici branch tabanli akisin kaldirilmasini ve tum branch'lerin `main` altinda toplanmis olmasini istedi.
- Bulgular:
  - `git fetch --all --prune`
  - `git branch --all --verbose --no-abbrev`
  - `git branch -r`
  - Sonuc: repoda sadece `main` ve `origin/main` bulunuyor; merge bekleyen ek branch yok.
- Duzeltme:
  - `rules.md` icindeki branch secimi ve task-branch zorunlulugu kaldirildi.
  - Workflow artik `main`-only olacak sekilde `Mainline Rule` ile guncellendi.
  - `SHIP`, `Git And Commit Rule` ve `Done Gate` satirlari branch referansi icermeyecek sekilde sadeleştirildi.
