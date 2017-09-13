{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'

module.exports = class Editor

	constructor: (wp,logger,namespace) ->
		@namespace = namespace
		@logger = logger
		@log    = @logger "site.#{@namespace}.wpcli.editor"
		@wp     = wp

		@directory = null
		@menu = []

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@menu = []
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		@subscriptions.add atom.commands.add "atom-text-editor", "wordpress-suite:site:editor:evaluate:#{@namespace}": (event) => atom.wordpressSuite.getSelectedSite().wpcli.editor.evaluate()

		@subscriptions.add atom.contextMenu.add { "atom-text-editor": [{ label: 'Wordpress Suite', submenu: [{ label: 'Evaluate Code', command: "wordpress-suite:site:editor:evaluate:#{@namespace}"}], shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.editor) }] }

	getMenu: ->
		if @menu.length > 0
			return @menu
		return [{ label: "Loading...", enabled: false }]

	evaluate: ->
		editor = atom.workspace.getActiveTextEditor()
		selection = editor.getSelectedText()
		if selection
			@wp.eval "'#{selection}'", (err,message) =>
				if err
					@emitter.emit 'message', [ 'WP-CLI: Code Evaluated', 'error', err ]
				else
					@emitter.emit 'message', [ 'WP-CLI: Code Evaluated', 'info', message ]

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
			@menu = []