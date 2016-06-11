function addBoard(){
    $("#popup").show();
    $("#overlay").show();
}

function deleteclub(){
    $("#confirm").show();
    $("#overlay").show();
}

function canceldelete(){
    $("#confirm").hide();
    $("#overlay").hide();
}

function closeBoard(){
    $("#popup").hide();
    $("#overlay").hide();
}

$( document ).ready(function() {
    var day = $("#day").data("day");
    var time = $("#time").data("time");
    var tag = $("#tag").data("tag");
    $("#time").val(time);
    $("#tag").val(tag);
    $("#day").val(day);
});
