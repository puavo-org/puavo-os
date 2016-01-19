var autoReloadTimeout;
var urlParams;

// Parse query string parameters.
// See https://stackoverflow.com/questions/901115/how-can-i-get-query-string-values-in-javascript
(window.onpopstate = function () {
    var match,
    pl     = /\+/g,  // Regex for replacing addition symbol with a space
    search = /([^&=]+)=?([^&]*)/g,
    decode = function (s) { return decodeURIComponent(s.replace(pl, " ")); },
    query  = window.location.search.substring(1);

    urlParams = {};
    while (match = search.exec(query))
        urlParams[decode(match[1])] = decode(match[2]);
})();

function checkAutoReload() {
    if (urlParams["autoreload"] !== undefined) {
        var interval = parseInt(urlParams["autoreload"], 0);
        if (interval === 0 || isNaN(interval)) {
            clearTimeout(autoReloadTimeout);
        } else {
            autoReloadTimeout = setTimeout("window.location.reload();", interval * 1000);
            document.getElementById("autoreload_checkbox").checked = true;
        }
    }
}

function toggleAutoReload() {
    if (document.getElementById("autoreload_checkbox").checked) {
        window.location.replace("?autoreload=5");
    } else {
        window.location.replace("?autoreload=0");
    }
}
