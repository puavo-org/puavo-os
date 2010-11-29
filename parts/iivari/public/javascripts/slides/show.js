$(document).ready(function(){
    $.ajax({
	url: '/channels/' + channel_id + '/slides/' + slide_id + '/status',
	dataType: "jsonp"
    });


    if( $(".link_slide_timers").length == 0 ) {
	$.ajax({
	    url: '/slides/' + slide_id + '/slide_timers',
	    dataType: "jsonp"
	});

	$(".slide_timers").toggle();
    }

    $(".link_slide_timers").bind("ajax:success", function() {
	$(".slide_timers").toggle();
    });
});

function setTimerListEvent() {
    $(".delete_timer").bind("ajax:success", function() {
	$(this).closest("tr").next().fadeOut();
	$(this).closest("tr").fadeOut();
    });

    $.datepicker.setDefaults($.datepicker.regional[application_locale]);
    $.timepicker.setDefaults($.timepicker.regional[application_locale]);
    $('#slide_timer_start_datetime').datetimepicker();
    $('#slide_timer_end_datetime').datetimepicker({
	hour: 23,
	minute: 59
    });

    $('#slide_timer_end_datetime').datepicker("getDate");

    $('#slide_timer_start_time').timepicker($.timepicker.regional[application_locale]);
    $('#slide_timer_end_time').timepicker($.timepicker.regional[application_locale]);

    $(".weekday_and_action").mouseover(function() {
	$(this).addClass('timer_over');
	$(this).prev().addClass('timer_over');
	$(this).prev().find('.delete_timer').toggle();
    });
    $(".weekday_and_action").mouseout(function() {
	$(this).removeClass('timer_over');
	$(this).prev().removeClass('timer_over');
	$(this).prev().find('.delete_timer').toggle();
    });

    $(".timer").mouseover(function() {
	$(this).addClass('timer_over');
	$(this).next().addClass('timer_over');
	$(this).find('.delete_timer').toggle();
    });
    $(".timer").mouseout(function() {
	$(this).removeClass('timer_over');
	$(this).next().removeClass('timer_over');
	$(this).find('.delete_timer').toggle();
    });
}
