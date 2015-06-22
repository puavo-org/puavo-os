defaultPref("browser.search.defaultenginename", "Google");
defaultPref("browser.search.selectedEngine", "Google");
lockPref("browser.cache.disk.capacity", 0);
lockPref("browser.cache.disk.enable", false);
lockPref("browser.safebrowsing.enabled", false);
lockPref("browser.safebrowsing.malware.enabled", false);
lockPref("browser.search.showOneOffButtons", false);
lockPref("extensions.blocklist.enabled", false);
lockPref("network.dns.disableIPv6", true);
lockPref("network.seer.enabled", false);
lockPref("print.postscript.paper_size", "iso_a4");
lockPref("toolkit.storage.synchronous", 1);
pref("flashblock.html5video.blocked", false);
pref("flashblock.whitelist", "elisaviihde.fi,rockway.fi,ugri.net,sanomapro.fi,pelastusopisto.fi,suomeasavelin.net,vetamix.net,vimeo.com,youtube.com,google.com,ksml.fi,quizlet.com,downloads.bbc.co.uk,play.spotify.com,satunetti.fi,fun4thebrain.com,veljeksethanhela.net,starfall.com,gapminder.org,openmatikka.fi,ihmisoikeuspeli.fi,yle.fi,ruutu.fi,twitter.com,facebook.com,dreambroker.com,twitch.tv,adobeconnect.com,yahoo.com,bing.com,mll.fi");

homepage=getenv("HOMEPAGE");

if (homepage) {
  lockPref("browser.startup.homepage", homepage);
}

gfx_xrender_enabled = getenv("FIREFOX_LOCKPREF_GFX_XRENDER_ENABLED");
if (gfx_xrender_enabled === "false") {
    lockPref("gfx.xrender.enabled", false);
} else if (gfx_xrender_enabled === "true") {
    lockPref("gfx.xrender.enabled", true);
}

apiserver = getenv("PUAVO_APISERVER");
if (apiserver) {
  lockPref("network.negotiate-auth.delegation-uris", apiserver);
  lockPref("network.negotiate-auth.trusted-uris", apiserver);
}

lockPref("nglayout.enable_drag_images", false);
