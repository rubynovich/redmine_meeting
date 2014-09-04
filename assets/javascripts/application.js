//= require ./jquery_nested_form

$(document).on('nested:fieldAdded', function(){
    if (! isMobile()) {
        var user_select = $('select[id$=user_id]');
        user_select.attr('style','width:300px; min-width: 300px;');
        user_select.select2();
    }
})