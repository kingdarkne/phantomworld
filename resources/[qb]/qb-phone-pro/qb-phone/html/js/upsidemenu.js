$(document).on('click', "#flight-mode", function() {
    $("#flight-mode").toggleClass('active');
    $(".fa-signal").toggleClass('ac');  
    $("#flight-mode-signal").toggleClass('bc');  
    $("#flight-mode-signal-one").toggleClass('bcc');  
    $("#flight-mode-signal-two").toggleClass('bccc');  
})
// wifi work start 
$(document).on('click', "#wifi-upside", function() {
    $("#wifi-upside").toggleClass('active');
    $("#phone-wifi").toggleClass('active');
    $("#phone-wifi-one").toggleClass('active');
    $("#phone-wifi-two").toggleClass('active');
})

// calculator work start
$(document).on('click', "#calculator-open-up-slide", function() {
    lock();
    $("#calculator-app-in").css({"display":"block"});
    $(".up-side-menu").css({"display":"none"});
    $("#alarm-clock").css({"display":"none"});
})

function data_up(val){
    calc_up.display.value += val;
}
function ac_up(){
    calc_up.display.value = "";
}
function c_up(){
    calc_up.display.value = calc_up.display.value.slice(0, -1);
}
function equal_up(){
    calc_up.display.value = eval(calc_up.display.value);
}

// calculator work end

// battery-saving work start
$(document).on('click', "#battery-saving", function() {
    $("#battery-saving").toggleClass('active');
    $("#battery-col").toggleClass('ac'); 
    $("#battery-col-one").toggleClass('ac'); 
    $("#battery-col-two").toggleClass('ac'); 
    $(".up-side-menu").toggleClass('ac'); 
    $(".col").toggleClass('ac'); 

})
// battery-saving work end

// upside-in flash light work start
$(document).on('click', "#light-up-side", function() {
    $("#flash-Light").css({"display":"block"});
})
$(document).on('click', ".flash-text", function() {
    $("#flash-Light").css({"display":"none"});
})
// upside-in flash light work end

// notepad work start
$(document).on('click', "#notepad-up-side-menu", function() {
    lock();
    $("#notepad").css({"display":"block"});
    $(".up-side-menu").css({"display":"none"});
    // $(".lock-screen").css({"display":"none"});
})

$(document).on('click', ".notepad-text-one", function() {
    $("#notepad").css({"display":"none"});
})

$("#clear-note-btn").click(function() {
    $("#notepad-text").val(''); 
});

var dataArray = []; 
$("#save-note-btn").click(function() {
    var inputText = $("#notepad-text").val(); 
    dataArray.push(inputText); 
    $("#outputList").append("<li>" + inputText + "</li>");
    $("#notepad-text").val('');
});

$("#notepad-text-two").click(function() {
    clearArray();
})

function clearArray() {
    while (dataArray.length > 0) {
        dataArray.pop(); 
    }
    $("#outputList").empty();
}

// notepad work end




function lock() {
    setTimeout(function(){
        $(".lock-screen").animate({bottom: '68vh'}, "slow");
        $(".phone-footer").css({"display":"block"});
        $(".face-lock-top").animate({left: '36%',height:'3%',width:'25%'}, "slow");
        $(".animation-container").css({"display":"none"});
    },[]);
}

// alarm 3 work start
 
$(document).on('click', "#alarm-open-up-slide ", function() {
    lock();
    $("#alarm-clock").css({"display":"block"});
    $(".up-side-menu").css({"display":"none"});
    $(".alarm-on-off").css({"display":"none"});
    $(".stopwatch-on-off").css({"display":"none"});
})

$(document).on('click', ".alarm-clock-back", function() {
    $("#alarm-clock").css({"display":"none"});
})

// alarm btn
$(document).on('click', "#alarm-clock-alarm", function() {
    $(".alarm-on-off").css({"display":"block"});
    $(".stopwatch-on-off").css({"display":"none"});
})
$(document).ready(function() {
    let alarmTime;
    let alarmInterval;

    function checkAlarm() {
        const currentTime = new Date().toLocaleTimeString().slice(0, 5); 
        if (currentTime === alarmTime) {
            clearInterval(alarmInterval);
            $('#alarmMessage').text("Alarm ringing!");
            $('#alarmMessage').show();
            $('#alarmSound')[0].play(); 
            $('#stopAlarmButton').prop('disabled', false);
        }
    }

    $('#setAlarmButton').click(function() {
        alarmTime = $('#alarmInput').val();
        $('#displayedAlarmTime').text(alarmTime);
        $('#alarmMessage').show();
        $('#stopAlarmButton').prop('disabled', true);
        alarmInterval = setInterval(checkAlarm, 1000);
        $("#alarm-open-up-slide-two").toggleClass('active');

    });

    $('#stopAlarmButton').click(function() {
        clearInterval(alarmInterval);
        $('#alarmMessage').hide();
        $('#alarmSound')[0].pause();
        $('#alarmSound')[0].currentTime = 0;
        $('#stopAlarmButton').prop('disabled', true);
        $("#alarm-open-up-slide-two").hide();
    });
});

//stopwatch btn
$(document).on('click', "#alarm-clock-stopwatch", function() {
    $(".stopwatch-on-off").css({"display":"block"});
    $(".alarm-on-off").css({"display":"none"});
})

$(document).ready(function() {
    let timer;
    let isRunning = false;
    let seconds = 0, minutes = 0, hours = 0;
    let lapCounter = 1;

    function updateStopwatch() {
        seconds++;
        if (seconds >= 60) {
            seconds = 0;
            minutes++;
            if (minutes >= 60) {
                minutes = 0;
                hours++;
            }
        }

        const timeString = 
          (hours < 10 ? '0' : '') + hours + ':' +
          (minutes < 10 ? '0' : '') + minutes + ':' +
          (seconds < 10 ? '0' : '') + seconds;

        $('#stopwatch').text(timeString);
    }

    $('#startButton').click(function() {
        if (!isRunning) {
            isRunning = true;
            timer = setInterval(updateStopwatch, 1000); // Update every 1 second
            $('#startButton').prop('disabled', true);
            $('#stopButton').prop('disabled', false);
            $('#resetButton').prop('disabled', true);
            $('#lapButton').prop('disabled', false);
        }
    });

    $('#stopButton').click(function() {
        if (isRunning) {
            isRunning = false;
            clearInterval(timer);
            $('#startButton').prop('disabled', false);
            $('#stopButton').prop('disabled', true);
            $('#resetButton').prop('disabled', false);
            $('#lapButton').prop('disabled', true);
        }
    });

    $('#resetButton').click(function() {
        seconds = 0;
        minutes = 0;
        hours = 0;
        $('#stopwatch').text('00:00:00');
        $('#startButton').prop('disabled', false);
        $('#stopButton').prop('disabled', true);
        $('#resetButton').prop('disabled', true);
        $('#lapButton').prop('disabled', true);
        $('#lapList').empty();
        lapCounter = 1;
    });

    $('#lapButton').click(function() {
        const lapTime = $('#stopwatch').text();
        const lapItem = $('<li>Lap ' + lapCounter + ': ' + lapTime + '</li>');
        $('#lapList').append(lapItem);
        lapCounter++;
    });
});

// ============================
$(document).on('click', "#alarm-open-up-slide-two ", function() {
    lock();
    $("#alarm-clock").css({"display":"block"});
    $(".up-side-menu").css({"display":"none"});
    setTimeout(function(){
        $(".alarm-on-off").css({"display":"block"});
        $(".stopwatch-on-off").css({"display":"none"});
    },1000)
})

$(document).on('click', "#alarm-open-up-slide-three ", function() {
    lock();
    $("#alarm-clock").css({"display":"block"});
    $(".up-side-menu").css({"display":"none"});
    setTimeout(function(){
        $(".stopwatch-on-off").css({"display":"block"});
        $(".alarm-on-off").css({"display":"none"});
    },1000)
})
// alarm 3 work end 




// theme work start
var wallpapers = [
    "./img/backgrounds/default-qbcore.png",
    "./img/backgrounds/pic-one.png",
    "./img/backgrounds/pic-two.png",
    "./img/backgrounds/pic-three.png",
];

$(document).on('click', "#display-light-up-side-menu", function() {
    
    $(".up-side-menu").css({"display":"none"});
    // lock();
    $("#theme-up-side").css({"display":"block"});
})

$(document).on('click', "#theme-close-btn", function() {
    $("#theme-up-side").css({"display":"none"});
})

$(document).on('click', "#theme-one-all", function() {
    $("#theme-up-side").css({"display":"none"});
    $("#phone_bg_change").css("background-image", "url(" + wallpapers[0] + ")");
    $(".lock-screen").css("background-image", "url(" + wallpapers[0] + ")");
})

$(document).on('click', "#theme-two-all", function() {
    $("#theme-up-side").css({"display":"none"});
    $("#phone_bg_change").css("background-image", "url(" + wallpapers[1] + ")");
    $(".lock-screen").css("background-image", "url(" + wallpapers[1] + ")");

})

$(document).on('click', "#theme-three-all", function() {
    $("#theme-up-side").css({"display":"none"});
    $("#phone_bg_change").css("background-image", "url(" + wallpapers[2] + ")");
    $(".lock-screen").css("background-image", "url(" + wallpapers[2] + ")");
})

$(document).on('click', "#theme-four-all", function() {
    $("#theme-up-side").css({"display":"none"});
    $("#phone_bg_change").css("background-image", "url(" + wallpapers[3] + ")");
    $(".lock-screen").css("background-image", "url(" + wallpapers[3] + ")");
})

// theme work end

// all up-side app close work start
$(document).on('click', "#top-up-close-btn", function() {
    $("#theme-up-side").css({"display":"none"});
    $("#alarm-clock").css({"display":"none"});
    $("#notepad").css({"display":"none"});
    $("#calculator-app-in").css({"display":"none"});
    $(".recording").css({"display":"none"});
    $("#youtube").css({"display":"none"});

})

// rotated display work start
$(document).on('click', "#rotate-display", function() {
    $("#rotate-display").toggleClass('active');
    $(".phone-background").toggleClass('polaroid-up-side-work');
    $(".phone-frame").toggleClass('phone-pic-rotated');
})
// rotated display work end

// brightness work start
$(document).ready(function() {
    var brightnessOverlay = $(".ontest");
    var brightnessOverlayAll = $(".all-test");

    var brightnessRange = $("#brightnessRange");

    brightnessRange.on("input", function() {
        var brightnessPercentage = $(this).val();
        var opacity = 1 - brightnessPercentage / 100;
        brightnessOverlay.css("background-color", "rgba(0, 0, 0," + opacity + ")");
        brightnessOverlayAll.css("background-color", "rgba(0, 0, 0," + opacity + ")");
    });
});

$(document).ready(function () {
    function updateBackgroundGradient(value) {
   
        let gradient = "linear-gradient(to right, rgb(255, 255, 255) " + value + "%, rgb(255, 255, 255)  " + value + "%, rgba(0, 0, 0, 0.45)" + value + "%, rgba(0, 0, 0, 0.45) " + value + "%)";


        $("#brightnessRange").css("background", gradient);
    }

    $("#brightnessRange").on("input", function () {
        let brightnessValue = $(this).val();
        updateBackgroundGradient(brightnessValue);
    });

    updateBackgroundGradient($("#brightnessRange").val());
});

// brightness work end
$(document).on('click', "#v-recoding", function() {
    lock();
    $(".up-side-menu").css({"display":"none"});
    $(".recording").css({"display":"block"});
})


let mediaRecorder;
let recordedChunks = []
$('#startRecording').click(function() {
    navigator.mediaDevices.getDisplayMedia({ video: true, audio: true })
        .then(function (stream) {
            mediaRecorder = new MediaRecorder(stream);
            mediaRecorder.ondataavailable = function (event) {
                if (event.data.size > 0) {
                    recordedChunks.push(event.data);
                }
            }
            mediaRecorder.onstop = function () {
                let blob = new Blob(recordedChunks, { type: 'video/webm' });
                let videoURL = URL.createObjectURL(blob);
                $('#recordedVideo').attr('src', videoURL);
            }
            mediaRecorder.start();
            $('#startRecording').prop('disabled', true);
            $('#stopRecording').prop('disabled', false);
        })
        .catch(function (error) {
            console.error('Error accessing screen recording:', error);
        });
})

$('#stopRecording').click(function() {
    if (mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
        $('#startRecording').prop('disabled', false);
        $('#stopRecording').prop('disabled', true);
    }
});
// video recording work end

// audio music work start
$(document).on('click', "#open-music", function() {
    lock();
    $(".up-side-menu").css({"display":"none"});
    $("#youtube").css({"display":"block"});
})

// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    var player;
    var videoInput = document.getElementById('youtubeVideoID');
    var loadBtn = document.getElementById('loadVideoBtn');

    loadBtn.addEventListener('click', function() {
        loadVideo();
    });

    function loadVideo() {
        var videoID = videoInput.value.trim();
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
    $("#volumeRange").on("input", function () {
       let value = $(this).val();
       player.setVolume(value);

       let gradient = "linear-gradient(to right, rgb(255, 255, 255) " + value + "%, rgb(255, 255, 255)  " + value + "%, rgba(0, 0, 0, 0.45)" + value + "%, rgba(0, 0, 0, 0.45) " + value + "%)";
        $("#volumeRange").css("background", gradient);
    });

});
   
