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
    if ( slideData.json == null ) {
	setTimeout(showNextSlide, 1000,repeat);
	return;
    }

    var counter = 0;
    var newSlideFound = 0;

    while (!newSlideFound && counter < slideData.json.length) {
	counter = counter + 1;
	
	if ( slideNumber > slideData.json.length - 1 ) {
  	    slideNumber = 0;	
	}

	// When repeat value is false then request is come from Iivari management user interface.
	// Check slide's timer configuration and status only if repeat is true
	if (repeat == true) {
	    // If slide status is not active or time of show not match, continue to next slide
	    if ( checkSlideTimerAndStatus(slideData.json[slideNumber]) == false ) {
		slideNumber = slideNumber + 1;
	    } else {
		newSlideFound = 1;
            }
	} else {
	    newSlideFound = 1;
	}
    }
    
    if (newSlideFound == 0) {
	setTimeout(showNextSlide, 5000, repeat);
    } else { 
	
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
	$(newslide).append(slideData.json[slideNumber]["slide_html"]);
	$(newslide).find('.footer_container').append("<h3 class=\"footer\">" + newtime + "</h3>");
	$(newslide).appendTo('body');

	$(oldslide).hide();
	$(newslide).show();
	$(oldslide).remove();

	slide_delay = slideData.json[slideNumber]["slide_delay"] * 1000;
	slideNumber = slideNumber + 1;
	if (repeat == true) {
	    setTimeout(showNextSlide, slide_delay, repeat);
	}
    }
}

function checkTime(i)
{
    if (i<10) 
	{i="0" + i}
    return i;
}

function checkSlideTimerAndStatus(slide) {
    if (slide.status == false) {
	return false
    }

    var timers = slide.timers

    if (timers.length == 0) {
	return true;
    }
    else {
	var now = new Date();
	for ( i = 0; i < timers.length; i++ ) {
	    if ( ! timers[i]["weekday_" + now.getDay()] ) {
		continue;
	    }

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
		    return true;
		}
	    }
	}
    }
    return false;
}
