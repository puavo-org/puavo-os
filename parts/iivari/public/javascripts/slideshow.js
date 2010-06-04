
function updateSlideData(url, cache) {
    if(cache == true) {
	$.retrieveJSON(url, function(json, status) {
	    if (status != "notmodified") {
		slideData.json = json;
	    }
	});
    }
    else {
	$.getJSON(url, function(data) {
	    slideData.json = data;
	});
    }
}

function showNextSlide() {
    // wait one second if slideData.json is not defined yet
    if ( typeof(slideData.json) == "undefined" ) {
	setTimeout("showNextSlide()", 1000);
    }
    else {
	if ( slideNumber > slideData.json.length - 1 ) {
	    slideNumber = 0;
	}
	$("#content").empty().append(slideData.json[slideNumber]["slide_html"]);
	slideNumber = slideNumber + 1
	setTimeout("showNextSlide()", 5000);
    }
}
