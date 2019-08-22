
_ = require 'underscore'
tools = require './tools'

cached = module.exports.cached = (get, opts) ->
    self = this
    if not opts.key?
        throw new Error("Must provide 'key' option")
    # opts.cache ?= {}
    cacheKey = opts.key
    getKey = do =>
        if tools.isFunction(cacheKey)
            (...args) -> cacheKey.apply(this, args)
        else
            () -> cacheKey
    return () ->
        key = getKey.call(this)
        cache = (if opts.cache? then opts.cache else this)
        cached = cache[key]
        if cached?
            return cached
        result = get.call(this)
        cache[key] = result
        return result