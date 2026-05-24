/*
Premium QB-Phone by FiveM QBCore
For premium server buy visit here:
🌍 Website: https://fivem-qbcore.com
💬 Discord: https://discord.gg/qbcoreframework
*/

$(document).ready(function() {
  $("#appstore-search").on("input", function() {
      var searchTerm = $(this).val().toLowerCase();
      $(".app-item").each(function() {
          var appName = $(this).find("span").text().toLowerCase();
          if (appName.includes(searchTerm)) {
              $(this).show();
          } else {
              $(this).hide();
          }
      });
  });
});

window.addEventListener('message', (event) => {
	let data = event.data
	if(data.appname != null) {
		setTimeout(function() {
      // Display specific app content based on the name
      $("#in-" + data.appname).css({"display":"none"});
      $("#un-" + data.appname).css({"display":"block"});
      $("#app-" + data.appname.replace(/\s/g, '') + "-inside").css({"display":"block"});
      AppLoadDatabase(data.appname,data.appnumber)
    }, 3000)
	}
})

var icurrentName = null;
var ibtnValue = null;
var ucurrentName = null;
var ubtnValue = null;

function installApp(name,buttonValue) {
  $(".app-install-title").html(name);
  $(".app-install-process").css({"display":"block"});
  icurrentName = name;
  ibtnValue = buttonValue;
}

$(document).on("click", "#app-install-btn", function() {

  $(".app-install-process").css({"display":"none"});
  $(".loading-animation").css({"display":"block"});

  // loading animation work start
  $(".loader").show();
  setTimeout(function() {
    $(".loader").hide();  
    $(".loading-animation").css({"display":"none"}); 
  }, 3000); 

  setTimeout(function() {
    $("#content").css({"display":"block"}); 
  }, 2000); 
  $("#content").css({"display":"none"}); 
  // loading animation work end
  
  setTimeout(function() {
    // Display specific app content based on the name
    $("#in-" + icurrentName).css({"display":"none"});
    $("#un-" + icurrentName).css({"display":"block"});
    $("#app-" + icurrentName.replace(/\s/g, '') + "-inside").css({"display":"block"});
    AppSaveDatabase(icurrentName,ibtnValue)
  }, 3000)
});

function findValue(buttonValue) {
  switch(buttonValue) {
    case 1:
      installApp("Whatsapp", buttonValue);
      break;
    case 2:
      installApp("Twitter", buttonValue);
      break;
    case 3:
      installApp("Uber", buttonValue);
      break;
    case 4:
      installApp("Calculator", buttonValue);
      break;
    case 5:
      installApp("Youtube", buttonValue);
      break;
    case 6:
      installApp("Discord", buttonValue);
      break;
    case 7:
      
      installApp("Houses", buttonValue);
      break;
    case 8:
      
      installApp("Garage", buttonValue);
      break;
    case 9:
      installApp("Details", buttonValue);
      break;
    case 10: 
      installApp("Advertisements", buttonValue);
      break;
    case 11: 
      installApp("Debt", buttonValue);
      break;
    case 12:
      installApp("Wenmo", buttonValue);
      break;
    case 13:
      installApp("Documents", buttonValue);
      break;
    case 14:
      installApp("Crypto", buttonValue);
      break;
    case 15:
      installApp("JobCenter",buttonValue);
      break;
    case 16:
      installApp("Employment", buttonValue);
      break;
    case 17:
      installApp("LSBN", buttonValue);
      break;
    case 18:
      installApp("Betting", buttonValue);
      break;
    case 19:
      installApp("Racing", buttonValue);
      break;
    case 20:
      installApp("Invoices", buttonValue);
      break;
    // Add cases for other button values similarly
    // ...
    default:
      // Handle default case
      break;
  }
}

// uninstall app
function uninstallApp(name,buttonValue) {
  $(".app-uninstall-title").html(name);
  $(".app-uninstall-process").css({"display":"block"});
  ucurrentName = name;
  ubtnValue = buttonValue;
}

$(document).on("click", "#uninstall-btn", function() {
  $(".app-uninstall-process").css({"display":"none"});
  $(".uninstall-loading-animation").css({"display":"block"});
  // loading animation work start
  $(".uninstall-loader").show();
  setTimeout(function() {
      $(".uninstall-loader").hide();  
      $(".uninstall-loading-animation").css({"display":"none"}); 
  }, 3000); 

  setTimeout(function() {
    $("#uninstall-content").css({"display":"block"}); 
  }, 2000); 
  $("#uninstall-content").css({"display":"none"}); 
  // loading animation work end
  
  setTimeout(function() {
    // Display specific app content based on the name
    $("#in-" + ucurrentName).css({"display":"block"});
    $("#un-" + ucurrentName).css({"display":"none"});
    $("#app-" + ucurrentName.replace(/\s/g, '') + "-inside").css({"display":"none"});
    AppRemoveDatabase(ucurrentName,ubtnValue)
  }, 3000)
});

function findValueUninstall(buttonValue) {
  switch(buttonValue) {
    case 1:
      uninstallApp("Whatsapp",buttonValue);
      break;
    case 2:
      uninstallApp("Twitter",buttonValue);
      break;
    case 3:
      uninstallApp("Uber",buttonValue);
      break;
    case 4:
      uninstallApp("Calculator",buttonValue);
      break;
    case 5:
      uninstallApp("Youtube",buttonValue);
      break;
    case 6:
      uninstallApp("Discord",buttonValue);
      break;
    case 7:
      uninstallApp("Houses",buttonValue);
      break;
    case 8:
      uninstallApp("Garage",buttonValue);
      break;
    case 9:
      uninstallApp("Details",buttonValue);
      break;
    case 10:
      uninstallApp("Advertisements"),buttonValue;
      break;
    case 11:
      uninstallApp("Debt",buttonValue);
      break;
    case 12:
      uninstallApp("Wenmo",buttonValue);
      break;
    case 13:
      uninstallApp("Documents",buttonValue);
      break;
    case 14:
      uninstallApp("Crypto",buttonValue);
      break;
    case 15:
      uninstallApp("JobCenter",buttonValue);
      break;
    case 16:
      uninstallApp("Employment",buttonValue);
      break;
    case 17:
      uninstallApp("LSBN",buttonValue);
      break;
    case 18:
      uninstallApp("Betting",buttonValue);
      break;
    case 19:
      uninstallApp("Racing",buttonValue);
      break;
    case 20:
      uninstallApp("Invoices",buttonValue);
      break;
    // Add cases for other button values similarly
    // ...
    default:
      // Handle default case
      break;
  }
}
 
// install cancel btn work start
$(document).on("click", ".cancel-btn", function() {
$(".app-install-process").css({"display":"none"});
})

// uninstall cancel btn work start
$(document).on("click", ".uninstall-cancel-btn", function() {
$(".app-uninstall-process").css({"display":"none"});
})
// app install-uninstall process work end 


// database test for app-store work start 
// save btn
function AppSaveDatabase(name,buttonValue) {
  var AppName = name;
  var AppNumber = buttonValue;

  $.post('https://qb-phone/AddNewInstallApp', JSON.stringify({
      CurrentAppName: AppName,
      CurrentAppNumber: AppNumber,
  }), function(AppStor){
      // QB.Phone.Functions.LoadAppStor(AppStor);
      displaySavedAppData(AppStor);
  });
}

function AppLoadDatabase(name,buttonValue) {
  var AppName = name;
  var AppNumber = buttonValue;

  $.post('https://qb-phone/AddOldApp', JSON.stringify({
      CurrentAppName: AppName,
      CurrentAppNumber: AppNumber,
  }), function(AppStor){
      // QB.Phone.Functions.LoadAppStor(AppStor);
      displaySavedAppData(AppStor);
  });
}

function AppRemoveDatabase(name,buttonValue) {
  var AppName = name;
  var AppNumber = buttonValue;
  $.post('https://qb-phone/RemoveUnisatallApp', JSON.stringify({
      CurrentAppName: AppName,
      CurrentAppNumber: AppNumber,
  }), function(AppStor){
      // Handle the received data, if needed
      // QB.Phone.Functions.LoadAppStor(AppStor);
      displaySavedAppData(AppStor);
  });
};
// database test for app-store work end

// Function to display saved app data in HTML
function displaySavedAppData(data) {
  var savedAppDataElement = $('#savedAppData');
  savedAppDataElement.empty(); // Clear existing content

  if (data && data.length > 0) {
    var htmlContent = '<ul>';
    data.forEach(function(app) {
      htmlContent += '<li>App Name: ' + app.CurrentAppName + ', App Number: ' + app.CurrentAppNumber + '</li>';
    });
    htmlContent += '</ul>';

    savedAppDataElement.html(htmlContent);
  } else {
    savedAppDataElement.html('<p>No saved app data available.</p>');
  }
}




