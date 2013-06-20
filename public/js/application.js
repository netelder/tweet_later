function waitForStatus(status, jid, cnt){
  // set timeout - loop max 10 times - break if condition === true
  $.ajax({
    url: '/status/'+jid,
    method: 'GET'
  }).done(function(response){
      var condition = response;
      if (response === false && cnt < 10) {
        cnt++;
        setTimeout(function(){
          waitForStatus(status, jid, cnt);
        }, 2000);
      }
      else{
        $('#'+jid).text( status + ': ' + condition);
      }
  });
}

$(document).ready(function() {

  $('#send-tweet').on('submit', function(e){
    e.preventDefault();
    var status = $('input[name="status"]').val();
    var date = $('input[name="date"]').val();
    $('input[name="status"]').val('');
    $.ajax({
      url: '/tweeting',
      method: 'POST',
      data: {status: status, date: date}
    }).done(function(response){
      console.log(response);
      var jid = response[0];
      if (response === "false"){
        alert("Tweet failed to post.  Please try again");
      }
      else
      {
      $('#tweeters').append('<li id=' + jid + '>'  + status + ': pending </li>');
      waitForStatus(status, jid, 0);
      }
    });

  });
});
