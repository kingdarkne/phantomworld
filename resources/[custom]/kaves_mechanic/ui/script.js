// ALL MADE BY Ayazwai
// Discord: Ayazwai#3900 
// Linkedin: https://www.linkedin.com/in/ayaz-ekrem-770305212/
// Instagram: https://www.instagram.com/ayaz.ekremm/
// Discord Server: https://discord.com/invite/YanMPNg8Zn
// If you use leak your server will be shut down with a copyright claim
// https://ayazwai.dev

$('body, .color-menu, .fitment-menu, .eye').hide();
/////////////////////////////////////////////////////////////////////////////////////////
// VARIABLES'S //
/////////////////////////////////////////////////////////////////////////////////////////

let colorPicker = new iro.ColorPicker('#picker', {
    width: 175,
    layoutDirection : 'vertical',
    borderColor: '#fff',
    borderWidth: 3,
    wheelDirection: 'clockwise',
    sliderSize: 30,
});

let selectedColor = undefined
let cooldown = false;
let mainMenus;
let subMenus; 
let altMenus;
let activeMenuName;
let activeIndex = 0;
let maxIndex = 0;
let firstIndex = 0;
let secondIndex = 0;
let selectedType
let selectedTypeSecond
let inColorMenu = false;
let inFitmentMenu = false;

let firstSelectorItems = [
    "Primary",
    "Secondary",
    "Chameleon",
    "Neon Color",
    "Smoke Color",
    "Wheel Color"
]

let secondSelectorItems = [
    "Classic",
    "Metallic",
    "Matte",
    "Metal",
    "Pearlescent", 
    "Chrome",
]

let colors
let metalcolors
let metallicColors
let chromeColors
let chameleoncolors 
let mattecolors 
let pearlescentColors 
let chameleonIndex = 0;
let rgba = false
let rgbColor = undefined

let wheels = {
    "wheels-width": 1,
    "front-left": 1,
    "front-right": 1,
    "rear-left": 1,
    "rear-right": 1,
}

let buyedComps
let prices 

/////////////////////////////////////////////////////////////////////////////////////////
// UI CONTROL'S //
/////////////////////////////////////////////////////////////////////////////////////////

document.onkeyup = function(data) {
    let key = data.key;

    if (key == "ArrowRight") {
        $('.menu-item').attr('data-active', 'false');
        activeIndex++;
        if (activeIndex == maxIndex) {
            activeIndex = 0;
            $('.menu-items').animate({ scrollLeft: 0 }, 200);
        } else if (activeIndex % 4 == 0) {
            let pageIndex = Math.floor(activeIndex / 4);
            let menuItemWidth = $('.menu-item').outerWidth();
            let scrollAmount = pageIndex * 4.12 * menuItemWidth;
            $('.menu-items').animate({ scrollLeft: scrollAmount }, 200);
        }
        $(`.menu-item[data-id="${activeIndex}"]`).attr('data-active', 'true');
    } else if (key == "ArrowLeft") {
        $('.menu-item').attr('data-active', 'false');
        activeIndex--;
        if (activeIndex < 0) {
            activeIndex = maxIndex - 1;
            let pageIndex = Math.floor(activeIndex / 4);
            let menuItemWidth = $('.menu-item').outerWidth();
            let scrollAmount = pageIndex * 4.12 * menuItemWidth;
            $('.menu-items').animate({ scrollLeft: scrollAmount }, 200);
        } else if ((activeIndex + 1) % 4 == 0) {
            let pageIndex = Math.floor(activeIndex / 4);
            let menuItemWidth = $('.menu-item').outerWidth();
            let scrollAmount = pageIndex * 4.12 * menuItemWidth;
            $('.menu-items').animate({ scrollLeft: scrollAmount }, 200);
        }
        $(`.menu-item[data-id="${activeIndex}"]`).attr('data-active', 'true');
    } else if (key == "Enter") {
        let selected = $(`.menu-item[data-id="${activeIndex}"]`).data('type');
        let selectedId = $(`.menu-item[data-id="${activeIndex}"]`).data('id');

        if (selected == "main") {
            if (mainMenus[selectedId].label == "Paint Booth") {
                openPaintMenu()
                $.post('https://kaves_mechanic/cursorState', JSON.stringify({
                    cursor: true,
                }));
            }else if (mainMenus[selectedId].label == "Wheel Fitment") {
                $.post('https://kaves_mechanic/getWheelFitment', JSON.stringify({}), function(fitmentData){
                    wheels = fitmentData;
                    openFitment()
                });
                $.post('https://kaves_mechanic/cursorState', JSON.stringify({
                    cursor: true,
                }));
            }else if (mainMenus[selectedId].label == "Repair Vehicle") {
                $.post('https://kaves_mechanic/repairVehicle', JSON.stringify({}));
            }else {
                buildMenu("submenu", selectedId, null);
            }
        }else if (selected == "submenu") {
            let mainId = $(`.menu-item[data-id="${activeIndex}"]`).data('mainid');
            let component = $(`.menu-item[data-id="${activeIndex}"]`).data('componentname');
            buildMenu("altmenu", mainId, component);
            $('.menu-items').animate({ scrollLeft: 0 }, 200);
        }else if (selected == "altmenu") {
            let item = $(`.menu-item[data-id="${activeIndex}"]`);
            let itemData = item.data("itemtable")
            let attached = item[0].dataset.attached
            if (attached == "true" && itemData.modId == "extra" || attached === "false" || !attached) {
                $.post('https://kaves_mechanic/buyComponent', JSON.stringify({
                    component: item.data("itemtable")
                }), function(buyed){
                    if (buyed) {
                        mainMenus = buyed;
                        $('.menu-item').attr('data-attached', 'false');
                        item.attr('data-attached', 'true');
                        let attachedMain = $('#attached').parent();
                        if (item.data("componentname") != "Neon") {
                            $('#attached').remove();
                        }
                        attachedMain.html(`<span>$${attachedMain.data('price')}</span>`);
                        let priceItem = item.children('.menu-item-price');
                        priceItem.html('<i id="attached" class="fa-solid fa-circle-check"></i>')
                    }else {
                        item.attr('data-flash', 'true');
                        setTimeout(() => {
                            item.attr('data-flash', 'false');
                        }, 1000);
                    }
                });
            }
        }
    }else if (key == "Backspace") {
        if (inColorMenu) {
            closePaintMenu()
        }else if (inFitmentMenu) {
            closeFitment()
        }else {
            let selected = $(`.menu-item[data-id="${activeIndex}"]`).data('type');

            if (selected === "altmenu") {
                $('.eye').fadeOut(250);
                let mainId = $(`.menu-item[data-id="${activeIndex}"]`).data('mainid');
                buildMenu("submenu", mainId, null);
                $('.menu-items').animate({ scrollLeft: 0 }, 200);
            }else if (selected === "submenu") {
                buildMenu("main", null, null);
            }else if (selected === "main") {
                $.post('https://kaves_mechanic/close', JSON.stringify({}));
            }else if (selected === undefined) {
                buildMenu("main", null, null);
            }
        }
    }

    if (key == "Backspace" || key == "Enter" || key == "ArrowLeft" || key == "ArrowRight") {
        let item = $(`.menu-item[data-id="${activeIndex}"]`).data('itemtable');
        $.post('https://kaves_mechanic/surfItem', JSON.stringify({
            clear: activeMenuName == "altmenu" ? false : true,
            mod: activeMenuName == "altmenu" ? item.mod : null,
            modId: activeMenuName == "altmenu" ? item.modId : null,
            wheelType: activeMenuName == "submenu" ? $(`.menu-item[data-id="${activeIndex}"]`).data('wheel') : null,
        }));
    }
};

$('body').mousemove(function() { 
    if (activeMenuName == "altmenu") {
        $.post('https://kaves_mechanic/disableCamera', JSON.stringify({}));
    }
});

colorPicker.on('color:change', function(color) {
    $.post('https://kaves_mechanic/changeColor', JSON.stringify({
        type: {
            first: selectedType == undefined ? "Primary" : selectedType,
            second: null,
        },
        picker: true,
        color: color.rgba
    }));
    rgba = true
    rgbColor = color.rgb
});

/////////////////////////////////////////////////////////////////////////////////////////
// MAIN BUILD UI FUNCTION'S //
/////////////////////////////////////////////////////////////////////////////////////////
const scrollSecondary = document.querySelector(".color-wheel[data-wheel='secondary']");

const formatNumber = (num) => {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, `.`);
}    

const buildMenu = (menu, objectId, component) => {
    $('.menu-items').html('');
    maxIndex = 0;
    activeIndex = 0;
    
    if (menu === "main") {
        Object.keys(mainMenus).forEach((menu) => {
            let menuContent = mainMenus[menu];
            let item = `
                <div class="menu-item" data-id="${menu}" data-active="${menu == 0 ? "true" : "false"}" data-type="${menuContent.type}" data-componentname="none">
                    <img src="img/${menuContent.img}.png">
                    <span>${menuContent.label}</span>
                </div>
            `;
            $('.menu-items').append(item);
            maxIndex++;
        });
        activeMenuName = "main";
    }else if (menu === "submenu") {
        let i = 0;
        let menuItems = [];
        Object.keys(mainMenus[objectId].items).forEach((subItem) => {
            let item = mainMenus[objectId].items[subItem];
            if (item.items == null || item.items == undefined) {
                return;
            };
            menuItems.push({
                label: subItem,
                item,
            });
        });
        
        menuItems.sort((a, b) => a.label.localeCompare(b.label));
        menuItems.forEach((menuItemObj, index) => {
            let menuItem = `
                <div class="menu-item" data-id="${index}" data-mainid="${objectId}" data-active="${index == 0 ? "true" : "false"}" data-type="${menuItemObj.item.type}" data-componentname="${menuItemObj.label}" data-wheel="${menuItemObj.item.wheelType != null || menuItemObj.item.wheelType != undefined ? menuItemObj.item.wheelType : "none"}">
                    <img src="img/${menuItemObj.item.img}.png">
                    <span>${menuItemObj.label}</span>
                </div>
            `;
            maxIndex++;
            $('.menu-items').append(menuItem);
        });
        activeMenuName = "submenu";
    }else if (menu === "altmenu") {
        let i = 0;
        $('#eye-label').html(component)
        $.each(mainMenus[objectId].items[component].eyepos, function (i, v) { 
            $('.eye').css({
                [i]: `${v}vh`
            })
        });
        Object.keys(mainMenus[objectId].items[component].items).forEach((altItem) => {
            let item = mainMenus[objectId].items[component].items[altItem];
            let itemTableString = JSON.stringify(item).replace(/"/g, "&quot;"); // Tırnak işaretlerini &quot; ile değiştirir
            let menuItem = `
                <div class="menu-item" data-id="${i}" data-mainid="${objectId}" data-active="${i == 0 ? "true" : "false"}" data-type="altmenu" data-componentname="${component}" data-itemtable="${itemTableString}" data-flash="false" data-attached=${item.attached != undefined || item.attached != null ? item.attached  : "false"}>
                    <div class="menu-item-price" data-price="${item.price}">
                        ${
                            item.attached != undefined || item.attached != null && item.attached ?  (
                                `<i id="attached" class="fa-solid fa-circle-check"></i>`
                            ) : (
                                `<span>$${item.price}</span>`
                            )
                        }
                    </div>
                    <img src="img/${mainMenus[objectId].items[component].img}.png">
                    <span>${item.label}</span>
                </div>
            `;
            maxIndex++;
            i++;
            $('.menu-items').append(menuItem);
        });
        setTimeout(() => {
            $('.eye').fadeIn(250);
        }, 1250);
        activeMenuName = "altmenu";
    }

    $.post('https://kaves_mechanic/rotateCamera', JSON.stringify({
        menu: activeMenuName,
        objectId: objectId,
        component: component
    }));
}

const buildColors = (type, selected, firstOpen) => {
    if (!firstOpen) {
        if (type == "secondary") {
            let price = selected == "Metallic" || selected == "Classic" || selected == "Matte" || selected == "Metal" ? prices.color : selected == "Pearlescent" ? prices.pearlescent : selected == "Chrome" ? prices.chrome  : prices.color;
            let arr = selected == "Classic" ? colors : selected == "Metallic" ? metallicColors : selected == "Matte" ? mattecolors : selected == "Metal" ? metalcolors : selected == "Pearlescent" ? pearlescentColors : selected == "Chrome" ? chromeColors : colors;
            $(`.color-wheel[data-wheel="${type}"]`).html('');
            $.each(arr, function (i, v) { 
                if (v.hex == undefined) return;
                let div = `
                    <div class="color" style="background: ${v.hex};" data-colorindex="${v.colorindex}"></div>
                `
                $(`.color-wheel[data-wheel="${type}"]`).append(div);
            });
            $('#buyButton').html(`Buy Color $${formatNumber(price)}`);
        }else if (type == "main") {
            let price = selected == "Chameleon" ? prices.chameleon : selected == "Neon Color" ? prices.neon : selected == "Smoke Color" ? prices.smoke : prices.color;
            if (selected == "Chameleon") {
                $('#chameleon').html(chameleoncolors[0].name);
            }
            $('#buyButton').html(`Buy Color $${formatNumber(price)}`);
        }
    }else {
        $('.color-wheel[data-wheel="secondary"]').html('');
        $.each(colors, function (i, v) { 
            if (v.hex == undefined) return;
            let div = `
                <div class="color" style="background: ${v.hex};" data-colorindex="${v.colorindex}"></div>
            `
            $(`.color-wheel[data-wheel="secondary"]`).append(div);
        });
        $('#buyButton').html(`Buy Color $${formatNumber(prices.color)}`);
    }
}

function openPaintMenu() {
    inColorMenu = true;
    $('.main-menu').fadeOut(250);
    setTimeout(() => {
        buildColors(null, null, true);
        $('.color-menu').fadeIn(250);
    }, 250);
}

function closePaintMenu() {
    $.post('https://kaves_mechanic/cursorState', JSON.stringify({
        cursor: false,
    }));
    $('.color-menu').fadeOut(250);
    setTimeout(() => {
        $('.main-menu').fadeIn(250);
        setTimeout(() => {
            inColorMenu = false;
            chameleonIndex = 0;
            firstIndex = 0;
            secondIndex = 0;
            selectedType = undefined
            rgba = false
            rgbColor = undefined
            $('div[data-id="openable"]').hide();
            $('div[data-id="closeable"').show()
            $(`#main`).html(firstSelectorItems[0]);
            $(`#secondary`).html(secondSelectorItems[0]);
            $(`#chameleon`).html(chameleoncolors[0].name);
        }, 250);
    }, 250);
}

function openFitment() {
    $('.main-menu').fadeOut(250);
    inFitmentMenu = true;
    $.each(wheels, function (i, v) { 
        let span = $(`.fitment-modal[data-fitment="${i}"]`).children('#fitment');
        span.html(v.toFixed(2));
    });
    $('.fitment-menu').fadeIn(250);
}

function closeFitment() {
    $.post('https://kaves_mechanic/cursorState', JSON.stringify({
        cursor: false,
    }));
    inFitmentMenu = false;
    $('.fitment-menu').fadeOut(250);
    $('.main-menu').fadeIn(250);
}

scrollSecondary.addEventListener("wheel", (evt) => {
    evt.preventDefault();
    scrollSecondary.scrollLeft += evt.deltaY;
});

$(document).on('click', '#arrow', function(){
    if (!cooldown) {
        cooldown = true;
        let type = $(this).data('type');
        let side = $(this).data('side');

        if (type != "fitment") {
            if (side == "left") {
                if (type == "main") {
                    firstIndex = firstIndex - 1;
                    if (firstIndex < 0) {
                        firstIndex = 0;
                    }
                }else if (type == "secondary") {
                    secondIndex = secondIndex - 1;
                    if (secondIndex < 0) {
                        secondIndex = 0;
                    }
                }else if (type == "chameleon") {
                    chameleonIndex = chameleonIndex - 1;
                    if (chameleonIndex < 0) {
                        chameleonIndex = 0;
                    }
                }
            }else if (side == "right") {
                if (type == "main") {
                    firstIndex = firstIndex + 1;
                    if (firstIndex > firstSelectorItems.length - 1) {
                        firstIndex = firstSelectorItems.length - 1;
                    }
                }else if (type == "secondary") {
                    secondIndex = secondIndex + 1;
                    if (secondIndex > secondSelectorItems.length - 1) {
                        secondIndex = secondSelectorItems.length - 1;
                    }
                }else if (type == "chameleon") {
                    chameleonIndex = chameleonIndex + 1;
                    if (chameleonIndex > chameleoncolors.length - 1) {
                        chameleonIndex = chameleoncolors.length - 1;
                    }
                }
            }
            
            if (firstSelectorItems[firstIndex] == "Chameleon") {
                $('div[data-id="closeable"]').fadeOut(250)
                setTimeout(() => {
                    $('div[data-id="openable"]').show()
                }, 250);
            }else if (firstSelectorItems[firstIndex] == "Neon Color" || firstSelectorItems[firstIndex] == "Smoke Color") {
                $('div[data-id="closeable"], div[data-id="openable"]').hide()
                $('#picker[data-id="closeable"').show()

            }else if (firstSelectorItems[firstIndex] == "Wheel Color") {
                $('div[data-id="closeable"]').show()
                $('#picker, #blabla').hide();
            }else {
                $('div[data-id="openable"]').hide();
                $('div[data-id="closeable"]').fadeIn(250)
            }

            if (type == "chameleon") {
                selectedType = "Chameleon";
                $(`#${type}`).html(chameleoncolors[chameleonIndex].name);
                $.post('https://kaves_mechanic/changeColor', JSON.stringify({
                    type: {
                        first: selectedType,
                        second: null
                    },
                    picker: false,
                    color: chameleoncolors[chameleonIndex].colorindex
                }));
            }else {
                if (type == "main") {
                    selectedType = firstSelectorItems[firstIndex];
                }else if (type == "secondary") {
                    selectedTypeSecond = secondSelectorItems[secondIndex];
                }
                
                $(`#${type}`).html(type == "main" ? firstSelectorItems[firstIndex] : secondSelectorItems[secondIndex]);
                buildColors(type, type == "main" ? firstSelectorItems[firstIndex] : secondSelectorItems[secondIndex], false);
            }
        }else {
            let fitment = $(this).parent();
            let fitmentName = fitment.data('fitment');

            if (side == "right") {
                wheels[fitmentName] = wheels[fitmentName] + 0.01;
                if (wheels[fitmentName] >= 1) {
                    wheels[fitmentName] = 1;
                }
            }else if (side == "left") {
                wheels[fitmentName] = wheels[fitmentName] - 0.01;
                if (wheels[fitmentName] <= -1.0) {
                    wheels[fitmentName] = -1.0;
                }
            }
            fitment.children('#fitment').html(wheels[fitmentName].toFixed(2));
            $.post('https://kaves_mechanic/changeFitment', JSON.stringify({
                type: fitmentName,
                value: wheels[fitmentName]
            }));
        }
        cooldown = false
    }
});

$(document).on('click', '.color', function(){
    if (rgba) {
        rgba = false;
    }
    let type = $(this).parent().data('wheel');
    let colorIndex = $(this).data('colorindex');
    selectedColor = colorIndex
    if (type == "main") {
        selectedType = firstSelectorItems[firstIndex];
        $.post('https://kaves_mechanic/changeColor', JSON.stringify({
            type: {
                first: selectedType,
                second: null
            },
            picker: false,
            color: colorIndex
        }));
    }else if (type == "secondary") {
        $.post('https://kaves_mechanic/changeColor', JSON.stringify({
            type: {
                first: firstSelectorItems[firstIndex],
                second: secondSelectorItems[secondIndex]
            },
            picker: false,
            color: colorIndex
        }));
    }

});

$(document).on('click', '#buyColor', function(){
    if (!cooldown) {
        cooldown = true;
        $.post('https://kaves_mechanic/buyColor', JSON.stringify({
            type: {
                first: firstSelectorItems[firstIndex],
                second: secondSelectorItems[secondIndex]
            },
            color: !rgba ? selectedColor : null,
            picker: rgba ? rgbColor : false
        }), function() {
            cooldown = false;
        });
    }
})

$(document).on('click', '#buyFitment', function(){
    if (!cooldown) {
        cooldown = true;
        $.post('https://kaves_mechanic/applyFitment', JSON.stringify({}), function() {
            cooldown = false;
        });
    }
})

function playSoundEffect(soundEffect)
{
    var audioPlayer = null;

    if(audioPlayer != null)
    {
        audioPlayer.pause();
    }

    audioPlayer = new Howl({src: ["./sounds/" + soundEffect + ".ogg"]});
    audioPlayer.volume(0.4);
    audioPlayer.play();
}

/////////////////////////////////////////////////////////////////////////////////////////
// LISTENER AND SECOND BUILD FUNCTION'S //
/////////////////////////////////////////////////////////////////////////////////////////

window.addEventListener('message', function (event) {
    let e = event.data;
    switch (e.type) {
        case "OPEN_MENU":
            mainMenus = e.modMenu;
            if (e.state) {
                $('body').fadeIn(250);
                buildMenu("main", null, null);
            }else {
                $('.menu-items').animate({ scrollLeft: 0 }, 0);
                $('body').fadeOut(250);
            }
            break;
        case "COLORS":
            colors = e.colors.defaultColors;
            metallicColors = e.colors.metallicColors;
            metalcolors = e.colors.metalColors;
            mattecolors = e.colors.matteColors;
            pearlescentColors = e.colors.pearlescentColors;
            chromeColors = e.colors.chromeColors;
            chameleoncolors = e.colors.chameleonColors;
            break;
        case "SET_PRICES":
            prices = e.price;
            break;
        case "SOUND":
            playSoundEffect(e.sound);
            break;
        default: break;
    }
});   

