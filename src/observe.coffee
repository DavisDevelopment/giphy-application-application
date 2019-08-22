
_ = require 'underscore'
util = require 'util'
{EventEmitter} = require 'events'
tools = require './tools'
fp = require './fp'

tickLoop = do =>
    _callbacks = []
    _nextCallbacks = []
    _cycle = (...args) ->
        tmp = _nextCallbacks[0...]
        _nextCallbacks.length = 0
        for cb in tmp
            cb.call(this, ...args)
        for cb in _callbacks
            cb.call(this, ...args)
        _.defer(_cycle.bind(this, ...args))
        # _callbacks.length = 0
    _.defer(_cycle.bind(this))
    {
        on: (cb) =>
            _callbacks.push(cb)
        once: (cb) =>
            _nextCallbacks.push(cb)
    }

_emit = (o, evt, ...args) =>
    tickLoop.once () =>
        o.emit(evt, ...args)

class Observer extends EventEmitter
    @instances = []
    @_uid = 0

    constructor: (o) ->
        super()
        @_id = Observer._uid++
        Observer.instances.push(this)
        
        for key in Object.keys(o)
            @__defineGetter__(key, ()=>o[key])
            @__defineSetter__ key, (v) =>
                if v isnt o[key]
                    _emit(this, 'change', key, [o[key], v])
                o[key] = v
                return v

    free: ->
        Observer.instances.splice(Observer.instances.indexOf(this))

exports.Observer = Observer

