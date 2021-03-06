PopoverScreenView = require 'lib/popover_screen_view'
ComboBox    = require 'views/widgets/combobox'
Settings = require 'models/settings'
Modal = require 'lib/modal'
Event       = require 'models/event'

tFormat                 = 'HH:mm'
dFormat                 = 'DD/MM/YYYY'
inputDateDTPickerFormat = 'dd/mm/yyyy'
allDayDateFieldFormat   = 'YYYY-MM-DD'

defTimePickerOpts       =
    template: false
    minuteStep: 5
    showMeridian: false

defDatePickerOps        =
    language: window.app.locale
    fontAwesome: true
    autoclose: true
    pickerPosition: 'bottom-right'
    keyboardNavigation: false
    format: inputDateDTPickerFormat
    minView: 2
    viewSelect: 4

module.exports = class MainPopoverScreen extends PopoverScreenView

    # Override generic template title.
    templateTitle: require 'views/templates/popover_screens/main_title'
    templateContent: require 'views/templates/popover_screens/main'
    attributes:
        tabindex: "0"


    events:
        'keyup':                'onKeyUp'
        'keyup button':         'stopKeyUpPropagation'
        'keyup [role=button]':  'stopKeyUpPropagation'
        'change select':        'onKeyUp'
        'change input':         'onKeyUp'
        'click .cancel':        'onCancelClicked'
        'click .add':           'onAddClicked'
        'click .advanced-link': 'onAdvancedClicked'
        'click .remove':        -> @switchToScreen('delete')
        'click .duplicate':     'onDuplicateClicked'

        'changeTime.timepicker .input-start':    'onSetStart'
        'changeTime.timepicker .input-end-time': 'onSetEnd'
        'changeDate .input-start-date':          'onSetStart'
        'changeDate .input-end-date':            'onSetEnd'
        'click .input-allday':                   'toggleAllDay'

        'input .input-desc':                     'onSetDesc'
        'input .input-place':                    'onSetPlace'

        'keydown [data-tabindex-next]':          'onTab'
        'keydown [data-tabindex-prev]':          'onTab'

        # Screen switches.
        'click .input-people': -> @switchToScreen('guests')
        'click .input-details': -> @switchToScreen('details')
        'click .input-alert': -> @switchToScreen('alert')
        'click .input-repeat': ->
            @switchToScreen('repeat') if not @context.readOnly

    initialize: ->
        @formModel = @context.formModel

        # Listen to the model's change to update the view accordingly.
        # `start` and `end` are updated when one changed to prevent overlapping
        # times.
        @listenTo @formModel, "change:start", @onStartChange
        @listenTo @formModel, "change:end", @onEndChange

        @calendar = @formModel.getCalendar()

        # Shared event's getCalendar method does not return a calendar
        if @calendar
            @listenTo @calendar, 'change:color', @onCalendarColorChange

        @listenTo app.calendars, 'change', @onCalendarsChange


    # Remove the listeners when the screen is left.
    onLeaveScreen: ->
        @stopListening @formModel


    getRenderData: ->
        defaultCalendar = app.getDefaultCalendar()
        if @model.isNew()
            currentCalendar = defaultCalendar
            @formModel.setCalendar currentCalendar
        else
            currentCalendar = @formModel.get('tags')?[0] or \
                defaultCalendar.get('name')

        endOffset = if @formModel.isAllDay() then -1 else 0
        return data = _.extend super(),
            readOnly:    @context.readOnly
            tFormat:     tFormat
            dFormat:     dFormat
            calendar:    currentCalendar
            place:       @formModel.get 'place'
            description: @formModel.get 'description'
            allDay:      @formModel.isAllDay()
            sameDay:     @formModel.isSameDay()
            start:       @formModel.getStartDateObject()
            end:         @formModel.getEndDateObject().add(endOffset, 'd')
            alerts: @formModel.get('alarms')
            guestsButtonText: @getGuestsButtonText()
            detailsButtonText: @getDetailsButtonText()
            buttonText: @getButtonText()
            recurrenceButtonText: @getRecurrenceButtonText()


    afterRender: ->
        # Required for keyup event
        @$el.attr 'tabindex', 0

        # Cache jQuery selectors.
        @description = @$ '.input-desc'
        @$container   = @$ '.popover-content-wrapper'
        @$addButton    = @$ '.btn.add'
        @removeButton = @$ '.remove'
        @spinner = @$ '.remove-spinner'
        @duplicateButton = @$ '.duplicate'
        @$optionalFields = @$ '[data-optional="true"]'
        @$moreDetailsButton = @$ '.advanced-link'
        @$detailsButton = @$ '.input-details button'

        # If this is a new unsaved event, hide the irrelevant buttons.
        if @model.isNew()
            @removeButton.hide()
            @duplicateButton.hide()

        timepickerEvents =
            'focus': ->
                $(@).timepicker('highlightHour')
            'timepicker.next': ->
                $("[tabindex=#{+$(@).attr('tabindex') + 1}]").focus()
            'timepicker.prev': ->
                $("[tabindex=#{+$(@).attr('tabindex') - 1}]").focus()


        @$('input[type="time"]:not([aria-readonly])').attr('type', 'text')
                                .timepicker defTimePickerOpts
                                .delegate timepickerEvents

        # Chrome is really bad with HTML5 form so it always get an error of
        # validation. As a result we don't use a type=date, but a type=text.
        @$('.input-date:not([aria-readonly])').datetimepicker defDatePickerOps


        @calendarComboBox = new ComboBox
            el: @$ '.calendarcombo'
            small: true
            source: app.calendars.toAutoCompleteSource()
            current: @formModel.getCalendar()?.get('name')
            readOnly: @context.readOnly

        @context.clickOutListener.exceptOn @calendarComboBox.widget().get 0

        if not @context.readOnly
            @calendarComboBox.on 'edition-complete', (value) =>
                @formModel.setCalendar app.calendars.getOrCreateByName value
                @description.focus()

        # Apply the expanded status if it has been previously set.
        if @context.popoverExtended
            @expandPopover()

        # If all the optional fields are shown by default (they all have a
        # value), then hide the "more details" button.
        if @$("[aria-hidden=true]").length is 0
            @$moreDetailsButton.hide()

        # Focus the short description field by default. It's done in a timeout
        # because otherwise it loses focus for some reason.
        setTimeout =>
            @$('[tabindex="1"]').focus()
        , 1


    onKeyUp: (event) ->
        if event.keyCode is 13 or event.which is 13 #ENTER
            # Forces the combobox to blur to save the calendar if it has changed
            @calendarComboBox.onBlur()
            # Update start and end too.
            @onSetStart()
            @onSetEnd()

            @$addButton.click()
        else
            @$addButton.removeClass 'disabled'


    stopKeyUpPropagation: (event) ->
        event.stopPropagation()


    toggleAllDay: ->
        # NOTE: I'm not especially fan to set models logics in the view.
        #
        # Maybe we should handle those kind of changes inside the model
        # directly. Need to revamp the model event view also.
        start = @formModel.getStartDateObject()
        end = @formModel.getEndDateObject()
        if @$('.input-allday').is ':checked'
            @formModel.set 'start', start.format(allDayDateFieldFormat)
            @formModel.set 'end', end.add(1, 'd').format(allDayDateFieldFormat)
        else
            @formModel.set 'start', start.hour(12).toISOString()
            @formModel.set 'end', start.hour(13).toISOString()

        # Set labels, captions and views states
        @$('.input-time').attr 'aria-hidden', @formModel.isAllDay()
        @$container.toggleClass 'is-all-day', @formModel.isAllDay()


    onSetDesc: (ev) ->
        @formModel.set 'description', ev.target.value


    onSetPlace: (ev) ->
        @formModel.set 'place', ev.target.value


    onSetStart: ->
        @formModel.setStart @formatDateTime @$('.input-start').val(),
                                        @$('.input-start-date').val(),
                                        false


    onSetEnd: ->
        @formModel.setEnd @formatDateTime @$('.input-end-time').val(),
                                      @$('.input-end-date').val()

        # We put or remove a top-level class on the popover body that target if
        # the event is one day long or not
        @$container.toggleClass 'is-same-day', @formModel.isSameDay()


    onCalendarColorChange: (calendar) ->
        @calendarComboBox.buildBadge calendar.get 'color'


    onCalendarsChange: (calendars) ->
        @calendarComboBox.resetComboBox app.calendars.toAutoCompleteSource()


    formatDateTime: (timeStr = '', dateStr = '', end=true) ->
        t = timeStr.match /([0-9]{1,2}):([0-9]{2})\+?([0-9]*)/
        d = splitted = dateStr.match /([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})/

        [hour, minute] = t[1..2] if t?[0]
        [date, month, year] = d[1..3] if d?[0]

        # Add a day later if event is all-day long and if it's and end date.
        if end
            date = +date + 1 if date and @formModel.isAllDay()

        month = +month - 1 if month # Months are 0 indexed in moment.js

        # The order here is *VERY* important. When updating a moment date
        # by iterating over the properties of this object, we must set month
        # before day. For all day event ending the last day of the month, date
        # is superior to the number of days of the month, and setting the
        # monthe before the day will produce a wrong date.
        # See #409
        setObj = { year, month, date, hour, minute}


    # Loop over controls elements w/o exiting the popover scope
    onTab: (ev) =>
        # Early return if the key pressed isn't `tab` (keyCode == 9)
        return unless ev.keyCode is 9
        # Find if the element has an explicit next/prev control, and if it fits
        # w/ loop direction (forward/backward over controls)
        $this = $(ev.target)
        if not ev.shiftKey and $this.is '[data-tabindex-next]'
            index = $this.data 'tabindex-next'
        if ev.shiftKey and $this.is '[data-tabindex-prev]'
            index = $this.data 'tabindex-prev'
        # Early return if no index is found
        return unless index
        # Set focus to the targetted element and prevent focusing to fix the
        # overlooping effect (directly jump to the next/prev element rather than
        # the declared one)
        @$("[tabindex=#{index}]").focus()
        ev.preventDefault()

    # Revert formModel to model state, so the close method will not
    # detect any change.
    cancelChanges: ->
        @context.formModel = @model.clone()


    # Hides popover.
    onCancelClicked: ->
        @cancelChanges()
        @popover.close()


    # When duplicate button is clicked, an new event with exact same date
    # is created.
    onDuplicateClicked: ->
        attrs = []
        attrs[key] = value for key, value of @formModel.attributes
        delete attrs.id
        delete attrs._id

        calendarEvent = new Event attrs
        @duplicateButton.hide()
        @spinner.show()

        formModelDiffers = not _.isEqual @context.formModel.attributes,
                                    @model.attributes

        # update popover with the duplicated event
        _updatePopover = (screen) =>
            contextDesc = @context.formModel.attributes.description
            isNotNewDesc = contextDesc is @model.attributes.description
            if isNotNewDesc
                calendarEvent.attributes.description += ' copy'
            @popover.model = calendarEvent.clone()
            @context.formModel = calendarEvent.clone()
            @formModel = @context.formModel
            @switchToScreen screen

        # if changes -> screen to confirm discard/save changes on previous
        if formModelDiffers
            screen = @context.screen
            duplicateHandler = =>
                _updatePopover screen
                return
            cancelHandler = =>
                @switchToScreen screen
                @duplicateButton.hide()
                @spinner.show()
                return
            @switchToScreen 'duplicate',
                duplicateCallback: duplicateHandler
                cancelCallback: cancelHandler
        else
            _updatePopover @context.screen


    onAddClicked: ->
        return if @$('.btn.add').hasClass 'disabled'
        spinner = '<img src="img/spinner-white.svg" alt="spinner" />'
        @$addButton.empty()
        @$addButton.append spinner

        errors = @model.validate @formModel.attributes
        if errors
            @$addButton.html @getButtonText()

            @$('.alert').remove()
            @$('input').css 'border-color', ''
            @handleError err for err in errors

        else # no errors.
            calendar = @formModel.getCalendar()
            @model.setCalendar calendar

            saveEvent = (sendInvitations) =>
                @model.save @formModel.attributes,
                    wait: true
                    url: "#{@model.url()}?sendMails=#{sendInvitations}"
                    success: (model, response) =>
                        app.events.add model, sort: false
                    error: ->
                        # TODO better error handling
                        alert 'server error occured'
                    complete: =>
                        @$addButton.html @getButtonText()
                        @popover.close()

            @confirmEmailInvitations @formModel, (err, sendInvitations) =>
                if err
                    # TODO better error handling
                    alert err
                    return

                @syncCalendar calendar, (err, calendar) ->
                    # TODO better error handling
                    if err
                        alert err
                        return

                    saveEvent(sendInvitations)

    # Display confirmation modal for sending emails invitation to attendees
    confirmEmailInvitations: (model, callback) ->
        invitationsShouldBeSent = model.isNew() or
                                    model.startDateChanged or
                                        model.attendeesChanged
        if not invitationsShouldBeSent
            callback null, false
            return

        # else: look state of each guest.
        attendees = model.get('attendees') or []
        guestsToInform = attendees.filter (guest) =>
            return not guest.isSharedWithCozy and
                (model.isNew() or
                    guest.status is not 'ACCEPTED' or
                        model.startDateChanged)

        if guestsToInform.length
            guestsList = guestsToInform.map((guest) -> guest.label).join ', '
            modal = Modal.confirm t('modal send mails'),
                "#{t 'send invitations question'} #{guestsList}", \
                t('yes'),
                t('no'),
                (result) -> callback null, result

            @context.clickOutListener.exceptOn [
                    modal.el,
                    modal.getBackdrop() ]

        else
            callback null, false

    # Ensure that the given calendar is saved (method called just before
    # saving an event)
    syncCalendar: (calendar, callback) ->
        if calendar.isNew()
            calendar.save calendar.attributes,
                wait: true
                success: ->
                    app.calendars.add calendar
                    callback null, calendar
                error: ->
                    callback 'server error occured', null
        else
            callback null, calendar


    handleError: (error) ->
        switch error.field
            when 'description'
                guiltyFields = '.input-desc'

            when 'startdate'
                guiltyFields = '.input-start'

            when 'enddate'
                guiltyFields = '.input-end-time, .input-end-date'

            when 'date'
                guiltyFields = '.input-start, .input-end-time, .input-end-date'

        @$(guiltyFields).css('border-color', 'red')
        @$(guiltyFields).focus()
        alertMsg = $('<div class="alert"></div>').text(t(error.value))
        @$('.popover-content').before alertMsg


    getButtonText: ->
        if @model.isNew() then t('create button') else t('save button')


    getGuestsButtonText: ->
        guests = @formModel.get('attendees') or []

        if guests.length is 0
            return t("add guest button")
        else if guests.length is 1
            return guests[0].label
        else
            numOthers = guests.length - 1
            options =
                first: guests[0].label,
                smart_count: numOthers
            return t("guests list", options)

    getDetailsButtonText: ->
        return @formModel.get('details') or t("placeholder description")


    getRecurrenceButtonText: ->
        rrule = @formModel.get('rrule')

        # If there is a valid rrule.
        if rrule?.length > 0
            try
                rrule = RRule.fromString @formModel.get('rrule')
            catch e
                console.error e
                return t('invalid recurring rule')
            # Handle localization.
            locale = moment.localeData()
            language =
                dayNames: locale._weekdays

                monthNames: locale._months

            return rrule.toText(window.t, language)
        else
            return t('no repeat button')


    # Show more fields when triggered.
    onAdvancedClicked: (event) ->
        event.preventDefault()

        # Show all the fields, and hide the button.
        @expandPopover()

        # Mark the popover has extended so the information is not lost when
        # screen is left.
        @context.popoverExtended = not @context.popoverExtended?


    # Show the optional fields of the screen (the ones hidden by default).
    expandPopover: ->
        @$optionalFields.attr 'aria-hidden', false
        @$moreDetailsButton.hide()
        # focus for keyboard navigation
        @$detailsButton.focus()


    # Handle model's change for field `start`
    onStartChange: ->
        newValue = @formModel.getStartDateObject().format tFormat
        @$('.input-start').timepicker('setTime', newValue)


    # Handle model's change for field `end`
    onEndChange: ->
        endOffset = if @formModel.isAllDay() then -1 else 0
        newValue = @formModel.getEndDateObject()
            .add endOffset, 'd'
            .format tFormat
        @$('.input-end-time').timepicker('setTime', newValue)
