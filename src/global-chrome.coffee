
ExtTab::send = (message, data={}) ->
  chrome.tabs.sendRequest @tab, [message, data]

ExtGlobal.isAvailable = (tab) -> yes

chrome.tabs.onRemoved.addListener (tabId) ->
  ExtGlobal.killZombieTab tabId

chrome.extension.onRequest.addListener ([eventName, data], sender, sendResponse) ->
  console.log "#{eventName}(#{JSON.stringify(data)})"
  ExtGlobal.receive sender.tab.id, eventName, data
