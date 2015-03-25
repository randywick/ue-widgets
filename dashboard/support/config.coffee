### NAMESPACE: window.rw.config ###
namespace: 'config'
command: ''
refreshFrequency: false

render: -> return null
update: -> return null

### APPLICATION CONFIGURATION ###
afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this
  @self = window.rw[@namespace]


defaultAppPath: '/usr/local/bin'
mockResults: false