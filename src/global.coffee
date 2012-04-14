
class Site
  constructor: (@host) ->
    @components = @host.split('.').reverse()
    if @components[0] is 'com' && @components[1] is 'tenderapp'
      @subdomain = @components[2]
    else
      @subdomain = @components[1]

    @apiKey = null
    @kb = null


Sites = {}

class ExtTab
  constructor: (@tab) ->
    @enabled = no
    @active  = no

  receive: (eventName, data) ->
    console.log "Received: #{eventName}"
    switch eventName
      when 'loadKnowledgeBaseArticles'
        @site ||= (Sites[data.host] ||= new Site(data.host))
        if @site.apiKey
          @loadKb()
        else
          @send 'getApiKey'
      when 'apiKey'
        @site.apiKey = data.apiKey
        @loadKb()


  loadKb: ->
    if @site.kb
      @send 'kbLoaded', @site.kb

    console.log "Sending AJAX request..."
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = =>
      console.log "onreadystatechange"
      if xhr.readyState is XMLHttpRequest.DONE and xhr.status is 200
        console.log "Success!"
        @site.kb = JSON.parse(xhr.responseText)
        @send 'kbLoaded', @site.kb
    xhr.onerror = (event) =>
      console.log "Error! ", event
      @send 'error', event
    xhr.open("GET", "https://api.tenderapp.com/#{@site.subdomain}/faqs", true)
    xhr.setRequestHeader 'Accept', 'application/vnd.tender-v1+json'
    xhr.setRequestHeader 'X-Tender-Auth', @site.apiKey
    xhr.send(null)


ExtGlobal =
  _tabs: []

  killZombieTabs: ->
    @_tabs = (tabState for tabState in @_tabs when @isAvailable(tabState.tab))

  killZombieTab: (tab) ->
    for tabState, index in @_tabs
      if tabState.tab is tab
        @_tabs.splice index, 1
        return
    return

  findState: (tab, create=no) ->
    for tabState in @_tabs
      return tabState if tabState.tab is tab
    if create
      state = new ExtTab(tab)
      @_tabs.push state
      state
    else
      null

  receive: (tab, eventName, data) ->
    @findState(tab, yes).receive(eventName, data)
