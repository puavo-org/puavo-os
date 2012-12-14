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
      @current = @initialMenu

      @allItems = opts.allItems
      @user = opts.user
      @config = opts.config

      @firstItem = @allItems[0]

      @menuListView = new MenuListView
      @setView ".menu-app-list-container", @menuListView
      @displayCurrentMenu()

      @bindTo Application.global, "select", (model) =>
        if model.get("type") is "menu"
          @current = model
          @displayCurrentMenu()

      @bindTo this, "startFirstApplication", (filter) =>
        Application.bridge.trigger "open", @firstItem.toJSON()
 

      @setView ".sidebar", new ProfileView
        model: @user
        config: @config

      @setView ".favorites", new Favorites
        collection: @allItems
        config: @config

      if FEATURE_SEARCH
        @setView ".search-container", new Search
        @bindTo this, "changeFilter", (filter) ->
          if filter.trim()
            resultItems = @allItems.searchFilter(filter)
            @firstItem = resultItems[0]
            @menuListView.displayItems resultItems
          else
            @displayCurrentMenu()

    reset: ->
      @curret = @initialMenu
      @displayCurrentMenu()

    displayCurrentMenu: ->
      @menuListView.displayItems @current.items.toArray()
      @setView ".breadcrums-container", new Breadcrumbs
        model: @current
      @refreshViews()


