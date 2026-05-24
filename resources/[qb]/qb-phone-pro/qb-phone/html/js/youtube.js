// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    var player;
    var youtubeVideoKeyID = document.getElementById('youtubeVideoKeyID');
    var playButton = document.getElementById('playButton');

    playButton.addEventListener('click', function() {
        loadVideo();
    });

    function loadVideo() {
        var videoID = youtubeVideoKeyID.value.trim();
        if (!player) {
            player = new YT.Player('youtubePlayer', {
                height: '200',
                width: '270',
                videoId: videoID,
                events: {
                    'onReady': onPlayerReady
                }
            });
        } else {
            player.loadVideoById(videoID);
        }
    }

    function onPlayerReady(event) {
        event.target.playVideo();
    }
 
});

