
send = (msg) =>
    globalThis.postMessage(msg)

listeners = []

onMessage = (event) ->
    console.log(event)

onStructuredMessage = (type, message) =>
    ui32 = new Uint32Array(message.ab)
    console.log ui32

globalThis.onmessage = (event) => 
    if event.data?.type?
        onStructuredMessage(event.data.type, event.data)
    else
        onMessage(event)