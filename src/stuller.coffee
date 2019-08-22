
require '@webcomponents/webcomponentsjs/webcomponents-bundle'
{fetch} = require('whatwg-fetch');
# import './jquery'

util = require 'util'
require './components'

giphy = require './giphy'
sb = require './searchbar'
content = require './content'

###
Core
•	*A user should have a clear way to search for GIFs.
•	A user should be able to make their own queries to search for GIFs.
•	A user should be able to easily copy the GIF URL to a chat program.
Nice to Have
•	A user should get results shortly after they're finshed typing.
•	A user should be able to cycle through many GIFs for each search query.
•	A user should be alerted when the API limit is reached.
•	*A user should be able to see previous results even after the API limit is reached.
•	A user should be able to see 3 random gifs before searching.
###

window.stuller = class stuller
    constructor: () ->
        @window = window
        @searchBar = new sb.SearchBar(this, $('#searchbar'))
        @contentPane = new content.ContentPane(this, $('#contentpane'))
        $('#load-more-btn').click () =>
            @contentPane.loadNextPage()
        @searchBar.perform({
            term: "doge"
            limit: 12
        })

    @init: () ->
        window.slave = new Worker './js/worker.packed.js'
        window.slave.onmessage = (event) =>
            console.log event
        window.giphy = giphy
        echo = window.echo = (x) =>
            console.log x
            x
        me = new stuller()
        window.StullerInstance = me

$(document).ready ->
    stuller.init()
module.exports = stuller