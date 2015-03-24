command: "echo ''"
refreshFrequency: 3000
historyMaxLength: 10
view: 'debug'

### COMMAND ###
commands:
  getSpeedTest:
    mockValue: '456KiB/s'
    binary: '/usr/local/bin/aria2c'
    flags: [
      '--auto-file-renaming=false',
      '--allow-overwrite=true',
      '--dir=\"/tmp\"',
      '--out=\"speedgun.tmp\"'
      '--max-connection-per-server=8'
    ]
    target: 'http://speedtest.reliableservers.com/10MBtest.bin'
    routing: ['2>', '/dev/null']
    pipes: [
      'tail -n 4',
      'head -n 1',
      "awk '{split($0,a,\"|\"); print a[3]}'",
      "sed -e 's/^[[:space:]]*//'"
    ]

runCommand: (command, mock = false) ->
  return @selfUpdate command.mockValue unless mock == false

  command.pipes.unshift('')
  cmd = [
    command.binary,
    command.flags.join(" "),
    command.target,
    command.routing.join(" "),
    command.pipes.join(" | ")
  ]
  @run cmd.join(" "), @selfUpdate

### SYSTEM METHODS ###

render: (output) ->
  @raw = output
  return @makeView @view

afterRender: (domEl) ->
  #noinspection JSUnresolvedVariable
  uebersicht.makeBgSlice(el) for el in $(domEl).find '.bg-slice'

update: (output, domEl) ->
  @documentElement = domEl
  @runCommand @commands.getSpeedTest, true

selfUpdate: (output) ->
  @raw = output
  @debugMessage = []
  result = @processBits output
  @updateElements @makePayload(result)


### UPDATE METHODS ###
updateElements: (payload) ->
  @setVisibility @camelToHyphen(payload.display)
  @setValue @camelToHyphen(element), value for element, value of payload.changes
  @setValue 'last-update', @timestamp
  @setValue 'debug', @debugMessage.join "<br>"
  @setValue 'raw', @raw



### RAW PROCESSING ###
processBits: (raw) ->
  tokens = raw.match /(^\d*\d?)(.*)/
  return @response('error', errorDetail: "command output invalid: #{raw}") unless tokens.length == 3

  conversion =
    'KiB/s': 1024 * 8
    'MiB/s': 1048576 * 8

  bits = conversion[tokens[2]] * tokens[1]
  return @response('error', errorDetail: "command output invalid: #{raw}") if isNaN(bits)

  @pushToHistory bits

  kilo = 1000
  sizes = ['bps', 'Kbps', 'Mbps']
  i = Math.floor(Math.log(bits) / Math.log(kilo))

  result =
    currentSpeedValue: (bits / Math.pow(kilo, i)).toPrecision(3)
    currentSpeedOrder: sizes[i]

  return @response('result', result)




### DISPLAY ###
# sets one 'selfish' element to visible and all others to invisible
setVisibility: (section) ->
  elements = $(@documentElement).find '.selfish'
  for el in elements
    @debugMessage.push $(el).attr 'id'
  @debugMessage.push section
  return
  el.removeClass 'invisible' unless el.attr('id') == section for el in elements
  section = $(@documentElement).find section
  section.addClass 'invisible' unless section.hasClass 'invisible'

setValue: (element, value) ->
  target = element unless typeof element == 'string'
  target = $(@documentElement).find '#' + element if typeof element == 'string'
  return unless target?
  target.html value

### HISTORY ###
pushToHistory: (bits) ->
  @history = [] unless @history?
  @history.push(bits)
  @history.shift unless @history.length < @historyMaxLength



### MESSAGING ###
# helper to create a simple response dto
response: (type, value) ->
  response =
    type: type
    value: value

  return response

# helper to create a simple payload dto
makePayload: (response) ->
  payload =
    display: @displayType[response.type]
    changes: response.value

  return payload


### CONFIG OBJECTS ###
displayType:
  result: 'currentResult'
  error: 'currentError'


### HELPERS ###
camelToHyphen: (camel) ->
  return null unless typeof camel == 'string'
  return camel.replace /([A-Z])/g, (match) ->
    return '-' + match.toLowerCase()

timestamp: ->
  date = new Date
  return date.getHours() + ':' + date.getMinutes()


### TEMPLATING ###
views:
  main: master: {content: ['widget']}
  debug: master: {content: ['widget', 'debug']}
  raw: master: {content: ['raw']}

makeView: (view) ->
  return unless @views[view]?
  response = []
  for partial, content of @views[view]
    continue unless @partials[partial]
    response.push @inject @partials[partial], content

  return response.join ""


inject: (template, patterns) ->
  for pattern, replacements of patterns
    replacements = [replacements] if typeof replacements == 'string'
    continue unless replacements instanceof Array
    replacement = ((@partials[item] if @partials[item]?) ? item for item in replacements)
    regex = new RegExp('@@' + pattern, 'g')
    template = template.replace(match, replacement.join "") for match in template.match regex

  # capture any non-overwritten internal references within the partial
  matches = template.match new RegExp('(?:@@)+([a-zA-Z]+)', 'g')
  return template unless matches?

  template = (template.replace match, (@partials[match.substring(2)] ? match) for match in matches)
  return template

partials:
  master: """
    <canvas class="bg-slice"></canvas>
    <div class="content" id="content">
      @@content
    </div>
    """

  widget: """
    <div id="result" class="selfish section">
      <div id="current-result">
        <span class="desc">Download Speed</span>
        <div class="inner-frame">
          <span id="current-speed-value"></span>
          <span id="current-speed-order"></span>
        </div>
      </div>
      <div id="current-error" class="selfish invisible section">
        <span class="desc error">An error has occurred:</span>
        <span id="error-detail"></span>
      </div>
      <div id="last-update-container" class="section">
        Last updated: <span id="last-update"></span>
      </div>
    </div>
    @@historyContainer
    """

  historyContainer: """
    <hr>
    <div id="history-container"></div>
    """

  debug: """
    <div class="section">
      <h2>DEBUG</h2>
      <div id="debug"></div>
    </div>
    """

  raw: """
    <div id="raw"></div>
    """


style: """
  top 10%
  left 10%
  width 250px
  height 250px
  overflow hidden
  font 12px Georgia, serif

  $spacing = 15px

  .section
  	padding $spacing $spacing 0

  .content
    border-radius 2px
    background rgba(#fff, 0.5)
    color #152033

    hr
    	border-top 1px solid rgba(#bbb, 0.2)
    	border-bottom none
    	margin-bottom 0px

  	.desc
  		font-size 1.2em

  bg-blur = 10px

  .bg-slice
    position absolute
    top -(bg-blur)
    left -(bg-blur)
    width 100% + 2*bg-blur
    height 100% + 2*bg-blur
    -webkit-filter blur(bg-blur)

  .invisible
  	display none

	#current-speed-value
		font-size 4em
		font-weight 700

	#current-speed-order
		font-size 2em
		font-weight 400

	#history-container
		height 50
		position relative
"""