
tools = require './tools'
{magic} = require './giphy'
_download = require './download'
_ = require 'underscore'

do =>

    jqueryDataProperty = (name) =>
        getter = -> $(this).data(name)
        setter = (set, value) -> 
            $(this).data(name, value)
            return set.call(this, value)
        return {
            isWrapper: yes,
            get: getter,
            set: setter
        }

    ###
    total hack
    ###
    _tmp = customElements.define.bind(customElements)
    cedef = (...args) =>
        if WebComponents.ready
            _tmp(...args)
        else
            _.defer _.partial(cedef, ...args)
    customElements.define = cedef
    _dce = document.createElement.bind(document)
    remaps = {}
    remappedElement = (tag, override) =>
        ctor = remaps["#{override} extends #{tag}"]
        if ctor?
            self = _dce(tag)
            ctor.call self
            for name, method of ctor::
                self[name] = method
            return self

    dce = (tag, opts, ...args) =>
        # name = opts['is']
        special = remappedElement(tag, opts['is'])
        if special? and special instanceof Element
            return special
        return _dce(tag, opts, ...args)
    # document['createElement'] = dce

    extag = (tag, overrideName) =>
        wrapper = (ctor) =>
            remaps["#{overrideName} extends #{tag}"] = ctor
        return wrapper

    _cedef = (_super, name, ctor, opts) =>
        if not opts?
            return _super(name, ctor, opts)
        if opts?.extends?
            override = opts.extends
            remaps["#{name} extends #{override}"] = ctor
        return _super(name, ctor, opts)
    customElements.define = _.wrap(customElements.define, _cedef)

    GiphyImage = ->
        # super()

        @loop = yes
        @playsinline = yes
        @autoplay = yes
        ###
        BINGO
        ("fixed_height_small" makes the grid look SOOO much betty than "fixed_height")
        ###
        @activeImg = 'fixed_height_small'
        @addEventListener 'srcchange', (evt) =>
            console.log 'source changed'
            @classList.remove 'ready'
        
        @addEventListener 'loadeddata', (evt) =>
            @classList.add 'ready'

    GiphyImage.prototype =
        share: ->
            # console.log event
            # if event.ctrlKey or event.shiftKey or event.altKey

            await tools.clipboard.writeText(@giph.url)
            @dispatchEvent(new Event('share'))

        connectedCallback: () ->
            console.log(this)
            do @update

        disconnectedCallback: () ->
            console.log("removed", this)

        destroy: () ->
            @remove()

        update: () ->
            console.log "updating"
            gif = @giph
            if gif?
                null
            else
                console.log "No gif"

        get_giph: () -> @_giph
        set_giph: (giph) ->
            # labels = giph?.displayableImages?.map((x) => x.label)
            # @activeImg = labels[0] if labels?
            if not (giph.images[@activeImg]?.displayable)
                #TODO:
                throw 'invalid @activeImg'
            @activeImg = @activeImg
            return giph

        get_img: () -> null
        set_img: (img) ->
            if not img?
                return
            if not img.displayable
                throw new Error("Image is not displayable")
            @src = img.mp4

        get_activeImg: () -> null
        set_activeImg: (v) ->
            @img = @giph?.images[v]
            return v
    
    GiphyImage = magic GiphyImage
    tools.property(GiphyImage, 'giph', no, jqueryDataProperty('giph'))
    tools.property(GiphyImage, 'img', no, jqueryDataProperty('img'))
    tools.property(GiphyImage, 'activeImg', no, jqueryDataProperty('activeImg'))

    lGiphyImage = window.lGiphyImage = GiphyImage
    # Object.getOwnPropertyDescriptors
    # Object.assign(HTMLVideoElement.prototype, GiphyImage.prototype)
    Object.defineProperties(HTMLVideoElement.prototype, Object.getOwnPropertyDescriptors(GiphyImage.prototype))
    window.GiphyImage = () =>
        v = document.createElement('video')
        lGiphyImage.call(v)
        return v

    ## written to facilitate downloads
    load = (url) =>
        type = null
        ab = await fetch(url).then (res) =>
            console.log res.headers
            type = res.headers.get('content-type')
            res.arrayBuffer()
        # blob = new Blob([ab], {type})
        return [type, ab]

    # keep around for historical purposes
    # works great in Chrome
    download = (url, filename) =>
        msg = StullerInstance.searchBar.alert('info', "Downloading <strong>#{filename}</strong>...", off)
        [type, data] = await load(url)
        _download(data, filename, type)
        # cleanup = =>
            # msg.remove()
            # URL.revokeObjectURL newUrl
        msg.then (e) =>
            $(e).html("<strong>\"#{filename}\" saved!</strong>")
            setTimeout(
                ()=>
                    $(e).alert('close')
                    $(e).remove()
                    # do cleanup
                1200
            )

    GiphyContainer = () ->
        # super()
        @classList.add 'giphy'
        @classList.add 'gcontainer'
        # @shadow = this.attachShadow({mode: 'closed'})
        # @image = document.createElement('video', {is: 'giphy-image'})
        @image = window.GiphyImage()
        @image.classList.add('giphy')
        @image.addEventListener 'share', (evt) =>
            @container?.contentPane.main.searchBar.alert('info', "GIF Copied to clipboard")
        @appendChild(@image)

        @overlay = document.createElement('div')
        @overlay.classList.add('giphy-video-overlay')
        @appendChild @overlay

        icon = (src) =>
            img = new Image()
            img.src = src
            @overlay.appendChild img
            return img
        # copy = icon 'res/copy-48.png'
        copy = icon 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAQAAAD9CzEMAAAAAmJLR0QA/4ePzL8AAACGSURBVFjD7dfLDYAgEATQKUTP1A4hoTElQgNagdnNbPwcZrzCvAPZZAWUP2VFxcRJfo76nS53ATVU7wDm04D7IBsBBMDNxURD8gCRuehYbSA2F8UGYnMxbIB99Nt7AgQIECBAgABqvxLwPRBbvA4baCEg20BCp+s3LL7f2oJBbKXZV6+8lQtX4JuQDLmI8gAAAABJRU5ErkJggg=='
        copy.title = "Copy GIF URL"
        $(copy).click (evt) =>
            @image.share()

        # dl = icon 'res/download-48.png'
        dl = icon 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAQAAAD9CzEMAAAAAmJLR0QA/4ePzL8AAACsSURBVFjD7dRBCoMwFATQWbUXbMmi3keh9wzeIUK6ECHR/7WRkVKY+RslMI9EIqD8R+54IyIXE9HjxgOGqnyZgQeMJhB5QHaGDnjvAgQIEMAHAtLBz81eTQjfEg+H2AMmvFp2YRM+0FjvER5wor4mJnSb1Wexeqp+n6DU+wSt3iao9VuCXl9fvVQ8BRCzvt3k+jVxQX35LYhnbxEX1s8HFaAoXjJ5BLQDyq/yASm+2y9SsDh4AAAAAElFTkSuQmCC'
        dl.title = 'Save GIF'
        $(dl).css {
            float: 'right'
        }
        $(dl).click (evt) =>
            url = @image.giph.images['original'].url
            title = @image.giph.title
            download url, "#{title}.gif"
        
        @addEventListener 'mouseenter', (evt) =>
            if not $(@image).is('.ready') then return

            r = @image.getBoundingClientRect()
            $(@overlay).css 
                display: 'block'
                top: (window.scrollY + r.top + r.height - $(@overlay).height())
                opacity: '0'
                width: r.width
                # left: r.left
            $(@overlay).animate(
                {
                    opacity: '100'
                },
                {
                    duration: 400
                }
            )

        @addEventListener 'mouseleave', (evt) =>
            r = @image.getBoundingClientRect()
            $(@overlay).css
                display: 'none'
            
    GiphyContainer.prototype =
        connectedCallback: () ->
            return 

        destroy: () ->
            console.log "destroying GiphyContainer"
            @image.destroy()
            @remove()

    GiphyContainer = magic GiphyContainer
    # Object.assign(HTMLDivElement::, GiphyContainer::)
    Object.defineProperties(HTMLDivElement.prototype, Object.getOwnPropertyDescriptors(GiphyContainer.prototype))
    lGiphyDiv = GiphyContainer
    window.GiphyDiv = () =>
        div = document.createElement 'div'
        lGiphyDiv.call(div)
        return div
    customElements.define('giphy-div', GiphyContainer, {
        extends: 'div'
    })

    _.defer =>
        console.log remaps