{CompositeDisposable, Emitter, Disposable} = require 'atom'

module.exports = class Media

	constructor: (wp,logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.wpcli.media"
		@wp     = wp

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@setup()

		new Disposable()

	setup: ->
		@subscriptions.add atom.commands.add ".project-root",
			"wordpress-suite:site:add-media": (event) =>
				console.log 'test'

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [
			{ label: 'Media', command: "wordpress-suite:site:add-media" }
		]} }

	onNotification: (callback) ->
		@emitter.on('notification', callback)

	onMessage: (callback) ->
		@emitter.on('message', callback)

	dispose: ->
		@log "Disposed", 6

		@subscriptions?.dispose()

		if atom.inDevMode()
			@logger = -> ->
			@log = ->
			@wp = null
			@subscriptions = null
			@emitter = null
			@directory = null
			@media = null