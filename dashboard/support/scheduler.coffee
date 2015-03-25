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
  @maxInterval = 0
  @schedule = {}
  @readyState = 'ready'

scheduleAction: (interval, callback) ->
  safeInterval = parseInt(interval)
  throw new TypeError("interval MUST be an integer (#{interval} provided") if isNaN(safeInterval)
  @schedule[safeInterval] = [] unless @schedule[interval]?
  @schedule[safeInterval].push callback
  @maxInterval = safeInterval unless @maxInterval > safeInterval