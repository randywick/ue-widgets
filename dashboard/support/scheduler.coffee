### NAMESPACE: window.rw.scheduler ###
namespace: 'scheduler'
command: ''
refreshFrequency: false

render: -> return null
update: -> return null

afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this

  @self = window.rw[@namespace]

boot: ->
  @schedule = {}
  @readyState = 'ready'

scheduleAction: (interval, callback) ->
  @schedule[interval] = [] unless @schedule[interval]?
  @schedule[interval].push callback