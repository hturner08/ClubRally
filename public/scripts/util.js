function addBoard(){
    $("#popup").show();
    
}

function deleteclub(){
    $("#confirm").show();
    $("#overlay").show();
}

function closepopup(){
    $("#confirm").hide();
    $("#overlay").hide();
    $("#editimage").hide();
    $("#popup").hide();
    $("#addhead").hide();
    $("#mail").hide();
}

function openpopup(whichpopup){
    $("#overlay").show();
    $("#" + whichpopup).show();
}

$( document ).ready(function() {
    var day = $("#day").data("day");
    var time = $("#time").data("time");
    var tag = $("#tag").data("tag");
    var checkbox = $("#checkbox").data("checkbox");
    $("#time").val(time);
    $("#tag").val(tag);
    $("#day").val(day);
    $("#checkbox").prop('checked', checkbox);
});

$(document).keyup(function(e) {
     if (e.keyCode == 27) {
        closepopup();
    }
});
