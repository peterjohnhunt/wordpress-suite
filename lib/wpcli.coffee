{CompositeDisposable, Disposable, Emitter, Directory} = require 'atom'
WP = require 'wp-cli'
yml = require 'yamljs'
command = require 'command-exists'

Plugins = require './plugins'
Themes = require './themes'

module.exports = class WPCLI

	constructor: (sitePath,logger,namespace) ->
		@namespace = namespace
		@logger    = logger
		@log       = @logger "site.#{namespace}.wpcli"
		@sitePath  = sitePath
		@options   = {path: "#{sitePath}/"}

		@status = {
			yml: null
			exists: null
			initialized: null
			core: null
			config: null
			database: null
			installed: null
			ready: null
		}

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@status = {
			yml: null
			exists: null
			initialized: null
			core: null
			config: null
			database: null
			installed: null
			ready: null
		}
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		config = new Directory(@sitePath).getFile('wp-cli.yml')
		config.exists().then (exists) =>
			@status.yml = exists
			if exists
				config.read().then (contents) =>
					@options = yml.parse(contents)
					@check_command()
					if not @options.path
						@options.path = @sitePath
			else
				@check_command()

	check_command: ->
		command 'wp', (err,exists) =>
			@status.exists = exists
			if @status.exists
				@log "Exists", 6

				WP.discover @options, (wp) =>
					@status.initialized = true
					@wp = wp
					@check_core()

			else
				@log "Does Not Exist", 4

	check_core: ->
		@log 'checking core', 6
		if @status.initialized
			@wp.core.version (err,installed) =>
				@log 'handling core check', 6
				@status.core = not err
				if @status.core
					@log 'core exists', 6
					@check_config()
				else
					@status.ready = true

	check_config: ->
		@log 'checking config', 6
		if @status.core
			config = new Directory(@options.path).getFile('wp-config.php')
			config.exists().then (exists) =>
				@log 'handling config check', 6
				@status.config = exists
				if @status.config
					@log 'config exists', 6
					@check_db()
				else
					@status.ready = true

	check_db: ->
		@log 'checking db', 6
		if @status.config
			@wp.db.check (err) =>
				@log 'handling db check', 6
				@status.database = not err
				if @status.database
					@log 'db connected', 6
					@check_installed()
				else
					@status.ready = true

	check_installed: ->
		@log 'checking installed', 6
		if @status.database
			@wp.core.is_installed (err) =>
				@log 'handling installed check', 6
				@status.installed = not err
				if @status.installed
					@log 'is installed', 6
					@subscriptions.add @plugins = new Plugins(@wp, @logger, @namespace)
					@subscriptions.add @plugins.onNotification ([title,type]) => @emitter.emit 'notification', [title,type]
					@subscriptions.add @plugins.onMessage ([title,type,detail]) => @emitter.emit 'message', [title,type,detail]
					@subscriptions.add @themes = new Themes(@wp, @logger, @namespace)
					@subscriptions.add @themes.onNotification ([title,type]) => @emitter.emit 'notification', [title,type]
					@subscriptions.add @themes.onMessage ([title,type,detail]) => @emitter.emit 'message', [title,type,detail]
					@emitter.emit 'notification', [ 'WP-CLI: Initialized' ]
				@status.ready = true

	hasPlugins: ->
		return @plugins?.plugins.length > 0

	hasThemes: ->
		return @themes?.themes.length > 0

	full_setup: ->
		@emitter.emit 'notification', [ 'WP-CLI: Creating Site', 'info' ]
		@wp.core.download (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Download Error', 'error', err ]
			else
				@emitter.emit 'notification', [ 'WP-CLI: Wordpress Downloaded!' ]

				dbname = @namespace
				dbuser = atom.config.get('wordpress-suite.wpcli.dbuser')
				dbpass = atom.config.get('wordpress-suite.wpcli.dbpass')
				dbhost = atom.config.get('wordpress-suite.wpcli.dbhost')
				@wp.core.config {dbname, dbuser, dbpass, dbhost}, (err,message) =>
					if err
						@emitter.emit 'message', [ 'WP-CLI: Error Creating Config', 'error', err ]
					else
						@emitter.emit 'notification', [ 'WP-CLI: Config Created!', 'success' ]
						@wp.db.create (err,message) =>
							if err
								@emitter.emit 'message', [ 'WP-CLI: Error Creating Database', 'error', err ]
							else
								@emitter.emit 'notification', [ 'WP-CLI: Database Created!', 'success' ]
								url = atom.config.get('wordpress-suite.wpcli.url').replace('%%PROJECTNAME%%', @namespace)
								title = @namespace
								admin_user = atom.config.get('wordpress-suite.wpcli.admin_user')
								admin_password = atom.config.get('wordpress-suite.wpcli.admin_password')
								admin_email = atom.config.get('wordpress-suite.wpcli.admin_email')
								@wp.core.install {url, title, admin_user, admin_password, admin_email}, (err,message) =>
									if err
										@emitter.emit 'message', [ 'WP-CLI: Error Installing Wordpress', 'error', err ]
									else
										@emitter.emit 'notification', [ 'WP-CLI: Wordpress Installed!', 'success' ]
										@emitter.emit 'message', [ 'WP-CLI: Site Created!', 'success' ]
										@check_core()


	download_wordpress: ->
		@emitter.emit 'notification', [ 'WP-CLI: Wordpress Downloading', 'info' ]
		@wp.core.download (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Download Error', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Wordpress Downloaded!', 'success', message ]
				@check_core()

	create_config: ->
		@emitter.emit 'notification', [ 'WP-CLI: Creating Config', 'info' ]
		dbname = @namespace
		dbuser = atom.config.get('wordpress-suite.wpcli.dbuser')
		dbpass = atom.config.get('wordpress-suite.wpcli.dbpass')
		dbhost = atom.config.get('wordpress-suite.wpcli.dbhost')
		@wp.core.config [dbname, dbuser], {dbpass: dbpass, dbhost: dbhost}, (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Creating Config', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Config Created!', 'success', message ]
				@check_config()

	create_database: ->
		@emitter.emit 'notification', [ 'WP-CLI: Creating Database', 'info' ]
		@wp.db.create (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Creating Database', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Database Created!', 'success', message ]
				@check_db()

	install_wordpress: ->
		@emitter.emit 'notification', [ 'WP-CLI: Installing Wordpress', 'info' ]
		url = atom.config.get('wordpress-suite.wpcli.url').replace('%%PROJECTNAME%%', @namespace)
		title = @namespace
		admin_user = atom.config.get('wordpress-suite.wpcli.admin_user')
		admin_password = atom.config.get('wordpress-suite.wpcli.admin_password')
		admin_email = atom.config.get('wordpress-suite.wpcli.admin_email')
		@wp.core.install [url, title, admin_user], {admin_password: admin_password, admin_email: admin_email}, (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Installing Wordpress', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Wordpress Installed!', 'success', message ]
				@check_installed()

	export_database: (dbname, callback) ->
		if not dbname?
			dbname = atom.config.get('wordpress-suite.wpcli.dbname')
		dbpath = "#{@sitePath}/#{dbname}"
		@emitter.emit 'notification', [ 'WP-CLI: Exporting Database', 'info' ]
		@wp.db.export dbpath, (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Exporting Database', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Database Exported!', 'success', message ]
				# callback?

	import_database: (dbname) ->
		if not dbname?
			dbname = atom.config.get('wordpress-suite.wpcli.dbname')
		dbpath = "#{@sitePath}/#{dbname}"
		@export_database 'backup.sql', () =>
			@emitter.emit 'notification', [ 'WP-CLI: Importing Database', 'info' ]
			@wp.db.import dbpath, (err,message) =>
				if err
					@emitter.emit 'message', [ 'WP-CLI: Error Importing Database', 'error', err ]
				else
					@emitter.emit 'message', [ 'WP-CLI: Database Imported!', 'success', message ]

	optimize_database: ->
		@emitter.emit 'notification', [ 'WP-CLI: Optimizing Database', 'info' ]
		@wp.db.optimize (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Optimizing Database', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Database Optimized!', 'success', message ]

	repair_database: ->
		@emitter.emit 'notification', [ 'WP-CLI: Repair Database', 'info' ]
		@wp.db.repair (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Repair Database', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Database Repaired!', 'success', message ]

	clear_everything: ->
		@emitter.emit 'notification', [ 'WP-CLI: Clearing Everything', 'info' ]
		@wp.rewrite.structure ['/%postname%/'], (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Resetting Permalinks', 'error', err ]
			else
				@emitter.emit 'notification', [ 'WP-CLI: Permalinks Reset!', 'success' ]
				@wp.rewrite.flush (err,message) =>
					if err
						@emitter.emit 'message', [ 'WP-CLI: Error Clearing Rewrite Rules', 'error', err ]
					else
						@emitter.emit 'notification', [ 'WP-CLI: Rewrite Rules Cleared!', 'success' ]
						@wp.cache.flush (err,message) =>
							if err
								@emitter.emit 'message', [ 'WP-CLI: Error Clearing Cache', 'error', err ]
							else
								@emitter.emit 'notification', [ 'WP-CLI: Cache Cleared!', 'success' ]
								@wp.transient.delete [], {all: true}, (err,message) =>
									if err
										@emitter.emit 'message', [ 'WP-CLI: Error Clearing Transients', 'error', err ]
									else
										@emitter.emit 'notification', [ 'WP-CLI: Transients Cleared!', 'success' ]

	reset_permalinks: ->
		@emitter.emit 'notification', [ 'WP-CLI: Resetting Permalinks', 'info' ]
		@wp.rewrite.structure ['/%postname%/'], (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Resetting Permalinks', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Permalinks Reset!', 'success', message ]

	clear_rewrite_rules: ->
		@emitter.emit 'notification', [ 'WP-CLI: Clearing Rewrite Rules', 'info' ]
		@wp.rewrite.flush (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Clearing Rewrite Rules', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Rewrite Rules Cleared!', 'success', message ]

	clear_cache: ->
		@emitter.emit 'notification', [ 'WP-CLI: Clearing Cache', 'info' ]
		@wp.cache.flush (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Clearing Cache', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Cache Cleared!', 'success', message ]

	clear_transients: ->
		@emitter.emit 'notification', [ 'WP-CLI: Clearing Transients', 'info' ]
		@wp.transient.delete [], {all: true}, (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Clearing Transients', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Transients Cleared!', 'success', message ]

	regenerate_thumbnails: ->
		@emitter.emit 'notification', [ 'WP-CLI: Regenerating Thumbnails', 'info' ]
		@wp.media.regenerate [], {yes: true}, (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Regenerating Thumbnails', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Thumbnails Regenerated!', 'success', message ]

	import_media: (mediaPath) ->
		@emitter.emit 'notification', [ 'WP-CLI: Importing Media', 'info' ]
		@wp.media.import [mediaPath], (err,message) =>
			if err
				@emitter.emit 'message', [ 'WP-CLI: Error Importing Media', 'error', err ]
			else
				@emitter.emit 'message', [ 'WP-CLI: Media Imported!', 'success', message ]

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
			@sitePath = null
			@wp = null
			@emitter = null
			@subscriptions = null
			@plugins = null
			@themes = null
			@status = {
				yml: null
				exists: null
				initialized: null
				core: null
				config: null
				database: null
				installed: null
				ready: null
			}