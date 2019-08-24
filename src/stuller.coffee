
require '@webcomponents/webcomponentsjs/webcomponents-bundle'
require 'regenerator-runtime'
{fetch} = require('whatwg-fetch');
# import './jquery'

util = require 'util'
_ = window._ = require 'underscore'
require './components'

giphy = require './giphy'
sb = require './searchbar'
content = require './content'

###
   [App Requirements]
=========================
 
 - [ ] A user should be able to see 3 random gifs before searching.
  - DOGES are provided in their stead

==========
   Done
==========
 - [x] A user should have a clear way to search for GIFs.
 - [x] A user should be able to make their own queries to search for GIFs.
 
 - [x] A user should be able to easily copy the GIF URL to a chat program.
  - (click an image to copy the url to the clipboard)
 
 - [x] A user should be able to see previous results even after the API limit is reached.
  - (queries are cached to sessionStorage)
 
 - [x] A user should get results shortly after they're finshed typing.

 - [x] A user should be able to cycle through many GIFs for each search query.
  - each query yields many GIFs, which are all displayed
  - "Load More..." buttom allows for multi-page results

 - [x] A user should be alerted when the API limit is reached.
  - should work, but untested
###

window.stuller = class stuller
    constructor: () ->
        @window = window
        @searchBar = new sb.SearchBar(this, $('#searchbar'))
        @contentPane = new content.ContentPane(this, $('#contentpane'))
        $('#load-more-btn').click () =>
            # console.log "betty"
            @contentPane.loadNextPage()
        homeSearch = do =>
            if 'lastSearch' of localStorage then return _.pick(JSON.parse(localStorage.getItem('lastSearch')), 'term', 'rating', 'lang', 'limit')
            return {limit:10, term:'doge', rating:'PG', lang:'en'}

        @searchBar.perform(homeSearch)

    # keyboard-related listeners
    kbctrl: () ->
        @window.addEventListener 'keydown', (event) =>
            # ...

        @window.addEventListener 'keyup', (event) =>
            # ...

    @init: () ->
        window.giphy = giphy
        echo = window.echo = (x) =>
            console.log x
            x
        me = new stuller()
        window.StullerInstance = me

$(document).ready ->
    stuller.init()
module.exports = stuller