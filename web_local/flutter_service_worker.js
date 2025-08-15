'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "01f454d5b2b0b6c4e033a131a58e8ac4",
"version.json": "7c8c4b6e89c1e2a42f7f75ac52f462a6",
"index.html": "e778fcf5231216dff34fc4b5e2504d0f",
"/": "e778fcf5231216dff34fc4b5e2504d0f",
"main.dart.js": "7c62146f4efb69ffef072ae3e80edb50",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"_redirects": "589b098f951a45588e81aa663243eacd",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "105af78b3259a94ba05460786cb32d87",
"assets/AssetManifest.json": "711b6b3e8e8447ac9d9f6229ac61eb5e",
"assets/NOTICES": "dd61e9f3077d0b50766e14ca55d08d02",
"assets/FontManifest.json": "aa412ef799ba95740c31f500e46652ec",
"assets/AssetManifest.bin.json": "3cef63a077eb7e0bb6a1f911c52ec7f2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "0af81052e8fda0c93206666fa04c03e8",
"assets/fonts/MaterialIcons-Regular.otf": "dfc04ebd69cf5dea0cc0610fcbd8373f",
"assets/assets/m3.png": "aa3549984790e9eac6475b91ad0e7c16",
"assets/assets/m2.png": "8e5eadd7937334db55960c8d8c0261d7",
"assets/assets/m1.png": "1555be0f9f8636c8e8f25ef71e7bf804",
"assets/assets/master_detail_back_banner.png": "65dada530c0728fe2669f0e86e3a088e",
"assets/assets/m5.png": "2c9c67e9d1b01238b8ebff1ffd2914bc",
"assets/assets/master_cloud_banner.png": "2d3ec9ad0dac3e4cb3f05f00af661e40",
"assets/assets/m4.png": "314cb6fae955d2b5fc3191bc0b0b5182",
"assets/assets/m6.png": "4ba9f32098b19ab17beab1f453c95b9e",
"assets/assets/master_detail_banner.png": "65dada530c0728fe2669f0e86e3a088e",
"assets/assets/master_join_banner.png": "2d3ec9ad0dac3e4cb3f05f00af661e40",
"assets/assets/city_selection_banner.png": "65dada530c0728fe2669f0e86e3a088e",
"assets/assets/avatar5.png": "1555be0f9f8636c8e8f25ef71e7bf804",
"assets/assets/avatar4.png": "2c9c67e9d1b01238b8ebff1ffd2914bc",
"assets/assets/avatar6.png": "4ba9f32098b19ab17beab1f453c95b9e",
"assets/assets/avatar7.png": "1e6a2014c23cb0060d923a2b4aaca677",
"assets/assets/avatar3.png": "fe80af3683d6c5a99c0401802a4e3d69",
"assets/assets/avatar2.png": "314cb6fae955d2b5fc3191bc0b0b5182",
"assets/assets/avatar1.png": "8e5eadd7937334db55960c8d8c0261d7",
"assets/assets/master_detail_logo_banner.png": "258f6ad3c92193972d09c93e96956b54",
"assets/assets/master_cloud_banner1.png": "2d3ec9ad0dac3e4cb3f05f00af661e40",
"assets/assets/fonts/SF-Pro-Display-Thin.otf": "f35e961114e962e90cf926bf979a8abc",
"assets/assets/fonts/OpenSans_SemiCondensed-MediumItalic.ttf": "c6bb98a323412d080098dee9099c13c1",
"assets/assets/fonts/SF-Pro-Display-SemiboldItalic.otf": "fce0a93d0980a16d75a2f71173c80838",
"assets/assets/fonts/OpenSans_SemiCondensed-Regular.ttf": "2e7089d5d856a3c989bde3f2810c3d8c",
"assets/assets/fonts/OpenSans-SemiBold.ttf": "a0551be4db7f325256eeceb43ffe4951",
"assets/assets/fonts/OpenSans_SemiCondensed-Bold.ttf": "a2a3ff150eba87a490cd5881cd6f7efb",
"assets/assets/fonts/OpenSans_Condensed-Medium.ttf": "6df71e289c31e6e24a156a47d26aff76",
"assets/assets/fonts/OpenSans_SemiCondensed-Light.ttf": "28161a887edea180316df292b35a2fc6",
"assets/assets/fonts/OpenSans_Condensed-ExtraBold.ttf": "c901af99e22ea981617edee6964acada",
"assets/assets/fonts/COPYRIGHT.txt": "6f493d0b452fd23eb8da3fd73ac5ae0a",
"assets/assets/fonts/Lepka.otf": "312770ed70de89fd3266153bf817b258",
"assets/assets/fonts/SF-Pro-Display-RegularItalic.otf": "87d7573445a739a1a8210207d1b346a3",
"assets/assets/fonts/SF-Pro-Display-Light.otf": "ac5237052941a94686167d278e1c1c9d",
"assets/assets/fonts/OpenSans_SemiCondensed-SemiBoldItalic.ttf": "d9e6ea6daa692c632175b1e1c1852131",
"assets/assets/fonts/OpenSans_Condensed-SemiBold.ttf": "8578371fc22c584289396e0208a4537f",
"assets/assets/fonts/SF-Pro-Display-Regular.otf": "aaeac71d99a345145a126a8c9dd2615f",
"assets/assets/fonts/NauryzKeds.ttf": "1efc9dc7414e979667bdca47989dff12",
"assets/assets/fonts/OpenSans_SemiCondensed-SemiBold.ttf": "63c6cbb9f234bc28219500584565d086",
"assets/assets/fonts/SF-Pro-Display-Bold.otf": "644563f48ab5fe8e9082b64b2729b068",
"assets/assets/fonts/OpenSans_Condensed-LightItalic.ttf": "31867d6eb72477dab55a6ea023687768",
"assets/assets/fonts/OpenSans_Condensed-Bold.ttf": "9a8b3d4395da2a08ae86ec6392408b78",
"assets/assets/fonts/SF-Pro-Display-Medium.otf": "51fd7406327f2b1dbc8e708e6a9da9a5",
"assets/assets/fonts/SF-Pro-Display-Heavy.otf": "a545fc03ce079844a5ff898a25fe589b",
"assets/assets/fonts/OpenSans-Light.ttf": "68e60202714c80f958716e1c58f05647",
"assets/assets/fonts/OpenSans-Italic.ttf": "0d14a7773c88cb2232e664c9d586578c",
"assets/assets/fonts/OpenSans_SemiCondensed-Medium.ttf": "660e92c62c8fe78fe7a62e399431abbb",
"assets/assets/fonts/OpenSans-MediumItalic.ttf": "92a80fdfd3a0200e1bd11284407b6e27",
"assets/assets/fonts/OpenSans_Condensed-Light.ttf": "1a444a0c7de382541bd4e852676adb6b",
"assets/assets/fonts/OpenSans_Condensed-SemiBoldItalic.ttf": "52008500ebd2990a608c97dec8caed67",
"assets/assets/fonts/SF-Pro-Display-Semibold.otf": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/role_selection_banner.png": "2d3ec9ad0dac3e4cb3f05f00af661e40",
"assets/assets/center_memoji.png": "258f6ad3c92193972d09c93e96956b54",
"assets/assets/giveaway_banner.png": "258f6ad3c92193972d09c93e96956b54",
"assets/assets/giveaway_back_banner.png": "65dada530c0728fe2669f0e86e3a088e",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
