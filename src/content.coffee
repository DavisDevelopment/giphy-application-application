
tools = require './tools'
_ = require 'underscore'
util = require 'util'
observe = require './observe'
{magic} = require './giphy'
giphy = require './giphy'

sb = require './searchbar'

###
 responsible for management of GIF display grids
###
ContentPane = exports.ContentPane = magic class ContentPane
    constructor: (@main, e) ->
        @e = $(e)
        @containers = []

    loadNextPage: () ->
        if @pagination? and @query?
            q = @query
            newQuery = _.extend({}, q, {offset: q.offset + @pagination.count})
            # newQuery = {
            #     ...q,
            #     offset: @query.offset + @pagination.count
            # }
            console.log newQuery
            [query, results] = await giphy.search(newQuery)
            images = sb.processSearchResults query, results
            @pagination = results.pagination
            @query = query
            @appendImages images
            return yes
        else
            console.log "not fired"
            return no

    clear: () ->
        @containers.forEach (c) =>
            c.destroy()
        @containers.length = 0
        $(@e).html('')

    append: (e) ->
        if Array.isArray(e)
            for x in e
                @append(x)
        else if e instanceof Container
            console.log "append Container"
            @containers.push e
            # e.inject @e, (me, c) =>
            #     me.append(c)
            @e.append e.element
            console.log e.element
        else if e instanceof giphy.Giph
            @append(new Container(this, e))

        else
            throw new Error("invalid #{e}")

    ###
     TODO: pool and reuse Container instances
    ###
    setImages: (images) ->
        @clear()
        @appendImages images

    appendImages: (images) ->
        for img in images
            @append img

Container = exports.Container = magic class Container
    @properties = []
    @forward = {
        'image': {from: 'element'},
        'activeImage, giph': {from: 'image'}
    }

    constructor: (pane, g) ->
        @contentPane = pane
        # @element = document.createElement('div', {is: 'giphy-div'})
        @element = window.GiphyDiv()
        @element.container = this
        @element.image.giph = g
        
    inject: (parent, fn) ->
        return fn($(parent), $(@element))

    destroy: () ->
        @element.destroy()
        @element = null

Page = exports.Page = magic class Page
    constructor: (cursor, images) ->
        {count, offset, total_count} = cursor
        @cursor = new PaginationCursor(count, offset, total_count)
        @images = images

class PaginationCursor
    constructor: (@count, @offset, @total_count) ->
        null

    load: (index) ->
        query = {
            limit: @count,
            offset: @count * index
        }
        return (await giphy.search(query))[1]

Alert = exports.Alert = (type, content) =>
    html = [
        "<div class=\"alert alert-#{type} alert-dismissible fade show\" role=\"alert\">",
        content,
        '<button type="button" class="close" data-dismiss="alert" aria-label="Close">',
            '<span aria-hidden="true">&times;</span>',
        '</button>',
        '</div>'
    ].join('')
    e = $(html)
    e = $(e)
    return e.alert.bind(e)
