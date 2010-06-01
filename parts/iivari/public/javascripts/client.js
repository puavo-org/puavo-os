var slideNumber = 0;

slideData = new Object();

updateSlideData();

$(document).ready(function() { showNextSlide(); });

setInterval( "updateSlideData()", 7000);

function updateSlideData() {
    $.retrieveJSON("/slides.json", function(json, status) {
	if (status != "notmodified") {
	    console.log("Update slide data");
	    slideData.json = json;
	}
    });
}
    
function showNextSlide() {
    // wait one second if slideData.json is not defined yet
    if ( typeof(slideData.json) == "undefined" ) {
	//console.log("slideData.json is undfined");
	setTimeout("showNextSlide()", 1000);
    }
    else {
	if ( slideNumber > slideData.json.length - 1 ) {
	    slideNumber = 0;
	}
	console.log("Changed to the next slide");
	console.log("slide_data: " + slideData.json[slideNumber] )
	console.log("slide_data: " + slideData.json[slideNumber]["slide_html"] )
	$("#content").empty().append(slideData.json[slideNumber]["slide_html"]);
	slideNumber = slideNumber + 1
	setTimeout("showNextSlide()", 5000);
    }
}
