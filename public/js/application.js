$(document).ready(function() {
  
  $('#send-tweet').on('submit', function(e){
    e.preventDefault();
    $('#status p').text('Processing Tweet....');
    var tweet = $('input[name="tweet"]').val();
    $('input[name="tweet"]').val('');
    $('input[name="tweet"]').attr('disabled', 'disabled');
    $('input[type="submit"]').attr('disabled', 'disabled');

    $.ajax({
      url: '/tweeting',
      method: 'POST',
      data: {tweet: tweet}
    }).done(function(response){
      if (response === "true"){
        $('#status p').text('Successfully sent tweet!');
        $('#tweeters').append('<li>' + tweet + '</li>');
      }
      else {
        $('#status p').text("What'd you do wrong!");
      }
      $('input[name="tweet"]').removeAttr('disabled');
      $('input[type="submit"]').removeAttr('disabled');
    });

  });
});
