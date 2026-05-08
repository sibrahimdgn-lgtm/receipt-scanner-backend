const http = require('http');
const fs = require('fs');
const path = require('path');

const imgPath = process.argv[2];
const shopId = 'd7f8b48a-550f-49c2-aa8d-4fc8db333b66';
const boundary = 'FormBoundary' + Date.now();

const fileData = fs.readFileSync(imgPath);
const filename = path.basename(imgPath);
const mimeType = filename.endsWith('.png') ? 'image/png' : 'image/jpeg';

const pre = Buffer.from(
  '--' + boundary + '\r\n' +
  'Content-Disposition: form-data; name="receipt"; filename="' + filename + '"\r\n' +
  'Content-Type: ' + mimeType + '\r\n\r\n'
);
const post = Buffer.from('\r\n--' + boundary + '--\r\n');
const body = Buffer.concat([pre, fileData, post]);

const opts = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/receipts/scan',
  method: 'POST',
  headers: {
    'Content-Type': 'multipart/form-data; boundary=' + boundary,
    'Content-Length': body.length,
    'x-shop-id': shopId,
  },
};

console.log('Sending', filename, '(' + (fileData.length / 1024).toFixed(1) + ' KB) to API...\n');

const req = http.request(opts, (res) => {
  let d = '';
  res.on('data', (c) => (d += c));
  res.on('end', () => {
    console.log('HTTP Status:', res.statusCode);
    try {
      console.log(JSON.stringify(JSON.parse(d), null, 2));
    } catch {
      console.log(d);
    }
  });
});

req.on('error', (e) => console.error('Request error:', e.message));
req.write(body);
req.end();
const http = require('http');
const fs = require('fs');
const path = require('path');

const imgPath = process.argv[2];
// ÖNEMLİ: Bu e-posta ve şifreyi daha önce /api/auth/register ile oluşturduğun bir hesapla değiştir!
const TEST_EMAIL = 'test@shop.com'; 
const TEST_PASSWORD = 'password123';

if (!imgPath) {
  console.error('Lütfen bir resim yolu belirtin. Kullanım: node test_scan.js <resim_yolu>');
  process.exit(1);
}

// 1. Adım: Login olup Token alma
function loginAndGetToken(callback) {
  const loginData = JSON.stringify({ email: TEST_EMAIL, password: TEST_PASSWORD });
  
  const options = {
    hostname: '127.0.0.1',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(loginData)
    }
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      try {
        const response = JSON.parse(data);
        if (response.token && response.shopId) {
          console.log('✅ Login başarılı! Token alındı.');
          callback(null, { token: response.token, shopId: response.shopId });
        } else {
          callback(new Error('Login başarısız: ' + data));
        }
      } catch (e) {
        callback(e);
      }
    });
  });

  req.on('error', (e) => { callback(e); });
  req.write(loginData);
  req.end();
}

// 2. Adım: Alınan Token ile Fotoğrafı Tarama
function scanReceipt(authData) {
  const boundary = 'FormBoundary' + Date.now();
  const fileData = fs.readFileSync(imgPath);
  const filename = path.basename(imgPath);
  const mimeType = filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

  const pre = Buffer.from(
    '--' + boundary + '\r\n' +
    'Content-Disposition: form-data; name="receipt"; filename="' + filename + '"\r\n' +
    'Content-Type: ' + mimeType + '\r\n\r\n'
  );
  const post = Buffer.from('\r\n--' + boundary + '--\r\n');
  const body = Buffer.concat([pre, fileData, post]);

  const opts = {
    hostname: '127.0.0.1', // localhost yerine 127.0.0.1 kullanımı daha stabil olabilir
    port: 3000,
    path: '/api/receipts/scan',
    method: 'POST',
    headers: {
      'Content-Type': 'multipart/form-data; boundary=' + boundary,
      'Content-Length': body.length,
      'Authorization': 'Bearer ' + authData.token, // JWT Token Eklendi
      'x-shop-id': authData.shopId // Opsiyonel, bazı sistemler header'da da isteyebilir
    },
  };

  console.log(`\n📤 Gönderiliyor: ${filename} (${(fileData.length / 1024).toFixed(1)} KB) -> Gemini API...`);

  const req = http.request(opts, (res) => {
    let d = '';
    res.on('data', (c) => (d += c));
    res.on('end', () => {
      console.log('\n📊 HTTP Durumu:', res.statusCode);
      try {
        console.log(JSON.stringify(JSON.parse(d), null, 2));
      } catch {
        console.log("Sunucu Yanıtı (JSON Değil):", d);
      }
    });
  });

  req.on('error', (e) => console.error('Hata:', e.message));
  req.write(body);
  req.end();
}

// İşlemi Başlat
loginAndGetToken((err, authData) => {
  if (err) {
    console.error('❌ Hata:', err.message);
    return;
  }
  scanReceipt(authData);
});
