function toggleChat() {
    $_Tawk.toggle();
    return false;
}

$(window).scroll(function (event) {
    var scroll = $(window).scrollTop();
    if(scroll > 200){
        $("nav").css({
            "background-color": "#2E3842"
        });
    }else if(scroll < 200){
        $("nav").css({
            "background-color": "inherit"
        });
    }
    
    if(scroll > 80){
        $("nav#main").css({
            "background-color": "#2E3842"
        });
    }else if(scroll < 80){
        $("nav#main").css({
            "background-color": "inherit"
        });
    }
});