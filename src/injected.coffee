
ExtVersion = '1.0.1'

insertText = (textArea, prefix, selected, postfix) ->
  startPos  = textArea.selectionStart
  endPos    = textArea.selectionEnd
  scrollTop = textArea.scrollTop

  textArea.value = textArea.value.substring(0, startPos) + prefix + selected + postfix + textArea.value.substring(endPos, textArea.value.length)

  textArea.focus()
  textArea.selectionStart = startPos + prefix.length
  textArea.selectionEnd   = startPos + prefix.length + selected.length
  textArea.scrollTop      = scrollTop

removeNode = (node) ->
  if node
    node.parentNode.removeChild node

loadPage = (url, callback) ->
  xhr = new XMLHttpRequest()
  xhr.onreadystatechange = =>
    if xhr.readyState is XMLHttpRequest.DONE and xhr.status is 200
      callback(null, xhr.responseText)
  xhr.onerror = (event) =>
    callback(event)
  xhr.open("GET", url, true)
  xhr.send(null)

class ExtInjected

  constructor: (@document, @window, @extName) ->
    if @injectionParentNode()
      @send 'loadKnowledgeBaseArticles', { host: location.host }

    if document.body.className.match(/page-discussions_show/) && location.href.match(/embedded=1/)
      removeNode document.querySelector('#superheader')
      removeNode document.querySelector('#header')
      removeNode document.querySelector('.footerbox')
      removeNode document.querySelector('#footer')
      removeNode document.querySelector('.watcher-widget')
      removeNode document.querySelector('.watcher-tabs')
      removeNode document.querySelector('.feed-links')

      document.querySelector('#content').style.width = '95%'
      document.querySelector('.maincol').style.float = 'none'
      document.querySelector('.maincol').style.width = '100%'
      document.querySelector('.sidebar').style.float = 'none'
      document.querySelector('.sidebar').style.width = '100%'


    for li in document.querySelectorAll("li.discussion-item")
      if href = li.querySelector("h4 a.title")?.href
        do (li, href) =>
          li.addEventListener 'click', (e) =>
            return if e.target.tagName is 'A' || (e.target.tagName is 'DIV' && e.target.className.match(/checkbox/))

            if li.nextSibling?.className?.match /bettertender-preview/
              removeNode li.nextSibling
            else
              lili = document.createElement("li")
              lili.className = "discussion-item web bulkselect-new bulkselect-open ui-draggable bettertender-preview"

              iframe = document.createElement("iframe")
              iframe.src = href + "?embedded=1" #discussion-reply-form
              iframe.style.width = "100%"
              iframe.style.height = "400px"
              lili.appendChild iframe

              li.parentNode.insertBefore lili, li.nextSibling

          , false

  receive: (eventName, data) ->
    switch eventName
      when 'kbLoaded'
        @faqs     = data.faqs
        @sections = data.sections

        @inject()
      when 'error'
        console.error "Error: ", data
      when 'getApiKey'
        @determineApiKey()

  determineApiKey: ->
    console.log "BetterTender: Getting API key..."
    loadPage "/profile", (err, text) =>
      console.log "BetterTender: Loaded /profile, err = #{err}, text length = #{text?.length}"
      if !err && (m = text.match(/// href="(/users/\d+/edit)" ///))
        loadPage m[1], (err, text) =>
          console.log "BetterTender: Loaded #{m[1]}, err = #{err}, text length = #{text?.length}"
          if !err && (mm = text.match(/// value="(\w{40})" ///))
            apiKey = mm[1]
            console.log "BetterTender: Found API key: #{apiKey}"
            @send 'apiKey', { apiKey }

  injectionParentNode: ->
    document.querySelector("dl.formrow.article .inlineactions") || document.querySelector("div#main-fields")

  createFaqSelector: (prompt, callback) ->
    select = document.createElement("select")
    option = document.createElement("option")
    option.appendChild(document.createTextNode(prompt))
    option.value = '0'
    select.appendChild(option)

    sectionsByHref = {}
    for section in @sections
      section.faqs = []
      sectionsByHref[section.href] = section

    @faqsByHref = {}
    for faq in @faqs
      @faqsByHref[faq.html_href] = faq
      if section = sectionsByHref[faq.section_href]
        section.faqs.push faq

    for section in @sections
      optgroup = document.createElement("optgroup")
      optgroup.label = section.title
      select.appendChild(optgroup)

      for faq in section.faqs
        option = document.createElement("option")
        option.appendChild(document.createTextNode(faq.title))
        option.value = faq.html_href
        optgroup.appendChild(option)

    select.addEventListener 'change', =>
      if (index = select.selectedIndex) > 0
        if faq = @faqsByHref[select.value]
          console.log "Selected: #{faq.html_href}"
          callback(faq)
          select.selectedIndex = 0
    , false

    return select

  inject: ->
    if actionsNode = @injectionParentNode()
      removeNode @select if @select
      @select = @createFaqSelector "— Link to KB article —", (faq) =>
        if textArea = document.querySelector("textarea")
          insertText textArea, "[", "#{faq.title}", "](#{faq.html_href})"
      actionsNode.insertBefore @select, actionsNode.firstChild

      if document.querySelector("div#main-fields")
        # we're on discussion page; add a control to insert entire KB contents
        removeNode @select2 if @select2
        @select2 = @createFaqSelector "— Inline KB article —", (faq) =>
          if textArea = document.querySelector("textarea")
            insertText textArea, "", faq.body.trim(), "\n"
        actionsNode.insertBefore @select2, @select.nextSibling
