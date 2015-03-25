### NAMESPACE: window.rw.dashboard ###
namespace: 'dashboard'
command: ''
refreshFrequency: false
view: 'debug'

render: (output) -> return @makeView @view

afterRender: (domEl) ->
  @documentElement = domEl
  window.rw = {} unless window.rw?
  window.rw[@namespace] =
    context: this
  @self = window.rw[@namespace]
  #noinspection JSUnresolvedVariable
  uebersicht.makeBgSlice(el) for el in $(domEl).find '.bg-slice'

afterBoot: ->


#TODO: Get rid of this bridge
updateSpeedTest: (payload) ->
  packet =
    display: @displayType.result
    changes:
      currentSpeedValue: payload.download.value
      currentSpeedOrder: payload.download.order
  @updateElements(packet)



updateElements: (payload) ->
  @debugMessage = []
  @setVisibility @rw.helpers.camelToHyphen(payload.display)
  for element, value of payload.changes
    @setValue @rw.helpers.camelToHyphen(element), value
    console.log @rw.helpers.camelToHyphen(element), value
  @setValue 'last-update', @timestamp
  @setValue 'debug', @debugMessage.join "<br>"
  @setValue 'raw', @raw



displayType:
  result: 'currentResult'
  error: 'currentError'

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
    <div id="rawdata"></div>
    <canvas class="bg-slice"></canvas>
    <div class="content" id="content">
      @@content
    </div>
    """

  widget: """
    <div id="result" class="selfish section">
      <div id="notification"></div>
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
  top 0
  left 0
  width 25%
  height 100%
  overflow hidden
  font 12px Georgia, serif

  $spacing = 15px

  .section
  	padding $spacing $spacing 0

  .content
    border-radius 2px
    background rgba(#fff, 0.1)
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