// Uygulama dosyalarÄ±nÄ± Ã¶nbelleÄŸe alÄ±r. Sayfa her aÃ§Ä±lÄ±ÅŸta internetten en gÃ¼ncel sÃ¼rÃ¼mÃ¼ alÄ±r;
// internet yoksa son kaydedilen sÃ¼rÃ¼m aÃ§Ä±lÄ±r. Veriler (Supabase) Ã¶nbelleÄŸe alÄ±nmaz.
const SURUM="v139";
const KABUK = ["./", "./index.html", "./config.js", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png", "./logo-yatay.png", "./logo.jpg"];
self.addEventListener("install", e => { e.waitUntil(caches.open(SURUM).then(c => c.addAll(KABUK)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== SURUM).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const u = new URL(e.request.url);
  if (e.request.method !== "GET" || u.hostname.endsWith("supabase.co")) return;
  const ayniKaynak = u.origin === self.location.origin;
  const kutuphane = /cdnjs\.cloudflare\.com|cdn\.jsdelivr\.net|fonts\.(googleapis|gstatic)\.com/.test(u.hostname);
  if (ayniKaynak) {
    // cache:'no-cache' â†’ tarayÄ±cÄ±nÄ±n HTTP Ã¶nbelleÄŸi atlanÄ±r, sunucuya "deÄŸiÅŸti mi?" sorulur (yeni sÃ¼rÃ¼m hemen gelir)
    e.respondWith(fetch(e.request.url, { cache: "no-cache", credentials: "same-origin" }).then(r => { if (r.ok) { const k = r.clone(); caches.open(SURUM).then(c => c.put(e.request, k)); } return r; })
      .catch(() => caches.match(e.request, { ignoreSearch: true }).then(r => r || caches.match("./index.html"))));
  } else if (kutuphane) {
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request).then(res => { const k = res.clone(); caches.open(SURUM).then(c => c.put(e.request, k)); return res; })));
  }
});
