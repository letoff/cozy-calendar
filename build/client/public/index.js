var jade = require('pug-runtime'); module.exports = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
;var locals_for_with = (locals || {});(function (imports) {
buf.push("<!DOCTYPE html><html><head><meta charset=\"utf-8\"><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge, chrome=1\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>Cozy - Calendar</title><link rel=\"apple-touch-icon\" sizes=\"57x57\" href=\"/apps/calendar/apple-touch-icon-57x57.png\"><link rel=\"apple-touch-icon\" sizes=\"60x60\" href=\"/apps/calendar/apple-touch-icon-60x60.png\"><link rel=\"apple-touch-icon\" sizes=\"72x72\" href=\"/apps/calendar/apple-touch-icon-72x72.png\"><link rel=\"apple-touch-icon\" sizes=\"76x76\" href=\"/apps/calendar/apple-touch-icon-76x76.png\"><link rel=\"apple-touch-icon\" sizes=\"114x114\" href=\"/apps/calendar/apple-touch-icon-114x114.png\"><link rel=\"apple-touch-icon\" sizes=\"120x120\" href=\"/apps/calendar/apple-touch-icon-120x120.png\"><link rel=\"apple-touch-icon\" sizes=\"144x144\" href=\"/apps/calendar/apple-touch-icon-144x144.png\"><link rel=\"apple-touch-icon\" sizes=\"152x152\" href=\"/apps/calendar/apple-touch-icon-152x152.png\"><link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/apps/calendar/apple-touch-icon-180x180.png\"><link rel=\"icon\" type=\"image/png\" href=\"/apps/calendar/favicon-32x32.png\" sizes=\"32x32\"><link rel=\"icon\" type=\"image/png\" href=\"/apps/calendar/favicon-194x194.png\" sizes=\"194x194\"><link rel=\"icon\" type=\"image/png\" href=\"/apps/calendar/favicon-96x96.png\" sizes=\"96x96\"><link rel=\"icon\" type=\"image/png\" href=\"/apps/calendar/android-chrome-192x192.png\" sizes=\"192x192\"><link rel=\"icon\" type=\"image/png\" href=\"/apps/calendar/favicon-16x16.png\" sizes=\"16x16\"><link rel=\"manifest\" href=\"/apps/calendar/manifest.json\"><link rel=\"shortcut icon\" href=\"/apps/calendar/favicon.ico\"><meta name=\"msapplication-TileColor\" content=\"#ec8e73\"><meta name=\"msapplication-TileImage\" content=\"/apps/calendar/mstile-144x144.png\"><meta name=\"msapplication-config\" content=\"/apps/calendar/browserconfig.xml\"><meta name=\"theme-color\" content=\"#ec8e73\"><script src=\"javascripts/modernizr-2.6.1.js\"></script><link rel=\"stylesheet\" href=\"/fonts/fonts.css\"><link rel=\"stylesheet\" href=\"stylesheets/app-92bfc9dc.css\"><script src=\"socket.io/socket.io.js\"></script></head><body><div role=\"application\"><main class=\"main-container\"></main></div><script>" + (null == (jade_interp = imports) ? "" : jade_interp) + "</script><script src=\"javascripts/vendor-d0a31592.js\"></script><script src=\"javascripts/app-d7f251e7.js\" onload=\"require('initialize');\"></script></body></html>");}.call(this,"imports" in locals_for_with?locals_for_with.imports:typeof imports!=="undefined"?imports:undefined));;return buf.join("");
}