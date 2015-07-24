// Generated by CoffeeScript 1.9.0
var Event, User, async, cozydb, fs, jade, localization, log;

async = require('async');

jade = require('jade');

fs = require('fs');

log = require('printit')({
  prefix: 'MailHandler',
  date: true
});

Event = require('../models/event');

User = require('../models/user');

cozydb = require('cozydb');

localization = require('../libs/localization_manager');

module.exports.sendInvitations = function(event, dateChanged, callback) {
  var guests, needSaving;
  guests = event.toJSON().attendees;
  needSaving = false;
  return async.parallel([
    function(cb) {
      return cozydb.api.getCozyDomain(cb);
    }, function(cb) {
      return User.getUserInfos(cb);
    }
  ], function(err, results) {
    var domain, user;
    if (err) {
      return callback(err);
    }
    domain = results[0], user = results[1];
    return async.forEach(guests, function(guest, done) {
      var date, dateFormat, dateFormatKey, description, htmlTemplate, mailOptions, place, shouldSend, subject, subjectKey, templateKey, templateOptions, url, _ref;
      shouldSend = guest.status === 'INVITATION-NOT-SENT' || (guest.status === 'ACCEPTED' && dateChanged);
      if (!shouldSend) {
        return done();
      }
      if (dateChanged) {
        htmlTemplate = localization.getEmailTemplate('mail_update');
        subjectKey = 'email update title';
        templateKey = 'email update content';
      } else {
        htmlTemplate = localization.getEmailTemplate('mail_invitation');
        subjectKey = 'email invitation title';
        templateKey = 'email invitation content';
      }
      subject = localization.t(subjectKey, {
        description: event.description
      });
      url = domain + "public/calendar/events/" + event.id;
      date = event.formatStart(dateFormat);
      dateFormat = localization.t(dateFormatKey);
      dateFormatKey = event.isAllDayEvent() ? 'email date format allday' : 'email date format';
      _ref = event.toJSON(), description = _ref.description, place = _ref.place;
      place = (place != null ? place.length : void 0) > 0 ? place : false;
      templateOptions = {
        displayName: user.name,
        displayEmail: user.email,
        description: description,
        place: place,
        key: guest.key,
        date: date,
        url: url
      };
      mailOptions = {
        to: guest.email,
        subject: subject,
        html: htmlTemplate(templateOptions),
        content: localization.t(templateKey, templateOptions)
      };
      return cozydb.api.sendMailFromUser(mailOptions, function(err) {
        if (err) {
          log.error("An error occured while sending invitation");
          log.error(err);
        } else {
          needSaving = true;
          guest.status = 'NEEDS-ACTION';
        }
        return done(err);
      });
    }, function(err) {
      if (err != null) {
        return callback(err);
      } else if (!needSaving) {
        return callback();
      } else {
        return event.updateAttributes({
          attendees: guests
        }, callback);
      }
    });
  });
};

module.exports.sendDeleteNotification = function(event, callback) {
  var guests, guestsToInform;
  guests = event.toJSON().attendees;
  guestsToInform = guests.filter(function(guest) {
    var _ref;
    return (_ref = guest.status) === 'ACCEPTED' || _ref === 'NEEDS-ACTION';
  });
  return User.getUserInfos(function(err, user) {
    if (err) {
      return callback(err);
    }
    return async.eachSeries(guestsToInform, function(guest, done) {
      var date, dateFormat, dateFormatKey, description, htmlTemplate, mailOptions, place, subjectKey, templateOptions, _ref;
      if (event.isAllDayEvent()) {
        dateFormatKey = 'email date format allday';
      } else {
        dateFormatKey = 'email date format';
      }
      dateFormat = localization.t(dateFormatKey);
      date = event.formatStart(dateFormat);
      _ref = event.toJSON(), description = _ref.description, place = _ref.place;
      place = (place != null ? place.length : void 0) > 0 ? place : false;
      templateOptions = {
        displayName: user.name,
        displayEmail: user.email,
        description: description,
        place: place,
        date: date
      };
      htmlTemplate = localization.getEmailTemplate('mail_delete');
      subjectKey = 'email delete title';
      mailOptions = {
        to: guest.email,
        subject: localization.t(subjectKey, {
          description: event.description
        }),
        content: localization.t('email delete content', templateOptions),
        html: htmlTemplate(templateOptions)
      };
      return cozydb.api.sendMailFromUser(mailOptions, function(err) {
        if (err != null) {
          log.error("An error occured while sending email");
          log.error(err);
        }
        return done(err);
      });
    }, callback);
  });
};
