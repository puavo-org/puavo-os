
var locale = require("./locale");
var gettext = require("./gettext");

// from locale.h (bits/locale.h)
categories = {
  LC_CTYPE: 0,
  LC_NUMERIC: 1,
  LC_TIME: 2,
  LC_COLLATE: 3,
  LC_MONETARY: 4,
  LC_MESSAGES: 5,
  LC_ALL: 6,
  LC_PAPER: 7,
  LC_NAME: 8,
  LC_ADDRESS: 9,
  LC_TELEPHONE: 10,
  LC_MEASUREMENT: 11,
  LC_IDENTIFICATION: 12
};

function setLocale(category, locale_){
  var catid = categories[category];
  if (catid === null || catid === undefined) {
    throw new Error("Unknown category " + category);
  }
  return locale.setlocale(catid, locale_);
}

gettext.setLocale = setLocale;
gettext.locale = locale;

module.exports = gettext;
