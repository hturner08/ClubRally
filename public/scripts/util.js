function addBoard(){
    $("#popup").show();
    $("#overlay").show();
}

function closeBoard(){
    $("#popup").hide();
    $("#overlay").hide();
}

$( document ).ready(function() {
    var day = $("#day").data("day");
    var time = $("#time").data("time");

    $("#time").val(time);
    $("#day").val(day);
});
