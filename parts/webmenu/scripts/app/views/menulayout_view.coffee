define [
  "backbone.viewmaster"

  "cs!app/views/itemdescription_view"
  "cs!app/views/menulist_view"
  "cs!app/views/breadcrumbs_view"
  "cs!app/views/profile_view"
  "cs!app/views/favorites_view"
  "cs!app/views/search_view"
  "cs!app/views/search_result_view"
  "cs!app/application"
  "hbs!app/templates/menulayout"
  "app/utils/debounce"
], (
  ViewMaster

  ItemDescriptionView
  MenuListView
  Breadcrumbs
  ProfileView
  Favorites
  Search
  SearchResult
  Application
  template
  debounce
) ->

  class MenuLayout extends ViewMaster

    className: "bb-menu"

    template: template

    constructor: (opts) ->
      super
      @initialMenu = opts.initialMenu
      @allItems = opts.allItems
      @user = opts.user
      @config = opts.config

      @searchResultView = new SearchResult allItems: @allItems
      @menuListView = new MenuListView
        model: model

      @setMenu(@initialMenu)

      @bindTo Application.global, "select", (model) =>
        if model.get("type") is "menu"
          @setMenu model
          @renderViews()

      delayedShowProfile = debounce =>
        @showProfile()
        @renderViews()
      , 50

      @bindTo Application.global, "showDescription", (model) =>
        delayedShowProfile.cancel()
        @setView ".sidebar", new ItemDescriptionView
          model: model
        @renderViews()

      @bindTo Application.global, "hideDescription", => delayedShowProfile()

      @showProfile()

      @setView ".favorites", new Favorites
        collection: @allItems
        config: @config

      @bindTo this, "filter change", (filter) ->
        @setView ".menu-app-list-container", @searchResultView
        @searchResultView.displayItems(filter)
        console.log "Filter: ", filter
        @renderViews()

    showProfile: ->
      @setView ".sidebar", new ProfileView
        model: @user
        config: @config

    reset: ->
      @setMenu(@initialMenu)

    setMenu: (model) ->
      @setView ".menu-app-list-container", @menuListView
      @setView ".breadcrums-container", new Breadcrumbs
        model: model
      @setView ".search-container", new Search


