/* Punto Audio: caché de la interfaz, sin almacenar respuestas de Supabase. */
var C="inventario-v18";
var L="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js";
var F=["./","./index.html","./manifest.webmanifest","./icons/icon-192.png","./icons/icon-512.png","./icons/icon-maskable-512.png","./assets/marca.png","./assets/cabecera.png"];

self.addEventListener("install",function(e){
 e.waitUntil(caches.open(C).then(function(c){
  return c.addAll(F).then(function(){
   return fetch(new Request(L,{mode:"no-cors"})).then(function(r){
    if(r.ok||r.type==="opaque")return c.put(L,r);
   }).catch(function(){});
  });
 }).then(function(){return self.skipWaiting()}));
});

self.addEventListener("activate",function(e){
 e.waitUntil(caches.keys().then(function(keys){
  return Promise.all(keys.filter(function(n){return n!==C&&/^inventario-v\d+$/.test(n)}).map(function(n){return caches.delete(n)}));
 }).then(function(){return self.clients.claim()}));
});

self.addEventListener("fetch",function(e){
 if(e.request.method!=="GET")return;
 var u=new URL(e.request.url);
 if(e.request.url===L){
  e.respondWith(caches.open(C).then(function(c){
   return c.match(L).then(function(m){return m||fetch(e.request).then(function(r){if(r.ok||r.type==="opaque")c.put(L,r.clone());return r})});
  }));
  return;
 }
 if(u.origin!==self.location.origin)return;
 e.respondWith(caches.open(C).then(function(c){
  return fetch(e.request).then(function(r){
   if(r.ok)c.put(e.request,r.clone());
   return r;
  }).catch(function(){
   return c.match(e.request).then(function(m){
    if(m)return m;
    if(e.request.mode==="navigate")return c.match("./index.html").then(function(page){return page||Response.error()});
    return Response.error();
   });
  });
 }));
});
