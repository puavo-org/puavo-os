/* JQS5 - JQS5 - jQuery Simple Standards-Based Slide Show System
 * 
 * Copyright 2008 Steve Pomeroy <steve@staticfree.info>
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.

   Conceptually based on S5, with a little code borrowed from it.
 */

var cur;
var slideCount;

/* initialize the jqs5 rendering */
function jqs5_init(){
	/* inject some elements to stylize each slide */
	var footer = document.createElement('div');

	// a slide container that we'll be putting the content into
	var s = document.createElement('div');
	$(s).addClass('slide');

	fontScale();
}

/* go to either a numbered slide, 'next', 'prev', 'last, or 'first' */
function go(n){
	if(typeof n == 'string'){
		switch(n) {
		case 'next':
			if(cur < (slideCount-1)){
				n = cur + 1;
			}else{
				n = cur;
			}
			break;

		case 'prev':
			if( cur > 0 ){
				n = cur - 1;
			}else{
				n = cur;
			}
			break;

		case 'last':
			n = slideCount - 1;
			break;

		case 'first':
			n = 0;
			break;
		}
	}
	if(n == cur) return;
	var prev = cur;
	cur = n;
	var slides = $('.slide');
	slides.eq(prev).css('z-index', 0);
	slides.eq(cur).css('z-index', 100).fadeIn('medium', function(){ slides.eq(prev).hide()});
	if(n == 0 || prev == 0){
		if(n == 0){
			$('.footer').animate({top: '100%'});
		}else{
			$('.footer').animate({top: '90%'});
		}
	}
	document.location.hash = "#s" + n;
}


/* extend jQuery with a new function */
jQuery.fn.extend({
// selects a node's sibling's until the sibling matches
siblingsUntil: function( match ){
	var r = [];
	$(this).each(function(i){
		for(var n = this.nextSibling; n; n = n.nextSibling){
			if($(n).is(match)){
				break;
			}
			r.push(n);
		}
	});
	return this.pushStack( jQuery.unique( r ) );
}});

/* the below code borrowed from S5 */

function fontScale() {  // causes layout problems in FireFox that get fixed if browser's Reload is used; same may be true of other Gecko-based browsers
	var vScale = 22;  // both yield 32 (after rounding) at 1024x768
	var hScale = 32;  // perhaps should auto-calculate based on theme's declared value?
	if (window.innerHeight) {
		var vSize = window.innerHeight;
		var hSize = window.innerWidth;
	} else if (document.documentElement.clientHeight) {
		var vSize = document.documentElement.clientHeight;
		var hSize = document.documentElement.clientWidth;
	} else if (document.body.clientHeight) {
		var vSize = document.body.clientHeight;
		var hSize = document.body.clientWidth;
	} else {
		var vSize = 700;  // assuming 1024x768, minus chrome and such
		var hSize = 1024; // these do not account for kiosk mode or Opera Show
	}
	var newSize = Math.min(Math.round(vSize/vScale),Math.round(hSize/hScale));
	fontSize(newSize + 'px');
	if (jQuery.browser['mozilla']) {  // hack to counter incremental reflow bugs
		var obj = document.getElementsByTagName('body')[0];
		obj.style.display = 'none';
		obj.style.display = 'block';
	}
}

function fontSize(value) {
	isIE = jQuery.browser['msie'];
	if (!(s5ss = document.getElementById('s5ss'))) {
		if (!isIE) {
			document.getElementsByTagName('head')[0].appendChild(s5ss = document.createElement('style'));
			s5ss.setAttribute('media','screen, projection');
			s5ss.setAttribute('id','s5ss');
		} else {
			document.createStyleSheet();
			document.s5ss = document.styleSheets[document.styleSheets.length - 1];
		}
	}
	if (!isIE) {
		while (s5ss.lastChild) s5ss.removeChild(s5ss.lastChild);
		s5ss.appendChild(document.createTextNode('body {font-size: ' + value + ' !important;}'));
	} else {
		document.s5ss.addRule('body','font-size: ' + value + ' !important;');
	}
}

// 'keys' code adapted from MozPoint (http://mozpoint.mozdev.org/)
function keys(key) {
	if (!key) {
		key = event;
		key.which = key.keyCode;
	}
	switch (key.which) {
		case 10: // return
		case 13: // enter
		case 32: // spacebar
		case 34: // page down
		case 39: // rightkey
		case 40: // downkey
			go('next');
			break;
		case 33: // page up
		case 37: // leftkey
		case 38: // upkey
		case  8: // backspace
			go('prev');
			break;
		case 36: // home
			go(0);
			break;
		case 35: // end
			go(slideCount - 1);
			break;
		case 67: // c
			break;
		case 79: // o
			$('.outline').toggle();
	}
	return false;
}
// Key trap fix, new function body for trap()
function trap(e) {
	if (!e) {
		e = event;
		e.which = e.keyCode;
	}
	try {
		modifierKey = e.ctrlKey || e.altKey || e.metaKey;
	}
	catch(e) {
		modifierKey = false;
	}
	return modifierKey || e.which == 0;
}


function clicker(e) {
	var target;
	if (window.event) {
		target = window.event.srcElement;
		e = window.event;
	} else target = e.target;
	if (target.getAttribute('href') != null) return true;
	if (!e.which || e.which == 1) {
		go('next');
	}
}


