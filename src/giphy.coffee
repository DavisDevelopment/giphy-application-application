
{getJSON} = require './tools'
util = require 'util'
tools = require './tools'
fp = require './fp'
_ = require 'underscore'

{fetch} = require('whatwg-fetch');

ratings = exports.ratings = ["G", "PG"] #TODO: expand
giphyCacheSave = (query, result) =>
    cacheKey = JSON.stringify(query)
    try
        sessionStorage.setItem(cacheKey, JSON.stringify(result))
        return true
    catch error
        console.error(error)
        return false

giphyCacheRestore = (o) =>
    cacheKey = JSON.stringify(o)
    if cacheKey of sessionStorage
        return JSON.parse(sessionStorage.getItem(cacheKey))

mostRecentQuery = exports.mostRecentQuery = () =>
    try
        return JSON.parse localStorage.getItem 'lastSearch'
    finally
        return null

fillQuery = exports.fillQuery = (o={}) =>
    prev = mostRecentQuery()
    set = (k, def) =>
        o[k] ?= (prev?[k] or def)
    
    # o.term ?= ""
    # o.limit ?= 
    o.offset ?= 0
    # o.rating ?= ratings[0]
    # o.lang ?= "en"
    set 'term', ''
    set 'limit', 10
    set 'rating', ratings[0]
    set 'lang', 'en'

    return o

# queries are cached to sessionStorage
giphySearch = exports.search = (o={}) =>
    o = fillQuery o
    localStorage.setItem 'lastSearch', JSON.stringify(o)
    cached = giphyCacheRestore(o)
    if cached?
        return [o, cached]

    {term,limit,offset,rating,lang} = o
    url = "https://api.giphy.com/v1/gifs/search?api_key=c7LANKvnqSA4HmRcXCqNUN1efCHQ12tb&q=#{term}&limit=#{limit}&offset=#{offset}&rating=#{rating}&lang=#{lang}"
    result = await getJSON(url)
    giphyCacheSave(o, result)
    return [o, result]


giphyRandom = exports.random = (o={}) =>
    o.rating ?= "PG-13"
    o.tag ?= ''
    url = "https://api.giphy.com/v1/gifs/random?api_key=c7LANKvnqSA4HmRcXCqNUN1efCHQ12tb&tag=#{o.tag}&rating=#{o.rating}"
    result = await getJSON(url)
    return [o, result]

forwardFields = exports.forward = (type, spec) =>
    field = (key) =>
        frags = key.trim().split(/\s+/g)
        return [frags.splice(0, frags.length - 1), frags[0]]

    getter = (name, src) ->
        return this[src][name]
    setter = (name, src, value) ->
        return this[src][name] = value
    
    for _key, _v of spec
        source = _v.from
        fields = _key.split(/,\s/g).map(field)
        for [modifiers, name] in fields
            type::["get_#{name}"] = _.partial(getter, name, source)
            type::["set_#{name}"] = _.partial(setter, name, source, _)

            tools.property(type, name)
    return type

###
 magical functional class additions
###
magic = exports.magic = (type) =>
    if type.properties? then for name in type.properties
        if name.startsWith 'cached '
            name = name['cached '.length...]
            tmp = type.prototype[name]
            type.prototype[name] = fp.cached(tmp, {
                key: "_#{name}"
            })
        tools.property(type, name)
    if type.forward?
        forwardFields(type, type.forward)
    return type

Img = magic class Img extends tools.JSONWrapper
    @properties = ['displayable']
    constructor: (img) ->
        super(img)

    get_displayable: () -> @mp4?

ImgList = magic class ImgList
    constructor: (images) ->
        @data = do =>
            for label, img of images
                _.extend({label}, img)
        
        @images = (new Img(img) for img in @data)
        for img, idx in @images
            this[img.label] = img
            this[idx] = img
        @length = @images.length

    [Symbol.iterator]: () ->
        for idx in [0...@length]
            yield this[idx]
        return

    filter_: (predicate) ->
        for img from this
            if predicate img
                yield img
    filter: (f) ->
        return (for x from @filter_(f) then x)

###
 class which represents a GIF image on GIPHY
###
exports.Giph = magic class Giph
    @properties = [
        'cached displayableImages',
        'cached mp4Urls'
    ]
    constructor: (gif) ->
        #TODO validate object
        #TODO preinitialize properties, for performance
        Object.assign(this, gif)
        tmp = @images
        @images = new ImgList(tmp)

    get_displayable: () ->
        if @_displayable?
            return @_displayable
        else
            for key, img of @images
                if img.mp4?
                    @_displayable = true
                    return true
            return @_displayable = false

    get_mp4Urls: () ->
        return @images.filter((img) => img.displayable).map((x) => x.mp4)

    get_displayableImages: () ->
        return @images.filter((img) => img.displayable)

# Giph::get_mp4Urls = fp.cached(Giph::get_mp4Urls, {key: '_mp4Urls'})
tools.property(Giph, 'displayable')
# tools.property(Giph, 'mp4Urls')
