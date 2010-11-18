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
	//	$("#content").empty().append(slideData.json[slideNumber]["slide_html"]);


        var today=new Date();

	var d=today.getDate();
	var mo=today.getMonth()+1;
	var y=today.getYear() + 1900;
	var h=today.getHours();
	var m=today.getMinutes();
	var s=today.getSeconds();

	h=checkTime(h);
	m=checkTime(m);
	s=checkTime(s);

	var newtime = d+"."+mo+"."+y+"  "+h+":"+m;

	oldslide = $('.slide');

	var newslide = document.createElement('div');
	$(newslide).addClass('slide');
	$(newslide).append(slideData.json[slideNumber]["slide_html"] + "<h3 class=\"footer\">" + newtime + "</h3>");
	$(newslide).appendTo('body');

	if( slideData.json.length > 1 )  {
	    $(oldslide).hide();
	    $(newslide).show();
	    $(oldslide).remove();
	}

	slideNumber = slideNumber + 1;
	setTimeout("showNextSlide()", 5000);
    }
}

function checkTime(i)
{
    if (i<10) 
	{i="0" + i}
    return i;
}
