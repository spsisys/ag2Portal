/* Functions to adjust size and position of the detected
browser to the needs of the application,
and any other functions about browser management.
*/

// Default app's browser size:
function Resize(pwidth, pheight) {
  var width = pwidth;
  var height = pheight;
  if (pwidth > screen.width)
    width = screen.width;
  if (pheight > screen.height)
    height = screen.height;
  Move(pwidth, pheight);
  window.resizeTo(width, height);
}

// Default app's browser position:
function Move(pwidth, pheight) {
  var x = (screen.width - pwidth) / 2;
  var y = (screen.height - pheight) / 2;
  window.moveTo(x, y);
}

function ScreenSize(_show) {
  var screenW = screen.width;
  var screenH = screen.height;
  var message = I18n["screen_size"] + ':\t' + screenW + 'x' + screenH;
  if (_show != 0)
    window.alert(message);
  else
    return message;
}

function WindowSize(_show) {
  var screenW = $(window).width();
  var screenH = $(window).height();
  var message = I18n["window_size"] + ':\t' + screenW + 'x' + screenH;
  if (_show != 0)
    window.alert(message);
  else
    return message;
}

function DisplaySizeInfo() {
  var screenM = ScreenSize(0);
  var windowM = WindowSize(0);
  window.alert(screenM + '\n' + windowM);
}

function CloseUponResolution(screenW, screenH) {
  if ((screen.width <= screenW) || (screen.height <= screenH)) {
    window.close();
  }
}

// Detecting mobile browsers (be careful: it need's to be up-to-date!)
var isMobile = {
  Android : function() {
    return navigator.userAgent.match(/Android/i);
  },
  AndroidPhoneChrome : function() {
    return navigator.userAgent.match('Android' + 'Chrome/[.0-9]* Mobile');
  },
  AndroidTabletChrome : function() {
    return navigator.userAgent.match('Android' + 'Chrome/[.0-9]* (?!Mobile)');
  },
  BlackBerry : function() {
    return navigator.userAgent.match(/BlackBerry/i);
  },
  iOS : function() {
    return navigator.userAgent.match(/iPhone|iPad|iPod/i);
  },
  iOSChrome : function() {
    return navigator.userAgent.match(/CriOS/i);
  },
  Opera : function() {
    return navigator.userAgent.match(/Opera Mini/i);
  },
  Windows : function() {
    return navigator.userAgent.match(/IEMobile/i);
  },
  any : function() {
    return (isMobile.Android() || isMobile.BlackBerry() || isMobile.iOS() || isMobile.Opera() || isMobile.Windows() || isMobile.iOSChrome() || isMobile.AndroidPhoneChrome() || isMobile.AndroidTabletChrome());
  }
};

// Wake up functions:
function ScreenResolution(screenW, screenH) {
  var toPage = "LD";
  if ((screen.width < 1024) || (screen.height < 768)) {
    return toPage;
  }
  if ((screen.width >= screenW) && (screen.height >= screenH)) {
    toPage = "HD";
  } else {
    toPage = "SD";
  }
  return toPage;
}

function RedirectUponScreenResolution(screenW, screenH) {
  var toPage = "icon";
  if (isMobile.any()) {
    if ((screen.height < 1024) || (screen.width < 768)) {
      toPage = "icon";
    } else {
      if ((screen.height >= screenW) && (screen.width >= screenH)) {
        toPage = "default";
      } else {
        toPage = "lowres";
      }
    }
  } else {
    if ((screen.width < 1024) || (screen.height < 768)) {
      toPage = "icon";
    } else {
      if ((screen.width >= screenW) && (screen.height >= screenH)) {
        toPage = "default";
      } else {
        toPage = "lowres";
      }
    }
  }
  return toPage;
}

function RedirectUponWindowResolution(screenW, screenH) {
  var toPage = "icon";
  if (($(window).width() < 1024) || ($(window).height() < 768)) {
    return toPage;
  }
  if (($(window).width() >= screenW) && ($(window).height() >= screenH)) {
    toPage = "default";
  } else {
    toPage = "lowres";
  }
  return toPage;
}

// Alert base on browser's inner size:
function AlertInnerSize(pwidth) {
  var myWidth = 0, myHeight = 0;
  var alerted = false;
  if ( typeof (window.innerWidth) == 'number') {
    // Non-IE
    myWidth = window.innerWidth;
    myHeight = window.innerHeight;
  } else if (document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) {
    // IE 6+ in 'standards compliant mode'
    myWidth = document.documentElement.clientWidth;
    myHeight = document.documentElement.clientHeight;
  } else if (document.body && (document.body.clientWidth || document.body.clientHeight)) {
    // IE 4 compatible
    myWidth = document.body.clientWidth;
    myHeight = document.body.clientHeight;
  }
  if (myWidth < pwidth) {
    window.alert('Workspace: ' + myWidth + 'x' + myHeight);
    alerted = true;
  }
  return alerted;
}

// Browser Name:
function BrowserName() {
  var bName = navigator.appName;
  if (bName == "Netscape")
    bName += " (or compatible)";
  return bName;
}

// Based Alert on browser:
function AlertBrowser() {
  var alertMsg = "";
  var bName = navigator.appName;
  if (bName != "Microsoft Internet Explorer")
    alertMsg = "Microsoft Internet Explorer recommended";
  return alertMsg;
}