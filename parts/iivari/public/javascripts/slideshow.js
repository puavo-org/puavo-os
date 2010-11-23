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

function showNextSlide(repeat) {
    // wait one second if slideData.json is not defined yet
    if ( typeof(slideData.json) == "undefined" ) {
	setTimeout(showNextSlide, 1000,repeat);
    }
    else {
	if ( slideNumber > slideData.json.length - 1 ) {
	    slideNumber = 0;
	}
	//	$("#content").empty().append(slideData.json[slideNumber]["slide_html"]);

	if ( !checkSlideTimer(slideData.json[slideNumber].timers) && repeat ) {
	    slideNumber = slideNumber + 1;
	    return showNextSlide(repeat);
	}
	
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

	$(oldslide).hide();
	$(newslide).show();
	$(oldslide).remove();

	slideNumber = slideNumber + 1;
	if (repeat == true) {
	    setTimeout(showNextSlide, 5000, repeat);
	}
    }
}

function checkTime(i)
{
    if (i<10) 
	{i="0" + i}
    return i;
}

function checkSlideTimer(timers) {
    if (timers.length == 0) {
	console.log("return true");
	return true;
    }
    else {
	var now = new Date();
	for ( i = 0; i < timers.length; i++ ) {
	    var start_datetime = new Date(timers[i].start_datetime);
	    var end_datetime = new Date(timers[i].end_datetime);
	    var raw_start_time = new Date(timers[i].start_time);
	    var raw_end_time = new Date(timers[i].end_time);
	    var start_time = new Date( now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		raw_start_time.getHours(),
		raw_start_time.getMinutes() );
	    var end_time = new Date( now.getFullYear(),
		now.getMonth(),
		now.getDate(),
		raw_end_time.getHours(),
		raw_end_time.getMinutes() );
	    
	    if ( (start_datetime.toString() == "Invalid Date" || now > start_datetime ) &&
		 ( end_datetime.toString() == "Invalid Date" || now < end_datetime) ) {

		if ( now > start_time && now < end_time ) {
		    console.log("return true");
		    return true;
		}
	    }
	}
    }
    console.log("return false");
    return false;
}
    