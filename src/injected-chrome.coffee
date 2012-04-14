
ExtInjected::send = (message, data) ->
  console.log "BetterTender: sending #{message} to the background page"
  chrome.extension.sendRequest [message, data]

injected = new ExtInjected(document, window, 'Chrome')

chrome.extension.onRequest.addListener ([eventName, data], sender, sendResponse) ->
  console.log "BetterTender: received #{eventName} from the background page"
  injected.receive eventName, data
