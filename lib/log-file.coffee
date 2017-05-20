{CompositeDisposable, Disposable, Emitter, Directory, File} = require 'atom'

module.exports = class LogFile

	constructor: (sitePath,logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.filewatcher"
		@sitePath = sitePath

		@contents = ''
		@emitter  = new Emitter

		@subscriptions = new CompositeDisposable

		@setup()

		@log "Created", 6

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@file = null
		@folder = null
		@watching = null
		@contents = ''
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		folder = new Directory(@sitePath).getSubdirectory('wp-content')
		folder.exists().then (exists) =>
			if exists
				@folder = folder
				@file = @folder.getFile('debug.log')

				@subscriptions.add @file.onDidChange => @onDidChange()
				# @subscriptions.add @file.onDidRename => console.log('renamed')
				# @subscriptions.add @file.onDidDelete => console.log('deleted')

				@watching = true

				@emitter.emit 'notification', [ 'Log File: Watching For Messages' ]

				@file.create().then (created) =>
					if not created
						@file.read().then (contents) =>
							@contents = contents

	clear: ->
		@file.write('')
		@contents = ''
		@emitter.emit 'notification', [ 'Log File: Cleared' ]

	open: ->
		atom.workspace.open(@file.getPath(), {pending:false, searchAllPanes:true})
		@emitter.emit 'notification', [ 'Log File: Opened' ]

	pauseWatching: ->
		@watching = false
		@emitter.emit 'notification', [ 'Log File: Paused Watching', 'warning' ]

	resumeWatching: ->
		@watching = true
		@emitter.emit 'notification', [ 'Log File: Resumed Watching' ]

	onNotification: (callback) ->
		@emitter.on('notification', callback)

	onMessage: (callback) ->
		@emitter.on('message', callback)

	onDidChange: ->
		if @watching
			@file.read().then (contents) =>
				if contents.length >= @contents.length
					messages = contents.replace(@contents,'').split(/^\[\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2} UTC\] /gm)
					for message in messages
						if message isnt ''
							if message.indexOf('PHP Parse error:') == 0
								message = message.replace(/PHP Parse error:\s+/,'')
								title = 'Log File Error'
								type = 'error'
							else if message.indexOf('PHP Notice:') == 0
								message = message.replace(/PHP Notice:\s+/,'')
								title = 'Log File Notice'
								type = 'warning'
							else if message.indexOf('PHP Deprecated:') == 0
								message = message.replace(/PHP Deprecated:\s+/,'')
								title = 'Log File Deprecation'
								type = 'warning'
							else if message.indexOf('PHP Warning:') == 0
								message = message.replace(/PHP Warning:\s+/,'')
								title = 'Log File Warning'
								type = 'warning'
							else
								title = 'Log File Message'
								type = 'info'
							@emitter.emit 'message', [title, type, message]
				@contents = contents

	dispose: ->
		@log "Removed", 6

		if @watching and @file
			@emitter.emit 'notification', [ 'Log File: No Longer Being Watched', 'warning' ]

		@subscriptions?.dispose()

		if atom.inDevMode()
			@logger = -> ->
			@log = ->
			@sitePath = null
			@file = null
			@folder = null
			@watching = null
			@contents = ''
			@emitter = null
