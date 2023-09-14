defaultPref("browser.search.defaultenginename", "Google");
defaultPref("browser.search.selectedEngine", "Google");
lockPref("app.update.auto", false);
lockPref("app.update.doorhanger", false);
lockPref("app.update.enabled", false);
lockPref("browser.search.showOneOffButtons", false);
lockPref("browser.shell.checkDefaultBrowser", false);
lockPref("extensions.blocklist.enabled", false);
lockPref("network.dns.disableIPv6", true);
lockPref("network.seer.enabled", false);
lockPref("print.postscript.paper_size", "iso_a4");

homepage=getenv("HOMEPAGE");

if (homepage) {
  lockPref("browser.startup.homepage", homepage);
  lockPref("datareporting.policy.firstRunURL", "");
  lockPref("startup.homepage_welcome_url", "");
}

var auth_uris = [];
apiserver = getenv("PUAVO_APISERVER");
if (apiserver) {
  auth_uris.push(apiserver);
}
nextcloud_topdomain = getenv("PUAVO_NEXTCLOUD_TOPDOMAIN");
if (nextcloud_topdomain) {
  auth_uris.push('https://.' + nextcloud_topdomain);
}

var auth_uris_str = auth_uris.join(',');
if (auth_uris_str) {
  lockPref("network.negotiate-auth.delegation-uris", auth_uris_str);
  lockPref("network.negotiate-auth.trusted-uris", auth_uris_str);
}

user = getenv("USER");
if (user === "guest") {
  // no need to bother guest user with theme choices or any such
  // "first run"-items
  lockPref("browser.startup.homepage_override.mstone", "ignore");
  lockPref("datareporting.policy.firstRunURL", "");
}

lockPref("nglayout.enable_drag_images", false);
