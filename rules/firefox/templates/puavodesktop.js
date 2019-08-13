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

apiserver = getenv("PUAVO_APISERVER");
if (apiserver) {
  lockPref("network.negotiate-auth.delegation-uris", apiserver);
  lockPref("network.negotiate-auth.trusted-uris", apiserver);
}

lockPref("nglayout.enable_drag_images", false);
