### NAMESPACE: window.rw.helpers ###
namespace: 'helpers'
command: ''
refreshFrequency: false

render: -> return null
update: -> return null

afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this

  @self = window.rw[@namespace]


# Converts a camelCaseWord to a hyphen-case-word
camelToHyphen: (camel) ->
  return null unless typeof camel == 'string'
  return camel.replace /([A-Z])/g, (match) ->
    return '-' + match.toLowerCase()

# Returns a simple timestamp
timestamp: ->
  date = new Date
  return date.getHours() + ':' + date.getMinutes()