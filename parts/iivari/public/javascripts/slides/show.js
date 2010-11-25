$(document).ready(function(){

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
	$(this).closest("table").closest("tr").prev().fadeOut();
	$(this).closest("table").closest("tr").fadeOut();
    });

/*    $('#slide_timer_start_datetime').datetime({
	userLang: application_locale,
	americanMode: false,
    });
    $('#slide_timer_end_datetime').datetime({
	userLang: application_locale,
	americanMode: false,
    });
*/
    $.datepicker.setDefaults($.datepicker.regional[application_locale]);
    $.timepicker.setDefaults($.timepicker.regional[application_locale]);
    $('#slide_timer_start_datetime').datetimepicker();
    $('#slide_timer_end_datetime').datetimepicker();
    $('#slide_timer_start_time').timepicker($.timepicker.regional[application_locale]);
    $('#slide_timer_end_time').timepicker($.timepicker.regional[application_locale]);

    $(".weekday_and_action").mouseover(function() {
	$(this).addClass('timer_over');
	$(this).prev().addClass('timer_over');
	$(this).find('.delete_timer').toggle();
    });
    $(".weekday_and_action").mouseout(function() {
	$(this).removeClass('timer_over');
	$(this).prev().removeClass('timer_over');
	$(this).find('.delete_timer').toggle();
    });

    $(".timer").mouseover(function() {
	$(this).addClass('timer_over');
	$(this).next().addClass('timer_over');
	$(this).next().find('.delete_timer').toggle();
    });
    $(".timer").mouseout(function() {
	$(this).removeClass('timer_over');
	$(this).next().removeClass('timer_over');
	$(this).next().find('.delete_timer').toggle();
    });
}
