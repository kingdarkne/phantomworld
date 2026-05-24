// Track menu state
let menuOpen = false;

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'open') {
        menuOpen = true;
        document.getElementById('app').style.display = 'flex';
        document.body.classList.add('menu-open');

        // Update buttons based on admin status
        const buttons = [
            'btn-earthquake', 'btn-explosion', 'btn-lightning', 'btn-acidrain',
            'btn-heatwave', 'btn-sandstorm', 'btn-fog', 'btn-blackout',
            'btn-meteor', 'btn-tornado', 'btn-emp', 'btn-gravity',
            'btn-slowmo', 'btn-highgravity', 'btn-vehiclechaos', 'btn-police'
        ];

        const labels = {
            'btn-earthquake': 'Trigger Earthquake',
            'btn-explosion': 'Trigger Explosion',
            'btn-lightning': 'Trigger Lightning',
            'btn-acidrain': 'Trigger Acid Rain',
            'btn-heatwave': 'Trigger Heat Wave',
            'btn-sandstorm': 'Trigger Sandstorm',
            'btn-fog': 'Trigger Fog',
            'btn-blackout': 'Trigger Blackout',
            'btn-meteor': 'Trigger Meteor Shower',
            'btn-tornado': 'Trigger Tornado',
            'btn-emp': 'Trigger EMP',
            'btn-gravity': 'Trigger Gravity',
            'btn-slowmo': 'Trigger Slow Mo',
            'btn-highgravity': 'Trigger High Gravity',
            'btn-vehiclechaos': 'Trigger Vehicle Chaos',
            'btn-police': 'Trigger Police Pursuit'
        };

        buttons.forEach(btnId => {
            const btn = document.getElementById(btnId);
            if (btn) {
                if (data.isAdmin) {
                    btn.textContent = labels[btnId];
                    btn.disabled = false;
                    btn.classList.remove('disabled');
                } else {
                    btn.textContent = 'Admin Only';
                    btn.disabled = true;
                    btn.classList.add('disabled');
                }
            }
        });
    } else if (data.action === 'close') {
        menuOpen = false;
        document.getElementById('app').style.display = 'none';
        document.body.classList.remove('menu-open');
    }
});

// Escape key to close menu
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && menuOpen) {
        closeMenu();
    }
});

function closeMenu() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    });
}

function triggerEvent(eventType) {
    fetch(`https://${GetParentResourceName()}/triggerEvent`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            event: eventType
        })
    });
}
