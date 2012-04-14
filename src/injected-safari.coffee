
ExtInjected::send = (message, data) ->
  console.log "BetterTender: sending #{message} to the background page"
  safari.self.tab.dispatchMessage message, data

injected = new ExtInjected(document, window, 'Safari')

safari.self.addEventListener 'message', (event) ->
  console.log "BetterTender: received #{event.name} from the background page"
  injected.receive event.name, event.message
