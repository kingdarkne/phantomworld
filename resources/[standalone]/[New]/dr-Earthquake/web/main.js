$(document).ready((function() {
    var locales = {}

    window.addEventListener('message', event => {
        const { type, bool, locs, minutes } = event.data;
        if (type === 'main') {
            if (bool === 'open') {
                $('.EarthquakeContain h1').text(minutes);
                $('.EarthquakeTitle').html(locales["EarthquakeTitle"]);
                $('.EarthquakeDesc').html(locales["EarthquakeDesc"]);
                $('body').fadeIn(250);
                $('body').css('display', 'flex');
            } else if (bool === 'close') {
                $('body').fadeOut(250);
                setTimeout(() => {
                    $('body').css('display', 'none');
                }, 250);
            } else if (bool === 'update') {
                locales = locs
                $('.EarthquakeTitle').html(locs["EarthquakeTitle"]);
                $('.EarthquakeDesc').html(locs["EarthquakeDesc"]);
            } else {
                $('.EarthquakeContain h1').text("!");
                $('.EarthquakeTitle').html(locales["EarthquakeTitle2"]);
                $('.EarthquakeDesc').html(locales["EarthquakeDesc2"]);
                $('body').fadeIn(250);
                $('body').css('display', 'flex');
            }
        }
    });

    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            $('body').css('display', 'none');
        } 
    });
}));