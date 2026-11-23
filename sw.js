var C="inventario-v15",L="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js";
var F=["./","./index.html","./manifest.webmanifest","./icons/icon-192.png","./icons/icon-512.png","./icons/icon-maskable-512.png"];
self.addEventListener("install",function(e){e.waitUntil(caches.open(C).then(function(c){return c.addAll(F).then(function(){return fetch(new Request(L,{mode:"no-cors"})).then(function(r){return c.put(L,r)}).catch(function(){})})}));self.skipWaiting()});
self.addEventListener("activate",function(e){e.waitUntil(caches.keys().then(function(k){return Promise.all(k.filter(function(n){return n!==C}).map(function(n){return caches.delete(n)}))}));self.clients.claim()});
self.addEventListener("fetch",function(e){
 if(e.request.method!=="GET")return;
 var u=new URL(e.request.url);
 if(e.request.url===L){e.respondWith(caches.match(L).then(function(m){return m||fetch(e.request).then(function(r){var cp=r.clone();caches.open(C).then(function(c){c.put(L,cp)});return r})}));return}
 if(u.origin!==location.origin)return;
 e.respondWith(fetch(e.request).then(function(r){var cp=r.clone();caches.open(C).then(function(c){c.put(e.request,cp)});return r}).catch(function(){return caches.match(e.request).then(function(m){return m||caches.match("./index.html")})}))});
