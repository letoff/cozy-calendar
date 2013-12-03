ViewCollection      = require '../lib/view_collection'
helpers = require '../helpers'
defaultTimezone = 'timezone'


module.exports = class ListView extends ViewCollection

    id: 'viewContainer'
    template: require './templates/list_view'
    itemview: require './list_view_bucket'
    collectionEl: '#alarm-list'
    events:
        'click .showbefore': 'showbefore'

    appendView: (view) ->
        index = @collection.indexOf view.model
        el = view.$el
        if view.model.get('date').isBefore Date.now()
            el.addClass('before').hide()
        else
            el.addClass('after')

        if index is 0 then @$collectionEl.prepend el
        else
            prevCid = @collection.at(index-1).cid
            @views[prevCid].$el.after el


    showbefore: =>
        first = @$('.after').first()
        body = $('html, body')
        @$('.before').slideDown
            progress: -> body.scrollTop first.offset().top

        @$('.showbefore').fadeOut()
