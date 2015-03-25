#----------------------------------------------------------------------------------------------------
# NAMESPACE: window.rw.bootstrap
#
#    MODULE: Bootstrapper, a small utility designed to load and connect Uebersicht CoffeeScript files
#
#    The purpose of this module is to detect and related modules safely and predictably.
#    This works as follows:
#
# 1) At boot, this script will seek any modules listed in @modules with a key and context referenced at
#    window.rw (e.g., window.rw.myModule.context = this)
#
# 2) Bootstrapper will compile all loaded modules contexts at window.rw.bootstrap.aliases and inject a
#    reference to the same in each module at @rw.  Thus, any module may access any other module at @rw.moduleName
#
# 3) Bootstrapper will call the boot method on each module.  The boot method should contain any instructions
#    the module requires prior to being interactive, and no module is guaranteed any specific resource will be
#    available during the boot sequence
#
# 4) After all boot() methods have completed, Bootstrapper will call the afterBoot() method on each module.  At
#    this time, modules are fully interactive and may freely invoke each other's methods.  Use this sequence, for
#    example, to add tasks to the Scheduler or dispatch a command to the Commander to poll external data.
#
#    Any module may be referenced, provided it:
#
# A) Registers a reference to its base context (e.g., this) at window.rw.moduleName.context
# B) Respects the @rw reserved property (used for aliases)
# C) Does not contain a boot() or afterBoot() method, or if it does, the calling of either will not break
#    the module
#
#    NOTE: Bootstrapper relies upon boot() (if set) setting @readyStatus to 'ready' upon completing its
#          boot process.  Failure to set this will not result in an error, but will cause the Bootstrapper
#          to exhaust @maxSequenceAttempts prior to moving on.  If you experience unusually long loading delays,
#          this is a good place to start investigating.
#----------------------------------------------------------------------------------------------------

namespace: 'bootstrap'
command: ''
refreshFrequency: false
readyState: 'not ready'
bootSequence: 'boot'
maxSequenceAttempts: 50
modules: [
  'bootstrap',
  'commander',
  'config',
  'helpers',
  'dashboard',
  'speedtest',
  'scheduler',
  'data'
]

render: -> return null

update: ->
  # select an action based upon the boot sequence
  return @[@bootSequence]() if @[@bootSequence]?
  # possibly test for desirable @bootSequence value here and throw and Error if not?
  console.log 'boot sequence terminated'
  @refreshFrequency = false

afterRender: ->
  window.rw = {} unless window.rw?
  window.rw[@namespace] = context: this
  @self = window.rw[@namespace]
  return null



boot: ->
  try
    @enter 'boot'
  catch e
    @bootSequence = 'failed'
    return console.log 'Main boot sequence failed.  Is bootstrap trying to enter itself?', e

  # initialize accessible properties
  @self.aliases = {} unless @self.aliases?

  @refreshFrequency = 300
  @bootSequence = 'loadModules'

# Ensure each module is booted and aliases are assigned before setting booted property to true
loadModules: ->
  try
    @enter 'loadModules'
  catch e
    @bootSequence = 'failed'
    return console.log 'one or more modules failed to load', @loaded

  @loaded = {} unless @loaded?

  for module in @modules
    # skip if the module is not initialized
    continue unless window.rw[module]?

    # alias for cleanliness
    ctx = window.rw[module].context

    # register the module as loaded and create an alias
    @loaded[module] = module

    # if no boot method is included, insert a stub and flag as ready
    unless ctx.boot?
      ctx.boot = -> return null
      ctx.readyState = 'ready'

    # if no afterBoot method is included, insert a stub
    unless ctx.afterBoot?
      ctx.afterBoot = -> return null

    # add a reference to the module's context to the global alias object
    @self.aliases[module] = ctx

    # inject a reference to the global alias object into the module context
    ctx.rw = @self.aliases

  for module in @modules
    continue if @loaded[module]?
    # find on any modules that haven't loaded yet here
    return

  @bootSequence = 'bootModules'


# Iterate over the modules and call the 'boot' method on each, waiting until the modules reports ready before
# moving to the next sequence
bootModules: ->
  try
    @enter 'bootModules'
  catch e
    unless e.type is 'recoverable'
      @bootSequence = 'failed'
      return console.log 'an unrecoverable error has been thrown', e.message

    # If this error is caught, we have exceeded the allowed attempts without one or more modules loading.
    # we can try to proceed anyway.  First, grab a list of unset ready states to identify the most likely culprits
    readyStateUnset = (module unless window.rw[module].context.readyState? for module in @modules)
    console.log 'one or more modules failed to register boot status.  Attempting to continue', @booting, readyStateUnset

    # advance the boot sequence so we don't have to go through this again
    @bootSequence = 'afterBoot'

  # iterate over modules and call the boot() method, omitting this module
  unless @booting?
    for module in @modules
      window.rw[module].context.boot.call(window.rw[module].context) unless module is @namespace

  # build a new array of modules not reporting 'ready' (or not reporting anything)
  @booting = []
  for module in @modules
    continue if module is @namespace

    # ready state unset.  not an error but may develop into one
    unless window.rw[module].context.readyState?
      @booting.push module
      continue

    # ready state other than 'ready'
    @booting.push module unless window.rw[module].context.readyState == 'ready'

  # only update boot sequence if no modules are still pending
  @bootSequence = 'afterBoot' unless @booting.length > 0



# simply iterate over modules and call the afterBoot() method; no guarantees of completion for afterBoot
afterBoot: ->
  try
    @enter 'afterBoot'
  catch e
    @bootSequence = 'failed'
    return console.log 'Failed to enter afterBoot sequence.  Is bootstrap attempting to load itself?', e

  @bootSequence = 'completed'

  # call afterBoot() on every module aside from this
  for module in @modules
    window.rw[module].context.afterBoot() unless module is @namespace

  @readyState = 'ready'



# Observe a boot sequence for runaway loops and ensure the sequence entered agrees with @bootSequence
enter: (sequence) ->
  # test the provided sequence against expected bootSequence
  unless sequence is @bootSequence
    error = new Error()
    error.type = 'unrecoverable'
    error.code = 2
    error.message = "BOOT SEQUENCE STATE MISMATCH: EXPECTED #{@bootSequence}; OBSERVED #{sequence}"
    throw error

  @sequenceAttempts = {} unless @sequenceAttempts?

  # if this is the first impression, initialize a @sequenceAttempts record
  unless @sequenceAttempts[sequence]?
    @sequenceAttempts[sequence] = 0
    console.log "#{sequence} sequence properly entered"

  # Throw an error if the maximum boot sequence attempts has been exceeded
  unless @sequenceAttempts[sequence] < @maxSequenceAttempts
    error = new Error()
    error.type = 'recoverable'
    error.code = 1
    error.message = "Maximum boot sequence attempts of #{@maxSequenceAttempts} exceeded for #{sequence}"
    throw error

  return @sequenceAttempts[sequence]++