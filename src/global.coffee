
class Tender
  constructor: (@apiKey, @subdomain) ->

  load: (url, callback) ->
    url = "https://api.tenderapp.com/#{@subdomain}/#{url}"
    console.log "Loading #{url}..."
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = =>
      console.log "onreadystatechange"
      if xhr.readyState is XMLHttpRequest.DONE and xhr.status is 200
        console.log "Success!"
        response = JSON.parse(xhr.responseText)
        console.log response

        callback(null, response)
    xhr.onerror = (event) =>
      console.log "Error! ", event
      callback(event)
    xhr.open("GET", url, true)
    xhr.setRequestHeader 'Accept', 'application/vnd.tender-v1+json'
    xhr.setRequestHeader 'X-Tender-Auth', @apiKey
    xhr.send(null)

  loadList: (url, key, callback) ->
    items = []

    query = (page) =>
      @load "#{url}?page=#{page}", (err, response) =>
        return callback(err) if err

        items.push.apply(items, response[key])

        if response.offset + response.per_page < response.total
          query(page + 1)
        else
          callback(null, items)

    query(1)



class Site
  constructor: (@host) ->
    @components = @host.split('.').reverse()
    if @components[0] is 'com' && @components[1] is 'tenderapp'
      @subdomain = @components[2]
    else
      @subdomain = @components[1]

    @apiKey = null

    @faqs = null
    @sections = null
    @kbCallbacks = null

  loadKb: (thisCallback) ->
    if @faqs && @sections
      thisCallback(null, { @faqs, @sections })

    if @kbCallbacks
      @kbCallbacks.push thisCallback
    else
      @kbCallbacks = [thisCallback]

      @tender ||= new Tender(@apiKey, @subdomain)
      @tender.loadList "sections", 'sections', (err, sections) =>
        if err
          for callback in @kbCallbacks
            callback(err)
          @kbCallbacks = null
        else
          @sections = sections

          @tender.loadList "faqs", 'faqs', (err, faqs) =>
            if err
              for callback in @kbCallbacks
                callback(err)
              @kbCallbacks = null
            else
              @faqs = faqs
              for callback in @kbCallbacks
                callback(null, { @faqs, @sections })
              @kbCallbacks = null


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
    @site.loadKb (err, result) =>
      if err
        @send 'error', err
      else
        @send 'kbLoaded', result


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
