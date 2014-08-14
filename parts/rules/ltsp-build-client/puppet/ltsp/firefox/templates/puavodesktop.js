defaultPref("browser.search.defaultenginename", "Google");
defaultPref("browser.search.selectedEngine", "Google");
lockPref("browser.cache.disk.capacity", 0);
lockPref("browser.cache.disk.enable", false);
lockPref("browser.safebrowsing.enabled", false);
lockPref("browser.safebrowsing.malware.enabled", false);
lockPref("network.dns.disableIPv6", true);
lockPref("network.seer.enabled", false);
<% if not @api_server.nil? -%>
lockPref("network.negotiate-auth.trusted-uris", "<%= @api_server %>");
lockPref("network.negotiate-auth.delegation-uris", "<%= @api_server %>");
<% end -%>
lockPref("print.postscript.paper_size", "iso_a4");
lockPref("toolkit.storage.synchronous", 1);
pref("flashblock.whitelist", "rockway.fi,ugri.net,sanomapro.fi,pelastusopisto.fi,suomeasavelin.net,vetamix.net,vimeo.com,youtube.com,translate.google.com,ksml.fi,quizlet.com,downloads.bbc.co.uk,play.spotify.com,maps.google.com,satunetti.fi");

homepage=getenv("HOMEPAGE");

if (homepage) {
  lockPref("browser.startup.homepage", homepage);
}
