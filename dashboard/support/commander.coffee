### NAMESPACE: window.rw.command ###
namespace: 'commander'
command: ''
refreshFrequency: false

render: -> return null
update: -> return null

afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this
    resolvedCommands:
      builtins: ['-', ':', 'alias', 'autoload', 'bg', 'bindkey', 'break', 'builtin', 'bye', 'cap', 'cd', 'chdir', 'clone', 'command', 'echo', 'emulate', 'eval', 'export', 'false', 'getln', 'getargs', 'kill', 'let', 'limit', 'print', 'printf', 'pushln', 'read', 'set', 'shift', 'source', 'stat', 'true', 'type', 'whence', 'which']
  @self = window.rw[@namespace]

### Module start ###

#Runs the command payload
runCommand: (payload, callback, context) ->

  # TODO: add strong payload resolution here


  # resolve context
  callback = context[callback] if typeof context == 'object'

  # tests whether callback is valid
  return false unless callback instanceof Function

  # Test for a mock value to send without actually running the command
  if @rw.config.mockResults == true and context.mockValue?
    callback(null, context.mockValue, null)
    return

  # run the payload
  @run payload.actual(), (error, stdout, stderr) ->
    console.log stdout
    return
    callback(error, stdout, stderr)
  return true


# Builds a command string, with optional options and pipes
makePayload: (command, args, pipes) ->
  # validate input:  command is required; others optional
  # command and options should be a string, pipes may be a string or array
  return null unless typeof command == 'string'
  args = null unless typeof args == 'string'
  pipes = pipes.join(' | ') if pipes instanceof Array
  pipes = null unless typeof pipes == 'string'

  # build in a method to get the full command string, allowing for correction later
  actual = ->
    actual = @command
    actual = "#{actual} #{@args}" if @args?
    actual = "#{actual} | #{pipes}" if @pipes?
    return actual

  # perform a weak resolution test, simply testing against the existing resolution table
  payload = @resolve { command: command, args: args, pipes: pipes, actual: actual }

  return payload


# Validation for command payloads.  Tests whether a command is known to run as specified, and attempts to locate
# a suitable path to a command if not.  If no path is specified and the command is not pre-resolved, the command
# will be type-tested to determine if it is a valid alias or shell builtin
resolve: (payload, callback = null) ->
  # test command against pre-resolved list
  if @self.resolvedCommands.builtins.indexOf payload.command != -1
    payload.resolved = true
    payload.type = 'builtin'
    return payload

  # TODO: implement actual resolution here.  This should use 'which' or 'locate' and store resolved commands

  # does the command contain path info?  If not, prefix with default path
  payload.command = "#{@rw.config.defaultAppPath}/command" unless payload.command.search('/') == -1
  payload.resolved = false
  return payload
