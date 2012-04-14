
ExtTab::send = (message, data={}) ->
  @tab.page.dispatchMessage message, data

ExtGlobal.isAvailable = (tab) -> !!tab.url

safari.application.addEventListener 'message', (event) ->
  console.log "#{event.name}(#{JSON.stringify(event.message)})"
  ExtGlobal.receive event.target, event.name, event.message
