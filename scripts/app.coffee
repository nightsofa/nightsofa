console.clear = -> #doNothing
console.log = -> #doNothing


# ===
#  jQuery Plugins
# -
$.extend
  urlParams: (url) ->
    match = null
    pl = /\+/g
    search = /([^&=]+)=?([^&]*)/g
    decode = (s) ->
      decodeURIComponent(s.replace(pl, " "))
    query = url
    params = {}
    while match = search.exec(query)
      params[decode(match[1])] = decode(match[2])
    params

# ===
#  Backbone.js App
# -
window.App =
  Models: {}
  Views: {}
  Collections: {}
  Router: {}
  Live: {}
  Config:
    movieSearchURL: "https://www.google.com/uds/GwebSearch?key=notsupplied&v=1.0&safe=off&filter=0&gl=www.google.com&rsz=large&gss=.com&callback=?"
    movieDescriptionURL: "http://api.trakt.tv/movie/summary.json/515a27ba95fbd83f20690e5c22bceaff0dfbde7c"
    movieStreamsURL: "http://whateverorigin.org/get?url=https%3A//docs.google.com/get_video_info%3Fauthuser%3D%26docid%3D##VIDEOID##&mobile=##MOBILE##&callback=?"
    catalogURL: "https://yts.re/api/list.json"
    imdbSuggestionsURL: "http://sg.media-imdb.com/suggests/##FIRSTQUERYCHAR##/##QUERY##.json"
    searchQueryTemplate: "intitle:[##QUERY##] [mp4 | avi | mkv] -free -doc -pdf site:docs.google.com/file inurl:[preview OR edit]"
    $catalogContainerDOM: $("#catalogContainer")
    $movieTemplateDOM: $("#movieTemplate")
    $searchTemplateDOM: $("#searchTemplate")
    $indexTemplateDOM: $("#indexTemplate")
    $searchFieldDOM: $("#magic_field")
    $playerTemplateDOM: $("#playerTemplate")




# -
# Catalog
#

#
# Catalog Movie Extended Metadata (MODEL)
#

class App.Models.CatalogMovieExtendedMetadata extends Backbone.Model
  urlRoot: App.Config.movieDescriptionURL
  url: ->
    base = @urlRoot || ""
    "#{base.replace(/([^\/])$/, '$1/')}#{encodeURIComponent(this.id)}?callback=?"
    
  parse: (res) ->
    res.poster300 = res?.poster?.replace(/(\.(\w+))$/i,'-300$1')
    res

#
# Catalog Movie (MODEL)
#

class App.Models.CatalogMovie extends Backbone.Model

  initialize: (options) ->
    console.log 'Models:CatalogMovie::Initing...', this
    @options = options || {}

    _.bindAll this, 'extendedData', 'setModelExtendedMetadataModelClass', 'extendedMetadataChanged'

  extendedData: ->

    extendedMetadata = new @extendedMetadataModelClass
      id: @get 'ImdbCode'

    _.bindAll this, 'extendedMetadataChanged'

    @listenTo extendedMetadata, 'change', @extendedMetadataChanged
    extendedMetadata.fetch()

  setModelExtendedMetadataModelClass: (modelClass)->
    @extendedMetadataModelClass = modelClass
    @extendedData()

  extendedMetadataChanged: (model) ->
    console.log 'ModelsModels:CatalogMovieExtendedMetadata::extendedMetadataChanged', model
    @set 'extendedMetadata', model



#
# Catalog Movie (VIEW)
#

class App.Views.CatalogMovie extends Backbone.View

  initialize: (options) ->
    console.log 'Views:CatalogMovie::Initing...', this
    @options = options || {}

    @searchBarView = options?.searchBarView

    _.bindAll this, 'template', 'renderUpdate', 'render', 'search', 'searchMovie'

    @listenTo @model, 'change', @renderUpdate

  events:
    'click .search': 'searchMovie'

  searchMovie: (ev)->
    console.log 'Views:CatalogMovie::searchMovie', this, arguments
    ev?.preventDefault()
    movieTitle = @model.get 'MovieTitleFiltered'
    @search movieTitle

  search: (query) ->
    @searchBarView.search query

  template: ->

    extendedMetadata = @model.get 'extendedMetadata'
    console.log 'Views.Model.::template em', extendedMetadata

    plot = if extendedMetadata? then extendedMetadata.get 'overview' else "Loading..."

    people = if extendedMetadata? then extendedMetadata.get 'people'

    directorList = "Loading..."
    if people?.directors?
      directorList = ""
      separator = if people.directors.length > 1  then ", " else ""
      _.each people.directors, (director, i) ->
        separator = " " if i == (people.directors.length-1)
        directorList = "#{directorList}#{director.name}#{separator}"

    trailerURL = if extendedMetadata? then extendedMetadata.get 'trailer' else null

    coverUrl = if extendedMetadata? then extendedMetadata.get('poster300') else ""
      
    data =
      rating: @model.get 'MovieRating'
      coverSrc: coverUrl
      smallCoverSrc: @model.get 'CoverImage'
      shortPlot: plot
      trailerURL: trailerURL
      director: directorList
      year: @model.get 'MovieYear'
      title: @model.get 'MovieTitleFiltered'
    _.template App.Config.$movieTemplateDOM.html(), data

  renderUpdate: ->
    console.log 'View:Movie::renderUpdate', this
    @$el.html $(@template()).contents()
    # catalogLayout()

  render: ->
    console.log 'View:Movie::render', this
    @setElement $(@template())
    this


#
# Catalog (COLLECTION)
#

class App.Collections.Catalog extends Backbone.Collection
  initialize: (options) ->
    #debugger
  url: App.Config.catalogURL
  parse: (res) ->
    console.log 'Catalog response', res
    movies = res.MovieList
    movies = _.uniq movies, (movie) ->
      console.log 'Collections:Catalog::MovieParse IMDBcode', movie.ImdbCode
      movie.ImdbCode

    _.map movies, (movie)->

      # Movie Title Filtered
      movie.MovieTitleFiltered = \
        movie.MovieTitle.replace \
          /(\(\w+\))|\d+(p)|HQ|(  )+|[.,_\-;]+/g, ''

      # Large Cover
      movie.LargeCover = movie.LargeCover || movie.CoverImage?.replace(/_med\./, '_large.')

    movies


#
# Catalog (VIEW)
#

class App.Views.Catalog extends Backbone.View

  initialize: (options) ->
    console.log 'Views:Catalog::Initing..', this
    @options = options || {}

    @catalogCollection = options?.catalogCollection
    @catalogMovieViewClass = options?.catalogMovieViewClass
    @searchBarView = options?.searchBarView
    @extendedMetadataModelClass = options?.extendedMetadataModelClass

    _.bindAll this, 'onAdd', 'onReset', 'render'

    # Catalog Collection
    @listenTo @catalogCollection, 'add', @onAdd
    @listenTo @catalogCollection, 'reset', @onReset

    @catalogCollection.fetch
      reset: true # this shouldnd't be used
      data:
        limit: 50
        sort: 'seeds'
      processData: true

  events:
    'mouseenter .poster': 'movieHoverOn'
    'mouseleave .poster': 'movieHoverOff'

  movieHoverOff: (ev)->
    @$el.removeClass 'hovering'

  movieHoverOn: (ev)->
    @$el.addClass 'hovering'

  onAdd: (movie)->
    console.log 'Views:Catalog::onAdd', movie, @options
# TODO Test/try this method
#     movieView = new App.Views.Movie
#       model: movie
#       searchView: @options.searchView
#     @$el.append movieView.render().el
    #catalogLayout() // todo should pass each el

  onReset: (movies)->
    console.log 'Views:Catalog::onReset', movies
    $cacheDOM = $(document.createDocumentFragment())
    movieEach = (catalogMovieModel) ->
      console.log 'Views:Catalog::onReset movieEach', catalogMovieModel
      catalogMovieModel.setModelExtendedMetadataModelClass @extendedMetadataModelClass
      movieView = new @catalogMovieViewClass
        model: catalogMovieModel
        searchBarView: @searchBarView
      $cacheDOM.append movieView.render().el
    movies.each movieEach, this
    @$el.html $cacheDOM















# -
# Search
#

#
# Search Movie (MODEL)
#

class App.Models.SearchMovie extends Backbone.Model

  initialize: (options) ->
    _.bindAll this, 'debugAllEvents'

    @fetch()
    @listenTo this, 'all', @debugAllEvents

  debugAllEvents: ->
    console.log 'Models:SearchMovie::Parse debug all events ', @cid, arguments

  urlRoot: App.Config.movieStreamsURL
  url: ->
    isMobile = Modernizr?.touch || false
    base = @urlRoot || ""
    "#{base.replace(/([^\/])$/, '$1')}".replace("##VIDEOID##", @id).replace('##MOBILE##', isMobile)

  parse: (res) ->
    return res if res.id?
    params = $.urlParams res.contents
    console.log "Models:SearchMovie::Parse res #{@videoID}", res, this

    if params.status != "ok" || \
    !params.url_encoded_fmt_stream_map? || \
    !params.length_seconds? || \
    parseInt(params.length_seconds) < 1800
      console.log "Models:SearchMovie::Parse res destroying #{@videoID}", this
      @destroy()
      return

    streams = params.url_encoded_fmt_stream_map.split ','
    streams = _.map streams, (stream) ->
      $.urlParams stream

    res =
      streams: streams
      title: params.title
      videoID: params.docid
      length_seconds: params.length_seconds



#
# Search Movies (COLLECTION)
#

class App.Collections.SearchMovies extends Backbone.Collection

  model: App.Models.SearchMovie

  initialize: (options) ->
    _.bindAll this, 'search', 'fetch'

  url: App.Config.movieSearchURL

  search: (query) ->
    console.log 'Collections:SearchMovies::search ', query

    if !query || query == "" ||  query == " " || query.length < 3
      @reset()
      return
    
    googleQuery = App.Config.searchQueryTemplate.replace '##QUERY##', query

    @query = query
    @fetch
      data:
        q: googleQuery

  parse: (res) ->

    if res?.responseStatus != 200
      alert 'Google API error: Quota limited?'+ res.responseStatus
      return

    res = _.filter res?.responseData?.results, (result) ->
      isWebSearch = result?.GsearchResultClass == "GwebSearch"

      videoIDregEx = /docs\.google\.com\/(?:a\/[^\/]+\/)?file\/d\/([A-Za-z0-9\-_]+)\/\w+/g
      matches = []
      found = null
      while found = videoIDregEx.exec(result.url)
        for match in found
          matches.push match
      videoID = matches[1]
      result?.videoID = videoID
      hasVideoID = videoID?

      isWebSearch && hasVideoID

    console.log 'Collections:SearchMovies::Parse res', res

    res = _.map  res, (result) ->
      result =
        id: result?.videoID
#         title: result?.titleNoFormatting.replace(/Google|Drive|( - )|(\.\.\.)/gi, '')
#         url: result?.url

    console.log 'Collections:SearchMovies::Parse res', res

    res


#
# Search Movie (View)
#

class App.Views.SearchMovie extends Backbone.View


  id: ->
    "player_#{@model.cid}"

  className: 'playerWrapper'

  initialize: (options) ->
    @options = options || {}
    console.log 'Views:SearchMovie::Initing', this, options

    _.bindAll this, 'render', 'template', 'reRender' #, 'onChange' #, 'reRender'

    @listenTo @model, 'change', @render
    @listenTo @model, 'change', @reRender

#   onChange: ->
#     console.log 'Views:SearchMovie::onChange', arguments
#     @reRender()

#   reRender: ->
#     $videoDOM = $(@template())
#     @$el.
#     console.log 'Views:SearchMovie::reRender'

  reRender: ->
    console.log 'Views:SearchMovie::reRender', arguments


    @$el.addClass 'loaded'

  render: ->

    console.log 'Views:SearchMovie::Rending', this

    if @model.get('streams')?

      $videoDOM = $(@template())
      @$el.html $videoDOM

      length_seconds = @model.get('length_seconds') || 0

      player = videojs @$el.find('video')[0], null, ->
        console.log 'Views:SearchMovie::Render Player Loaded', length_seconds, this
        @duration length_seconds
        @trigger 'timeupdate'

      player.resolutionSelector
        default_res: 'medium'

      player.on 'durationchange', (ev) ->
        @trigger 'timeupdate'
        console.log 'Views:SearchMovie::Render Player::Durationchange'
        debugger


    this

  template: ->
    data =
      videoID: @model.get 'id' #|| ""
      title: @model.get 'title' #|| ""
      streams: @model.get 'streams' #|| []
      elID: @model.cid
    _.template App.Config.$playerTemplateDOM.html(), data


#
# Search RESULTS (VIEW)
#

class App.Views.SearchResults extends Backbone.View

  initialize: (options) ->
    console.log 'Views:SearchResults::Initing...', this
    @options = options || {}
    @searchBarModel = options?.searchBarModel

    @$dataEl = @$el.find '.data'

    _.bindAll this, 'queryChange', 'renderVideo', 'cleanVideo', 'search', 'onAll', 'onChange', 'onSync', 'onError', 'onRequest', 'onReset'

    @listenTo @searchBarModel, 'change:query', @queryChange

    @searchCollection = new App.Collections.SearchMovies()
    @listenTo @searchCollection, 'add', @renderVideo
    @listenTo @searchCollection, 'remove', @cleanVideo
    @listenTo @searchCollection, 'all', @onAll
    @listenTo @searchCollection, 'add remove change', @onChange
    @listenTo @searchCollection, 'reset', @onReset
    @listenTo @searchCollection, 'sync', @onSync
    @listenTo @searchCollection, 'error', @onError
    @listenTo @searchCollection, 'request', @onRequest

    @throlledSearch = _.debounce @search, 150

  onReset: ->
    oldVideos = arguments[1]?.previousModels 
    console.log 'Views:SearchResults:onReset', arguments[1].previousModels 
    _.each oldVideos, (video) =>
      @cleanVideo video
    @onChange()
    
  onError: ->
    console.log 'Views:SearchResults::onError', arguments[0], arguments
    @$el.removeClass 'loading'

  onSync: ->
    console.log 'Views:SearchResults::onSync', arguments[0], arguments
    setTimeout =>
      @$el.removeClass 'loading'
    , 200

  onRequest: ->
    console.log 'Views:SearchResults::onRequest', arguments[0], arguments
    @$el.addClass 'loading' if arguments[0] == @searchCollection

  onChange: ->

    #why d f does this work? TODO double check this method strategy
    resultsWithStreams = @searchCollection.filter((r)->r.get('streams')?).length

    console.log 'Views:SearchResults::onChange', arguments, resultsWithStreams

    if resultsWithStreams >= 1
      @$el.addClass 'haveresults'
      @$el.removeClass 'loading'
    else
      @$el.removeClass 'haveresults' #throllte this perhaps?



  onAll: ->
    console.log '-- Views:SearchResults::onAll', arguments

  renderVideo: (searchMovieModel) ->

    $("body, html").animate
      scrollTop: 0

    console.log 'Views:SearchResults::renderVideo', arguments, searchMovieModel

    #TODO return if no stream found!!!!!

    searchMovieView = new App.Views.SearchMovie
      model: searchMovieModel

    @$dataEl.append searchMovieView.render().el

    # streams = _.filter streams, (stream)->
    # stream.type.indexOf('video/mp4') > -1 && \
    # stream.quality.indexOf('medium') > -1

  cleanVideo: (searchMovieModel) ->

    console.log 'Views:SearchResults::cleanVideo', searchMovieModel

    $player = @$dataEl.find("#player_#{searchMovieModel.cid}")
    $player?.addClass 'unload'
    setTimeout =>
      $player.find('.player')[0]?.player?.dispose()
      $player?.remove()
    , 1000

  search: (query) ->
    console.log 'Views:SearchResults::Search', query
    @searchCollection.search query

  queryChange: (model) ->
    query = model.get 'query'
    console.log 'Views:SearchResults::queryChange', query
    @throlledSearch query







# -
# SEARCH BAR
#

#
# Search Bar (MODEL)
#

class App.Models.SearchBar extends Backbone.Model
  initialize: (options) ->

  defaults:
    query: ''
    placeholder: 'What do you want to watch?'

#
# Search Bar (VIEW)
#

class App.Views.SearchBar extends Backbone.View

  initialize: (options) ->
    console.log 'Views:Search::Initing...', this
    @options = options || {}

    _.bindAll this, 'search', 'template', 'render', 'autoComplete', 'onMagicFieldBlurs', 'mouseLeaveMagicField', 'mouseClickingMagicField'

    @render()

  events:
    'submit form': 'searchSubmit'
    'mouseleave .magic_field': 'mouseLeaveMagicField'
    'click .magic_field': 'mouseClickingMagicField'

  bindings:
    '.magic_field': 'query'

  mouseClickingMagicField: ->
    console.log 'Views:SearchBar:mouseClickingMagicField', arguments
    @$magicField.removeClass 'forcedBlur' #throlled?

  mouseLeaveMagicField: ->
    console.log 'Views:SearchBar:mouseLeaveMagicField', arguments
    @$magicField.removeClass 'forcedBlur' #throlled?


  searchSubmit: (ev) ->
    console.log 'Views:SearchBar::searchSubmit'
    ev?.preventDefault()
    @$magicField.addClass 'forcedBlur'
    @$magicField.blur()
    @$magicField?.autocomplete()?.clear()
    @$magicField?.autocomplete()?.clearCache()
    @$magicField?.autocomplete()?.hide()


  template: ->
    data =
      placeholder: @model?.get 'placeholder' || ""
      query: @model?.get 'query'|| ""
    _.template App.Config.$searchTemplateDOM.html(), data

  autoComplete: ->

    queryPreformat = (query) ->
      query = query.substr(0,6).replace(" ","_").toLowerCase()

    searchFn = @search

    @$magicField.autocomplete
      appendTo: @$magicField.parent()
      beforeRender: ($render) ->
        console.log 'Views:Search:AutoComplete::beforeRender', $render
        $render.attr 'style', ''

      transformResult: (res)->
        console.log 'Views:SearchBar:AutoComplete::transformResult Res', res
        suggestions = _.map res.d, (movie) ->
          { value: movie.l }
        transform =
          suggestions: suggestions

      jsonpCallback: (query)->
        query = queryPreformat query
        "imdb$#{query}"

      width: 'auto'
      triggerSelectOnValidInput: false
      maxHeight: 'auto'

      serviceUrl: (query) ->
        query = queryPreformat query
        console.log 'Views:SearchBar:AutoComplete::serviceUrl', query
        urlTemplate = App.Config.imdbSuggestionsURL
        url = urlTemplate.replace('##FIRSTQUERYCHAR##', query.charAt(0))
        url = url.replace('##QUERY##', query)

      onSelect: (sugesstion) ->
        console.log 'Views:SearchBar:AutoComplete::onSelect', arguments
        searchFn sugesstion?.value
        #@model.set 'query', sugesstion.value

      dataType: 'jsonp'
#       onSelect: (suggestion) =>
#         @model.search suggestion.value

  onMagicFieldBlurs: ->
    console.log 'Views:Search::onMagicFieldBlurs'
    setTimeout =>
      @$magicField?.autocomplete()?.hide()
      @$magicField?.autocomplete()?.clear()
    , 150

  render: ->
    console.log 'Views:Search::render', this
    @$el.html @template()

    @$magicField = $('.magic_field', @$el)

    @$magicField.blur @onMagicFieldBlurs
    @autoComplete()

    @stickit()
    this

  search: (text) ->
    console.log 'Views:SearchBar:Search', text, @$el
    @model.set 'query', text
    @$magicField.focus()
    @searchSubmit()
#     @$magicField.submit()




# -
# Index View
#

class App.Views.IndexView extends Backbone.View
  initialize: (options) ->
    console.log 'Views:IndexView::Initing...', this
    @options = options || {}
    _.bindAll this, 'template', 'resultsEl', 'render'

  searchEl: ->
    searchDOM = $('.searchContainer', @$el)
    console.log 'Views:IndexView::SearchEl', searchDOM
    searchDOM

  catalogEl: ->
    catalogDOM = $('.catalogContainer', @$el)
    console.log 'Views:IndexView::CatalogEl', catalogDOM
    catalogDOM

  resultsEl: ->
    resultsDOM = $('.results', @$el)
    console.log 'Views:IndexView::ResultsEl', resultsDOM
    resultsDOM

  template: ->
    _.template App.Config.$indexTemplateDOM.html(), {}

  render: ->
    console.log 'Views:IndexView::render', this
    @setElement $(@template())
    this




# -
# Full Screen View
#

class App.Views.FullView extends Backbone.View
  initialize: (options) ->
    console.log 'Views:FullView::Initing...'
    @options = options || {}
    _.bindAll this, 'onScroll', 'onScrollNotTop'
    @$bodyEl = $(@el.document.body)
    @onScroll()

    $god = $('html, body')
    $god.bind 'scroll mousedown DOMMouseScroll mousewheel keyup', ->
      $god.stop()

  events:
    'scroll': 'onScroll'

  setSearchBarView: (view) ->
    @$magicFieldEl = view?.$magicField
    console.log 'Views:FullView::setSearchView', @$magicFieldEl

  onScrollNotTop: ->

    console.log 'Views:FullView::onScrollNotTop'

    f = @_onScrollNotTop || @_onScrollNotTop = _.throttle =>
      console.log '+++ Views:FullView::onScrollNotTop'
      if @$bodyEl.hasClass 'scrolledTop'
        @$bodyEl.removeClass 'scrolledTop'
        @$magicFieldEl?.blur()
    , 100

    return f()

  onScroll: (ev) ->
    scrollY = @$el.scrollTop()
    return if scrollY % 2


    if scrollY > 150
      @onScrollNotTop()
    else
      @$bodyEl.addClass 'scrolledTop'



# -
# Router
#

class App.Router.RootRouter extends Backbone.Router
  routes:
    '': 'index'

  index: ->
    @doCleanUp()

    # Full View
    App.Live.FullView = new App.Views.FullView
      el: window

    # Index View
    App.Live.IndexView = new App.Views.IndexView
      fullView: App.Live.FullView
    @doRender App.Live.IndexView

    # Search
    App.Live.RootSearchBarModel = new App.Models.SearchBar()
    App.Live.RootSearchBarView = new App.Views.SearchBar
      el: App.Live.IndexView.searchEl()
      model: App.Live.RootSearchBarModel

    App.Live.FullView.setSearchBarView App.Live.RootSearchBarView

    App.Live.RootSearchResultsView = new App.Views.SearchResults
      el: App.Live.IndexView.resultsEl()
      searchBarModel: App.Live.RootSearchBarModel

    # Catalog
    App.Live.CatalogCollection = new App.Collections.Catalog [],
      model: App.Models.CatalogMovie
    App.Live.CatalogView = new App.Views.Catalog
      el: App.Live.IndexView.catalogEl()
      catalogCollection: App.Live.CatalogCollection
      catalogMovieViewClass: App.Views.CatalogMovie
      searchBarView: App.Live.RootSearchBarView
      extendedMetadataModelClass: App.Models.CatalogMovieExtendedMetadata

  doCleanUp: ->
    $('body').empty()

  doRender: (view) ->
    $('body').append view.render().el

  initialize: (options) ->
    @options = options || {}



App.Live.Router - new App.Router.RootRouter()

Backbone.history.start()
