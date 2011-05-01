$(document).ready(function(){
   // Show and hide the post history
   $("#history_button").click(function(event){
     if($("#history").css('display') == 'none'){
       $("#history").slideDown("100");
     } else {
       $("#history").slideUp("100");
     }
   });
 });
