WP = require 'wp-cli'
yml = require 'yamljs'
command = require 'command-exists'
{CompositeDisposable, Emitter} = require 'atom'

module.exports = class WPCLI
	constructor: (directory) ->
		@emitter = new Emitter
		@root    = directory
		@name    = @root.getBaseName()
		@site    = {
			path: @root.getPath(),
			yml: @root.getFile('wp-cli.yml'),
			config: @root.getFile('wp-config.php'),
			db: {
				dbname:@name,
				dbuser:'root',
				dbpass:'root'
			},
			details: {
				url:'http://localhost/'+@name,
				title:@name,
				admin_user:'root',
				admin_password:'root',
				admin_email:'admin@'+@name+'.com'
			},
		}

		@subscriptions = new CompositeDisposable
		@subscriptions.add @root.onDidChange => @main()

	main: ->
		command 'wp', (err,exists) =>
			@emitter.emit 'status:command', exists
			if exists
				@check_yml()
			else
				@initialized = true
				@emitter.emit 'status:initialized', @initialized

	setup: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		WP.discover { path: @site.path }, (wp) =>
			@wp = wp
			@check_files()

	check_yml: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@site.yml.exists().then (exists) =>
			if exists
				@subscriptions.add @site.yml.onDidChange => @check_yml()
				@subscriptions.add @site.yml.onDidRename => @check_yml()
				@subscriptions.add @site.yml.onDidDelete => @check_yml()

				@site.yml.read().then (contents) =>
					if contents
						parsed = yml.parse(contents)
						if parsed?.path?
							core = @root.getSubdirectory(parsed.path)
							@site.config = core.getFile('wp-config.php')
					@setup()
			else
				@setup()

	check_files: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.core.version (err,installed) =>
			@emitter.emit 'status:installed', installed
			@check_config()
			if not installed
				@initialized = true
				@emitter.emit 'status:initialized', @initialized
			@installed = installed

	check_config: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@site.config.exists().then (exists) =>
			@emitter.emit 'status:configured', exists
			@check_db()
			if exists
				@subscriptions.add @site.config.onDidChange => @check_config()
				@subscriptions.add @site.config.onDidRename => @check_config()
				@subscriptions.add @site.config.onDidDelete => @check_config()
			else
				@initialized = true
				@emitter.emit 'status:initialized', @initialized
			@configured = exists

	check_db: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.db.check (err) =>
			checked = not err
			@emitter.emit 'status:checked', checked
			@check_connect()
			if not checked
				@initialized = true
				@emitter.emit 'status:initialized', @initialized
			@checked = checked

	check_connect: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.core.is_installed (err) =>
			connected = not err
			@emitter.emit 'status:connected', connected
			@initialized = true
			@emitter.emit 'status:initialized', @initialized
			if connected
				@getName()
				@getPlugins()
				@getContent()
			@connected = connected

	getName: ->
		@wp.option.get 'blogname', (err,name) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'wordpress:name', name

	getPlugins: ->
		@wp.plugin.list (err,plugins) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'wordpress:plugins', plugins

	getContent: ->
		@wp.eval "'echo WP_CONTENT_DIR;'", (err, dir) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'wordpress:content', dir

	download: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.core.download (err,download) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'files:download', download
				@check_files()
			@initialized = true
			@emitter.emit 'status:initialized', @initialized

	config: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.core.config @site.db, (err,config) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'files:config', config
				@check_config()
			@initialized = true
			@emitter.emit 'status:initialized', @initialized

	create: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.db.create (err,create) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'database:create', create
				@check_db()
			@initialized = true
			@emitter.emit 'status:initialized', @initialized

	install: ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		@wp.core.install @site.details, (err,install) =>
			if err
				@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
			else
				@emitter.emit 'files:install', install
				@check_connect()
			@initialized = true
			@emitter.emit 'status:initialized', @initialized

	export: (dbname = 'latest-db.sql') ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		exportPath = @root.getSubdirectory('db')
		exportPath.create().then (created) =>
			dbpath = exportPath.getPath() + '/' + dbname
			@wp.db.export dbpath, (err,data) =>
				if err
					@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
				else
					@emitter.emit 'database:export', data
			@initialized = true
			@emitter.emit 'status:initialized', @initialized

	import: (dbname = 'latest-db.sql') ->
		@initialized = false
		@emitter.emit 'status:processing', @initialized
		today = new Date
		timestamp = "backup-#{today.getFullYear()}-#{(today.getMonth()+1)}-#{today.getDate()}-#{today.getHours()}-#{today.getMinutes()}-#{today.getSeconds()}.sql"
		@export(timestamp)
		importPath = @root.getSubdirectory('db').getFile(dbname)
		importPath.exists().then (exists) =>
			if exists
				dbpath = importPath.getPath()
				@wp.db.import dbpath, (err,data) =>
					if err
						@emitter.emit 'message:error', ['WP-CLI Error', 'error', {dismissable:true,detail:err}]
					else
						@emitter.emit 'database:import', data
			else
				@emitter.emit 'message:error', 'No Database Found'
			@initialized = true
			@emitter.emit 'status:initialized', @initialized

	onIsCommand: (callback) ->
		@emitter.on('status:command', callback)

	onIsInitialized: (callback) ->
		@emitter.on('status:initialized', callback)

	onIsInstalled: (callback) ->
		@emitter.on('status:installed', callback)

	onIsConfigured: (callback) ->
		@emitter.on('status:configured', callback)

	onIsChecked: (callback) ->
		@emitter.on('status:checked', callback)

	onIsConnected: (callback) ->
		@emitter.on('status:connected', callback)

	onDidName: (callback) ->
		@emitter.on('wordpress:name', callback)

	onDidPlugins: (callback) ->
		@emitter.on('wordpress:plugins', callback)

	onDidContent: (callback) ->
		@emitter.on('wordpress:content', callback)

	onDidDownload: (callback) ->
		@emitter.on('files:download', callback)

	onDidConfig: (callback) ->
		@emitter.on('files:config', callback)

	onDidInstall: (callback) ->
		@emitter.on('files:install', callback)

	onDidCreate: (callback) ->
		@emitter.on('database:create', callback)

	onDidExport: (callback) ->
		@emitter.on('database:export', callback)

	onDidImport: (callback) ->
		@emitter.on('database:import', callback)

	onDidError: (callback) ->
		@emitter.on('message:error', callback)

	dispose: ->
		@emitter?.dispose()
		@subscriptions?.dispose()