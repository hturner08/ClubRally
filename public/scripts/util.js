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
}

function openpopup(whichpopup){
    $("#overlay").show();
    $("#" + whichpopup).show();
}

$( document ).ready(function() {
    var day = $("#day").data("day");
    var time = $("#time").data("time");
    var tag = $("#tag").data("tag");
    $("#time").val(time);
    $("#tag").val(tag);
    $("#day").val(day);
});
