WP = require 'wp-cli'
yml = require 'yamljs'
command = require 'command-exists'
{CompositeDisposable, Emitter} = require 'atom'

module.exports = class WPCLI
	constructor: (directory) ->
		@emitter = new Emitter
		@root = directory
		@config = @root.getPath()

		@subscriptions = new CompositeDisposable
		@subscriptions.add atom.project.onDidChangePaths => @emitter.emit 'update'

		command 'wp', (err,exists) =>
			if not exists
				@emitter.emit 'warning', 'WP CLI is not installed.\n \nFor additional features download and install wp-cli.\n \nFree from: http://wp-cli.org/'
			else
				@main()

	main: ->
		config_path = @root.getFile('wp-cli.yml')
		config_path.exists().then (exists) =>
			if exists
				config_path.read().then (contents) =>
					if contents
						parsed = yml.parse(contents)
						if parsed.path
							@config = @root.getSubdirectory(parsed.path).getPath()
					@discover()
			else
				@discover()

		@emitter.emit 'main'

	discover: ->
		console.log @config
		WP.discover { path: @config }, (wp) =>
			@wp = wp

			@wp.option.get 'blogname', (err,data) =>
				if err
					@emitter.emit 'error', err
				else
					@emitter.emit 'name', data

			@emitter.emit 'discover'

	export: (dbname = 'latest-db.sql') ->
		exportPath = @root.getSubdirectory('db')
		exportPath.create().then (created) =>
			dbpath = exportPath.getPath() + '/' + dbname
			@wp.db.export dbpath, (err,data) =>
				if err
					@emitter.emit 'error', err
				else
					@emitter.emit 'export', data

	import: (dbname = 'latest-db.sql') ->
		today = new Date
		timestamp = "backup-#{today.getFullYear()}-#{(today.getMonth()+1)}-#{today.getDate()}-#{today.getHours()}-#{today.getMinutes()}-#{today.getSeconds()}.sql"
		@export(timestamp)
		importPath = @root.getSubdirectory('db').getPath() + '/' + dbname
		importPath.exists().then (exists) =>
			if exists
				@wp.db.import importPath, (err,data) =>
					if err
						@emitter.emit 'error', err
					else
						@emitter.emit 'import', data
			else
				@emitter.emit 'error', 'No Database Found'

	dispose: ->
		@emitter?.emit 'dispose'
		@emitter?.dispose()
		@subscriptions?.dispose()

	onDidInitialize: (callback) ->
		@emitter.on('main', callback)

	onDidDiscover: (callback) ->
		@emitter.on('discover', callback)

	onDidUpdate: (callback) ->
		@emitter.on('update', callback)

	onDidDispose: (callback) ->
		@emitter.on('dispose', callback)

	onDidName: (callback) ->
		@emitter.on('name', callback)

	onDidURL: (callback) ->
		@emitter.on('url', callback)

	onDidPlugin: (callback) ->
		@emitter.on('plugin', callback)

	onDidWarning: (callback) ->
		@emitter.on('warning', callback)

	onDidError: (callback) ->
		@emitter.on('error', callback)

	onDidExport: (callback) ->
		@emitter.on('export', callback)

	onDidImport: (callback) ->
		@emitter.on('import', callback)