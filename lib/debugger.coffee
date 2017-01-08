{CompositeDisposable, Emitter} = require 'atom'

module.exports = class Debugger
	constructor: (directory) ->
		@emitter = new Emitter
		@root = directory
		@directory = @root.getSubdirectory('wp-content')
		@log = @directory.getFile('debug.log')
		@history = ''
		@watching = false
		@ignored = []

		@buttons = [
			{
				text: 'Clear',
				className: 'btn-clear',
				onDidClick: =>
					@clear()
			},
			{
				text: 'Open',
				className: 'btn-open',
				onDidClick: =>
					@open()
			},
			{
				className: 'btn-ignore btn-right',
				onDidClick: (event) =>
					notification = event.target.parentElement.parentElement.parentElement.parentElement.model
					message = notification.getDetail()
					notification.dismiss()
					@ignore_add(message)
			}
		]

		@subscriptions = new CompositeDisposable
		@subscriptions.add @root.onDidChange => @main()

	main: ->
		@directory.exists().then (exists) =>
			if exists and not @initialized
				@create()
				@subscriptions.add @log.onDidChange => @change()
				@subscriptions.add @log.onDidRename => @create()
				@subscriptions.add @log.onDidDelete => @main()
			@initialized = exists
			@emitter.emit 'status:initialized', @initialized
			@watching = exists
			@emitter.emit 'status:watching', @watching

	create: ->
		@log.create().then (created) =>
			if not created
				@emitter.emit 'log:created'
				@log.read().then (contents) =>
					@history = contents
					@emitter.emit 'status:contents', @history

	open: ->
		atom.workspace.open(@log.getPath(), {pending:false, searchAllPanes:true})
		@emitter.emit 'log:open'

	clear: ->
		@log.write('')
		@history = ''
		@emitter.emit 'log:clear'
		@emitter.emit 'status:contents', @history

	pause: ->
		@watching = false
		@emitter.emit 'status:watching', @watching

	resume: ->
		@watching = true
		@emitter.emit 'status:watching', @watching

	ignore_add: (message) ->
		@ignored.push(message)
		@emitter.emit 'ignored:add'
		@emitter.emit 'status:ignored', @ignored.length > 0

	ignore_clear: ->
		@ignored = []
		@emitter.emit 'ignored:clear'
		@emitter.emit 'status:ignored', @ignored.length > 0

	change: ->
		@log.read().then (contents) =>
			if contents.length >= @history.length
				messages = contents.replace(@history,'').split(/^\[\d{2}-\w{3}-\d{4} \d{2}:\d{2}:\d{2} UTC\] /gm)
				for message in messages
					if message isnt ''
						if message.indexOf('PHP Parse error:') == 0
							message = message.replace(/PHP Parse error:\s+/,'')
							title = 'Error'
							type = 'error'
						else if message.indexOf('PHP Notice:') == 0
							message = message.replace(/PHP Notice:\s+/,'')
							title = 'Notice'
							type = 'warning'
						else if message.indexOf('PHP Deprecated:') == 0
							message = message.replace(/PHP Deprecated:\s+/,'')
							title = 'Deprecation'
							type = 'warning'
						else if message.indexOf('PHP Warning:') == 0
							message = message.replace(/PHP Warning:\s+/,'')
							title = 'Warning'
							type = 'warning'
						else
							title = 'Message'
							type = 'info'
						if @watching and message not in @ignored
							@emitter.emit 'log:message', [title, type, { dismissable:true, detail: message, buttons: @buttons }]
			@history = contents
			@emitter.emit 'status:contents', @history

	onIsInitialized: (callback) ->
		@emitter.on('status:initialized', callback)

	onIsWatching: (callback) ->
		@emitter.on('status:watching', callback)

	onIsContents: (callback) ->
		@emitter.on('status:contents', callback)

	onIsIgnored: (callback) ->
		@emitter.on('status:ignored', callback)

	onDidClear: (callback) ->
		@emitter.on('log:clear', callback)

	onDidOpen: (callback) ->
		@emitter.on('log:open', callback)

	onDidLog: (callback) ->
		@emitter.on('log:message', callback)

	onDidIgnoredAdd: (callback) ->
		@emitter.on('ignored:add', callback)

	onDidIgnoredClear: (callback) ->
		@emitter.on('ignored:clear', callback)

	dispose: ->
		@emitter?.dispose()
		@subscriptions?.dispose()