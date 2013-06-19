$(document).ready(function() {

  $('#send-tweet').on('submit', function(e){
    e.preventDefault();
    $('#status p').text('Processing Tweet....');
    var status = $('input[name="status"]').val();
    $('input[name="status"]').val('');
    $('input[name="status"]').attr('disabled', 'disabled');
    $('input[type="submit"]').attr('disabled', 'disabled');

    $.ajax({
      url: '/tweeting',
      method: 'POST',
      data: {status: status}
    }).done(function(response){
      if (response === "true"){
        $('#status p').text('Successfully sent tweet!');
        $('#tweeters').append('<li>' + status + '</li>');
      }
      else {
        $('#status p').text("What'd you do wrong!");
      }
      $('input[name="status"]').removeAttr('disabled');
      $('input[type="submit"]').removeAttr('disabled');
    });

  });
});
