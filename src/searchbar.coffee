
{fetch} = require('whatwg-fetch');
# import './jquery'

util = require 'util'
tools = require './tools'
fp = require './fp'
_ = require 'underscore'
giphy = require './giphy'
content = require './content'
{Alert} = content

mostRecentSearch = ()=>
    try
        return JSON.parse(localStorage.getItem('lastSearch'))

exports.SearchBar = class searchBar
    @instance = null

    constructor: (@main, elem) ->
        searchBar.instance = this
        @elem = elem
        @simpleTermInput = @elem.find('#term-simple')
        @simpleSubmitBtn = @elem.find('#submit-simple')
        @advancedSubmitBtn = @elem.find('#submit-advanced')
        @limitInput = @elem.find('#query-limit')
        @offsetInput = @elem.find('#query-offset')
        @ratingInput = @elem.find('#query-rating')

        do @listen

    alert: (type="primary", content, autoClose=yes) ->
        return new Promise (resolve, reject) =>
            alrt = Alert(type, content)
            a = alrt()
            $(a).addClass('window-alert')
            $('body').append a
            vp = window.visualViewport
            r = $(a)[0].getBoundingClientRect()
            $(a).css('opacity', '0%')
            $(a).animate(
                {
                    opacity: '100%'
                },
                {
                    duration: 800
                    complete: =>
                        setTimeout(_.partial(alrt, 'close'), 1500) if autoClose is on
                        
                    always: =>
                        return resolve $(a)
                }
            )

        # setTimeout _.partial(alrt, 'close'), 1500

    listen: ()->
        @simpleSubmitBtn.on('click', (event) => 
            @onSimpleSubmit(event)
        )
        @advancedSubmitBtn.on 'click', (event) =>
            event.preventDefault()
            @onAdvSubmit event

        searchIntentSubmit = ()=>
            v = @simpleTermInput.val()
            if v? and v isnt ""
                @onSimpleSubmit({})

        timeoutId = null
        @simpleTermInput.keypress (event) =>
            echo event
            clearTimeout(timeoutId) if timeoutId?
            
            if event.key.toLowerCase() is "enter"
                @onSimpleSubmit(event)
            
            else
                timeoutId = setTimeout(searchIntentSubmit, 800)

        @elem.find('#adv-dropdown').submit (evt) =>
            evt.preventDefault()
            evt.stopImmediatePropogation()
            # @onAdvSubmit

    assign: (query) ->
        @simpleTermInput.val query.term
        @limitInput.val(query.limit)
        @offsetInput.val(query.offset)
        @ratingInput.val query.rating

    perform: (query) ->
        @simpleTermInput.val query.term
        if (query.offset is 0 or not query.offset?) and (query.limit is 25 or not query.limit?) and (query.rating is 'Y' or not query.rating?)
            @onSimpleSubmit({})
        else
            @limitInput.val(query.limit)
            @offsetInput.val(query.offset)
            @ratingInput.val query.rating
            @onAdvSubmit({})

    submit: (query) ->
        [query, results] = await giphy.search(query)
        # @assign query # this is so that auto-filled query parameters will persist to the next manual submission
        images = processSearchResults query, results
        StullerInstance.contentPane.setImages images

        StullerInstance.contentPane.pagination = results.pagination
        StullerInstance.contentPane.query = query
        console.log "submitted"

    onAdvSubmit: (event) ->
        query = {
            term: @simpleTermInput.val()
            limit: +@limitInput.val()
            offset: +@offsetInput.val()
            rating: @ratingInput.val()
        }
        console.log query
        @submit query


    onSimpleSubmit: (event) ->
        term = @simpleTermInput.val()
        console.log giphy
        if term? and term isnt ""
            console.log "submitting"
            this.submit({
                term: "#{term}"
            })

        else
            @simpleTermInput.val('doge')
            console.log "deferring"
            _.defer @onSimpleSubmit.bind(this, {})

appError = (error) =>
    switch error
        when "tmr"
            # request limit has been reached
            # TODO: set some global variable denoting this fact
            searchBar.instance.alert('warning', 'Giphy API Limit Reached; Try again later')
            
    #TODO: display a floating card when errors occur
    searchBar.instance.alert('warning', "#{error}")
    throw error

exports.processSearchResults = processSearchResults = (query, results) =>
    processResults(
        {
            type: "search",
            simple: yes,
            query: query
        },
        results
    )

processResults = (options, results) =>
    console.log results
    switch results.meta.status
        when 200
            console.log("OK")
        when 400, 403, 404
            appError("Bad request!")
        when 429
            appError("tmr")
    results.data = results.data.map (x) => new giphy.Giph(x)
    displayable = for gif in results.data then gif if gif.displayable
    console.log displayable
    return displayable
    