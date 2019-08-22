
{fetch} = require('whatwg-fetch');
# import './jquery'

util = require 'util'
tools = require './tools'
fp = require './fp'
_ = require 'underscore'
giphy = require './giphy'
content = require './content'
{Alert} = content

exports.SearchBar = class searchBar
    constructor: (@main, elem) ->
        @elem = elem
        @simpleTermInput = @elem.find('#term-simple')
        @simpleSubmitBtn = @elem.find('#submit-simple')
        @advancedSubmitBtn = @elem.find('#submit-advanced')
        @limitInput = @elem.find('#query-limit')
        @offsetInput = @elem.find('#query-offset')

        do @listen

    alert: (type="primary", content) ->
        alrt = Alert(type, content)
        a = alrt()
        a.insertAfter @elem
        setTimeout _.partial(alrt, 'close'), 1500

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

    perform: (query) ->
        @simpleTermInput.val query.term
        if (query.offset is 0 or not query.offset?) and (query.limit is 25 or not query.limit?)
            @onSimpleSubmit({})
        else
            @limitInput.val(query.limit)
            @offsetInput.val(query.offset)
            @onAdvSubmit({})

    submit: (query) ->
        [query, results] = await giphy.search(query)
        images = processSearchResults query, results
        @main.contentPane.setImages images
        @main.contentPane.pagination = results.pagination
        @main.contentPane.query = query

    onAdvSubmit: (event) ->
        query = {
            term: @simpleTermInput.val()
            limit: +@limitInput.val()
            offset: +@offsetInput.val()
        }
        console.log query
        @submit query


    onSimpleSubmit: (event) ->
        term = @simpleTermInput.val()
        echo giphy
        if term? and term isnt ""
            @submit {term: "#{term}"}

        else
            appError("Invalid search term!")

appError = (error) =>
    switch error
        when "tmr"
            # request limit has been reached
            # TODO: set some global variable denoting this fact
            echo "Too many requests!"
    #TODO: display a floating card when errors occur
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
    echo results
    switch results.meta.status
        when 200 then echo("OK")
        when 400, 403, 404
            appError("Bad request!")
        when 429
            appError("tmr")
    
    results.data = results.data.map (x) => new giphy.Giph(x)
        
    displayable = for gif in results.data then gif if gif.displayable
    console.log displayable
    return displayable
    