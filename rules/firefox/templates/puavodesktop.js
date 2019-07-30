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

homepage=getenv("HOMEPAGE");

if (homepage) {
  lockPref("browser.startup.homepage", homepage);
  lockPref("datareporting.policy.firstRunURL", "");
  lockPref("startup.homepage_welcome_url", "");
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
