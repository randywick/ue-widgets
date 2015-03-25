### NAMESPACE: window.rw.speedtest ###
namespace: 'speedtest'
command: ''
refreshFrequency: false

render: -> return null
update: -> return null

afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this
    state: 'ready'
    current: null
    history: []
  @self = window.rw[@namespace]


afterBoot: ->
  @rw.data.speedtest = {}
  @fetch()


### SPEED TEST ###
# Powered by speedtest.net, using the excellent speedtest-cli python script by sivel,
# available at https://github.com/sivel/speedtest-cli

mockValue: """
Ping: 37.452 ms
Download: 43.15 Mbit/s
Upload: 23.03 Mbit/s
"""

fetch: ->
  payload = @rw.commander.makePayload('/usr/local/bin/speedtest-cli', '--simple')
  @rw.commander.runCommand(payload, 'captureResult', 'speedtest')


captureResult: (error, stdout, stderr) ->
  data = @parseResults(stdout)
  @rw.data.speedtest.current = data
  @rw.dashboard.updateSpeedTest(data)


# parse the command output and structure the output. expecting lines containing:
# Measurement: [rate] [order]
# Download: 50 Mbit/s
parseResults: (raw) ->
  # split the output into lines
  lines = raw.split '\n'
  response = {}
  for line in lines
    # split the lines into columns
    pair = line.split(': ')

    # reject any malformed data pairs
    continue if pair.length != 2

    # rename for clarity
    metric = pair[0].toLowerCase()
    data = pair[1].split ' '

    # something went wrong with the data here.  Log it to the console so we can inspect
    unless data.length == 2
      console.log "unexpected data: #{line}"
      continue

    response[metric] =
      value: data[0]
      order: data[1]

  return response
