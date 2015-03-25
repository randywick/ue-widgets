### NAMESPACE: window.rw.data ###
namespace: 'data'
command: ''
refreshFrequency: false

render: -> return null
update: -> return null

afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this

  @self = window.rw[@namespace]