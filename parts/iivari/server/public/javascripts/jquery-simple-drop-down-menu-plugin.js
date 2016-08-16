/*!
 * jQuery Simple Drop-Down Menu Plugin
 *
 * http://javascript-array.com/scripts/jquery_simple_drop_down_menu/
 *
 */


var timeout    = 500;
var closetimer = 0;
var ddmenuitem = 0;

function jsddm_open() {
    jsddm_canceltimer();
    jsddm_close();
    ddmenuitem = $(this).find('ul').css('visibility', 'visible');
    if (ddmenuitem.length > 0) $(this).find('a').css('height', 'auto');
}

function jsddm_close() {
    if(ddmenuitem) {
	ddmenuitem.css('visibility', 'hidden');
	// Remove "height: auto" setting and use height by css class
	ddmenuitem.prev().css('height', '');
    }
}

function jsddm_timer() {
    closetimer = window.setTimeout(jsddm_close, timeout);
}

function jsddm_canceltimer() {
    if(closetimer) {
	window.clearTimeout(closetimer);
	closetimer = null;
    }
}

$(document).ready(function() {
    $('#jsddm > li').bind('mouseover', jsddm_open)
    $('#jsddm > li').bind('mouseout',  jsddm_timer)
});

document.onclick = jsddm_close;
