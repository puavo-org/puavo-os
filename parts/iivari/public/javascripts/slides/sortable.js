$(document).ready(function(){
    $('#slides').sortable({
        axis: 'y',
        dropOnEmpty: false,
        handle: 'span',
        cursor: 'crosshair',
        items: 'li',
        opacity: 0.4,
        scroll: true,
        update: function(){
            $.ajax({
		type: 'post',
		data: $('#slides').sortable('serialize'),
		dataType: 'script',
		url: 'slides/sort'})
        }
    });
});
