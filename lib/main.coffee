{CompositeDisposable} = require 'atom'
WordpressSuite = null
Actions = null

config = require './config'

module.exports =

	config: config

	activate: ->
		activate = =>
			@log '------------- Activating... -------------', 6
			@subscription = new CompositeDisposable()

			WordpressSuite ?= require './wordpress-suite'
			@subscription.add atom.wordpressSuite = new WordpressSuite(@logger);

			@log '-------------- Activated! ---------------', 6

		if atom.inDevMode()
			try
				setTimeout activate,100
			catch e
				@log e.message, 1 if e?.message?
		else
			setTimeout activate,100

	deactivate: ->
		@log '------------ Deactivating... ------------', 6

		@subscription?.dispose()
		delete atom.wordpressSuite

		@log '------------- Deactivated! --------------', 6

		if atom.inDevMode()
			@log = ->
			@logger = -> ->
			@actions = null

	serialize: ->
		return

	toggle: ->
		return

	consumeDebug: (debugSetup) ->
		@logger = debugSetup(pkg: 'wordpress-suite')
		@log = @logger("main")
		@log 'Setup Debugging', 6

	consumeAutoreload: (reloader) ->
		reloader(
			pkg: 'wordpress-suite',
			files:[
				'package.json',
				'lib/actions.coffee',
				'lib/config.json',
				'lib/info.coffee',
				'lib/log-file.coffee',
				'lib/main.coffee',
				'lib/notifications.coffee',
				'lib/plugins.coffee',
				'lib/projects.coffee',
				'lib/site.coffee',
				'lib/themes.coffee',
				'lib/views.coffee',
				'lib/wordpress-suite.coffee'
				'lib/wpcli.coffee'
			]
		)
		@log 'Setup Autoreload', 6