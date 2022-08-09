// Polyfill for custom events in IE9-11
// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#polyfill
;(function () {
  if (typeof window.CustomEvent === 'function') return false

  function CustomEvent(event, params) {
    params = params || { bubbles: false, cancelable: false, detail: undefined }
    var evt = document.createEvent('CustomEvent')
    evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail)
    return evt
  }

  CustomEvent.prototype = window.Event.prototype

  window.CustomEvent = CustomEvent

  // eslint expects a return here
  return true
})()

export const blueprintUpdatedEvent = (blueprint) => {
  const event = new CustomEvent('blueprint-updated', {
    detail: {
      blueprint
    },
  })
  window.dispatchEvent(event)
}
