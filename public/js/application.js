function waitForStatus(status, jid, cnt){
  // set timeout - loop max 10 times - break if condition === true
  $.ajax({
    url: '/status/'+jid,
    method: 'GET'
  }).done(function(response){
      var condition = response;
      if (response === "false" && cnt < 5) {
        cnt++;
        setTimeout(function(){waitForStatus(status, jid, cnt); }, 1000);
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
    $('input[name="status"]').val('');
    $('input[name="status"]').attr('disabled', 'disabled');
    $('input[type="submit"]').attr('disabled', 'disabled');
    $.ajax({
      url: '/tweeting',
      method: 'POST',
      data: {status: status}
    }).done(function(response){
      var jid = response[0];
      $('input[name="status"]').removeAttr('disabled');
      $('input[type="submit"]').removeAttr('disabled');
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
