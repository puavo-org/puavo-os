var screenNumber = 0;

screenData = new Object();

updateScreenData();

$(document).ready(function() { showNextScreen(); });

setInterval( "updateScreenData()", 7000);

function updateScreenData() {
    $.retrieveJSON("/screens.json", function(json, status) {
	if (status != "notmodified") {
	    console.log("Update screen data");
	    screenData.json = json;
	}
    });
}
    
function showNextScreen() {
    // wait one second if screenData.json is not defined yet
    if ( typeof(screenData.json) == "undefined" ) {
	//console.log("screenData.json is undfined");
	setTimeout("showNextScreen()", 1000);
    }
    else {
	if ( screenNumber > screenData.json.length - 1 ) {
	    screenNumber = 0;
	}
	console.log("Changed to the next screen");
	console.log("screen_data: " + screenData.json[screenNumber] )
	console.log("screen_data: " + screenData.json[screenNumber]["screen_html"] )
	$("#content").empty().append(screenData.json[screenNumber]["screen_html"]);
	screenNumber = screenNumber + 1
	setTimeout("showNextScreen()", 5000);
    }
}
