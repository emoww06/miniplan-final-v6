const CACHE_NAME = 'miniplan-v2.2.0';
const urlsToCache = [
  '/',
  '/index.html',
  '/styles.css',
  '/manifest.json',
  '/favicon.ico',
  '/favicon.png',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png',
  '/sw.js'
];

// Service Worker kurulumu
self.addEventListener('install', event => {
  console.log('Service Worker kuruluyor...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Cache açıldı:', CACHE_NAME);
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log('Tüm dosyalar cache\'lendi');
        return self.skipWaiting();
      })
      .catch(error => {
        console.error('Cache hatası:', error);
      })
  );
});

// Service Worker aktivasyonu
self.addEventListener('activate', event => {
  console.log('Service Worker aktifleştiriliyor...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Eski cache siliniyor:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('Service Worker aktif');
      return self.clients.claim();
    })
  );
});

// Cache'den yanıt verme - Offline desteği
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          console.log('Cache\'den yanıt:', event.request.url);
          return response;
        }
        console.log('Network\'ten yanıt:', event.request.url);
        return fetch(event.request)
          .then(response => {
            // Başarılı yanıtları cache'e ekle
            if (response && response.status === 200 && response.type === 'basic') {
              const responseToCache = response.clone();
              caches.open(CACHE_NAME)
                .then(cache => {
                  cache.put(event.request, responseToCache);
                });
            }
            return response;
          })
          .catch(() => {
            console.log('Offline mod:', event.request.url);
            if (event.request.destination === 'document') {
              return caches.match('/index.html');
            }
            // Offline sayfası göster
            return new Response('Offline mod - İnternet bağlantınızı kontrol edin', {
              status: 503,
              statusText: 'Service Unavailable',
              headers: new Headers({
                'Content-Type': 'text/plain',
              })
            });
          });
      })
  );
});

// Background sync
self.addEventListener('sync', event => {
  console.log('Background sync tetiklendi:', event.tag);
  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

// Periodic background sync
self.addEventListener('periodicsync', event => {
  console.log('Periodic sync tetiklendi:', event.tag);
  if (event.tag === 'content-sync') {
    event.waitUntil(doPeriodicSync());
  }
});

// Background sync işlevi
function doBackgroundSync() {
  return new Promise((resolve) => {
    console.log('Background sync çalışıyor...');
    // Burada veri senkronizasyonu yapılabilir
    setTimeout(() => {
      console.log('Background sync tamamlandı');
      resolve();
    }, 1000);
  });
}

// Periodic sync işlevi
function doPeriodicSync() {
  return new Promise((resolve) => {
    console.log('Periodic sync çalışıyor...');
    // Uygulama güncellemelerini kontrol et
    caches.open(CACHE_NAME)
      .then(cache => {
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        console.log('Periodic sync tamamlandı - Cache güncellendi');
        resolve();
      })
      .catch(error => {
        console.error('Periodic sync hatası:', error);
        resolve();
      });
  });
}

// Push notification desteği
self.addEventListener('push', event => {
  console.log('Push notification alındı');
  const options = {
    body: event.data ? event.data.text() : 'MiniPlan hatırlatıcı!',
    icon: '/favicon.ico',
    badge: '/favicon.ico',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'Aç'
      },
      {
        action: 'close',
        title: 'Kapat'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('MiniPlan', options)
  );
});

// Notification tıklama
self.addEventListener('notificationclick', event => {
  console.log('Notification tıklandı:', event.action);
  event.notification.close();

  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Message handling
self.addEventListener('message', event => {
  console.log('Service Worker mesajı alındı:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
}); 