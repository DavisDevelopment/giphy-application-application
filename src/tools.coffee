{fetch} = require('whatwg-fetch');
# import './jquery'

util = require 'util'
_ = require 'underscore'

isFunction = exports.isFunction = (x) => typeof x is "function"
exports.getJSON = (url, options) => fetch(url, options).then (res) => res.json()

clipboard = exports.clipboard = {}
clipboard.writeText = (text) =>
    await navigator.clipboard.writeText("#{text}")
    return true

property = exports.property = (type, name, isStatic=no, proxy) =>
    proto = if isStatic then type else type.prototype
    getter = proto["get_#{name}"]
    setter = proto["set_#{name}"]
    if proxy?
        wrap = proxy.isWrapper or false
        getter = if wrap then _.wrap(getter, proxy.get) else proxy.get
        setter = if wrap then _.wrap(setter, proxy.set) else proxy.set
    prop = {
        enumerable: yes
    }
    prop.get = getter if getter?
    prop.set = setter if setter?
    Object.defineProperty(proto, name, prop)
    return

exports.JSONWrapper = class JSONWrapper
    constructor: (src) ->
        if typeof src is "string"
            src = JSON.parse(src)
        if not this instanceof JSONWrapper
            return new JSONWrapper(src)
        Object.assign(this, src)

defaultValueOf = Object::valueOf
hash = exports.hash = (o) =>
  switch typeof o
    when 'boolean'
      # The hash values for built-in constants are a 1 value for each 5-byte
      # shift region expect for the first, which encodes the value. This
      # reduces the odds of a hash collision for these common values.
      return if o then 0x42108421 else 0x42108420
    when 'number'
      return hashNumber(o)
    when 'string'
      return if o.length > STRING_HASH_CACHE_MIN_STRLEN then cachedHashString(o) else hashString(o)
    when 'object', 'function'
      if o == null
        return 0x42108422
      if typeof o.hashCode == 'function'
        # Drop any high bits from accidentally long hash codes.
        return smi(o.hashCode(o))
      if o.valueOf != defaultValueOf and typeof o.valueOf == 'function'
        o = o.valueOf(o)
      return hashJSObj(o)
    when 'undefined'
      return 0x42108423
    else
      if typeof o.toString == 'function'
        return hashString(o.toString())
      throw new Error('Value type ' + typeof o + ' cannot be hashed.')
  return

# Get references to ES5 object methods.
isExtensible = Object.isExtensible
# True if Object.defineProperty works as expected. IE8 fails this test.
canDefineProperty = do ->
  try
    Object.defineProperty {}, '@', {}
    return true
  catch e
    return false
  return
# If possible, use a WeakMap.
usingWeakMap = typeof WeakMap == 'function'
weakMap = undefined

smi = (i32) => i32 >>> 1 & 0x40000000 | i32 & 0xbfffffff

# Compress arbitrarily large numbers into smi hashes.

hashNumber = (n) =>
  if n != n or n == Infinity
    return 0
  h = n | 0
  if h != n
    h ^= n * 0xffffffff
  while n > 0xffffffff
    n /= 0xffffffff
    h ^= n
  smi h

cachedHashString = (string) =>
  hashed = stringHashCache[string]
  if hashed == undefined
    hashed = hashString(string)
    if STRING_HASH_CACHE_SIZE == STRING_HASH_CACHE_MAX_SIZE
      STRING_HASH_CACHE_SIZE = 0
      stringHashCache = {}
    STRING_HASH_CACHE_SIZE++
    stringHashCache[string] = hashed
  hashed

# http://jsperf.com/hashing-strings

hashString = (string) =>
  # This is the hash from JVM
  # The hash code for a string is computed as
  # s[0] * 31 ^ (n - 1) + s[1] * 31 ^ (n - 2) + ... + s[n - 1],
  # where s[i] is the ith character of the string and n is the length of
  # the string. We "mod" the result to make it between 0 (inclusive) and 2^31
  # (exclusive) by dropping high bits.
  hashed = 0
  ii = 0
  while ii < string.length
    hashed = 31 * hashed + string.charCodeAt(ii) | 0
    ii++
  smi hashed

hashJSObj = (obj) ->
  hashed = undefined
  if usingWeakMap
    hashed = weakMap.get(obj)
    if hashed != undefined
      return hashed
  hashed = obj[UID_HASH_KEY]
  if hashed != undefined
    return hashed
  if !canDefineProperty
    hashed = obj.propertyIsEnumerable and obj.propertyIsEnumerable[UID_HASH_KEY]
    if hashed != undefined
      return hashed
    hashed = getIENodeHash(obj)
    if hashed != undefined
      return hashed
  hashed = ++objHashUID
  if objHashUID & 0x40000000
    objHashUID = 0
  if usingWeakMap
    weakMap.set obj, hashed
  else if isExtensible != undefined and isExtensible(obj) == false
    throw new Error('Non-extensible objects are not allowed as keys.')
  else if canDefineProperty
    Object.defineProperty obj, UID_HASH_KEY,
      enumerable: false
      configurable: false
      writable: false
      value: hashed
  else if obj.propertyIsEnumerable != undefined and obj.propertyIsEnumerable == obj.constructor::propertyIsEnumerable
    # Since we can't define a non-enumerable property on the object
    # we'll hijack one of the less-used non-enumerable properties to
    # save our hash on it. Since this is a function it will not show up in
    # `JSON.stringify` which is what we want.

    obj.propertyIsEnumerable = ->
      @constructor::propertyIsEnumerable.apply this, arguments

    obj.propertyIsEnumerable[UID_HASH_KEY] = hashed
  else if obj.nodeType != undefined
    # At this point we couldn't get the IE `uniqueID` to use as a hash
    # and we couldn't use a non-enumerable property to exploit the
    # dontEnum bug so we simply add the `UID_HASH_KEY` on the node
    # itself.
    obj[UID_HASH_KEY] = hashed
  else
    throw new Error('Unable to set a non-enumerable property on object.')
  hashed

# IE has a `uniqueID` property on DOM nodes. We can construct the hash from it
# and avoid memory leaks from the IE cloneNode bug.

getIENodeHash = (node) ->
  if node and node.nodeType > 0
    switch node.nodeType
      when 1
        # Element
        return node.uniqueID
      when 9
        # Document
        return node.documentElement and node.documentElement.uniqueID
  return

if usingWeakMap
  weakMap = new WeakMap
objHashUID = 0
UID_HASH_KEY = '__immutablehash__'
if typeof Symbol == 'function'
  UID_HASH_KEY = Symbol(UID_HASH_KEY)
STRING_HASH_CACHE_MIN_STRLEN = 16
STRING_HASH_CACHE_MAX_SIZE = 255
STRING_HASH_CACHE_SIZE = 0
stringHashCache = {}
