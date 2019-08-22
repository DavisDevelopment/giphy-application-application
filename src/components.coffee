
tools = require './tools'
{magic} = require './giphy'

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

GiphyImage = magic class GiphyImage extends HTMLVideoElement
    constructor: () ->
        super()
        @loop = yes
        @playsinline = yes
        @autoplay = yes
        @activeImg = 'fixed_height'
        @title = "(click to copy url)"

        @addEventListener 'click', (evt) => @onClick(evt)

    onClick: (event) ->
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
        gif = @_giph
        if gif?
            console.log gif
            @src = gif.mp4Urls[0]
        else
            console.log "No gif"

    get_giph: () -> @_giph
    set_giph: (giph) ->
        labels = giph?.displayableImages?.map((x) => x.label)
        @activeImg = labels[0] if labels?
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

tools.property(GiphyImage, 'giph', no, jqueryDataProperty('giph'))
tools.property(GiphyImage, 'img', no, jqueryDataProperty('img'))
tools.property(GiphyImage, 'activeImg', no, jqueryDataProperty('activeImg'))

customElements.define('giphy-image', GiphyImage, {
    extends: 'video'
})

GiphyContainer = magic class GiphyContainer extends HTMLDivElement
    constructor: () ->
        super()
        @classList.add 'giphy'
        @classList.add 'gcontainer'
        # @shadow = this.attachShadow({mode: 'closed'})
        @image = document.createElement('video', {is: 'giphy-image'})
        @image.classList.add('giphy')
        @image.addEventListener 'share', (evt) =>
            @container?.contentPane.main.searchBar.alert('info', "GIF Copied to clipboard")
        @appendChild(@image)
        
    connectedCallback: () ->
        return 

    destroy: () ->
        console.log "destroying GiphyContainer"
        @image.destroy()
        @remove()


customElements.define('giphy-div', GiphyContainer, {
    extends: 'div'
})