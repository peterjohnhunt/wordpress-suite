{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'

module.exports = class Info

	constructor: (wp,logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.wpcli.info"
		@wp     = wp

		@emitter = new Emitter

		@menu = {
			posttypes: null
			taxonomies: null
			roles: null
			separator: { type:'separator' }
			name: null
			url: null
			version: null
		}

		@subscriptions = new CompositeDisposable

		@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@menu = {
			posttypes: null
			taxonomies: null
			roles: null
			separator: { type:'separator' }
			name: null
			url: null
			version: null
		}
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		@name()
		@url()
		@version()
		@posttypes()
		@taxonomies()
		@roles()

	name: ->
		@wp.option.get 'blogname', (err,name) =>
			if not err
				@menu.name = { label: "Name: #{name}", enabled: false }

	url: ->
		@wp.option.get 'siteurl', (err,url) =>
			if not err
				@menu.url = { label: "URL: #{url}", enabled: false }

	version: ->
		@wp.core.version (err,version) =>
			if not err
				@menu.version = { label: "Version: #{version}", enabled: false }

	posttypes: ->
		@wp.post_type.list (err,posttypes) =>
			if not err
				submenu = []
				for posttype in posttypes
					submenu.push({label:posttype.name,enabled:false})
				@menu.posttypes = { label: 'Post Types', enabled: false, submenu:submenu }

	taxonomies: ->
		@wp.taxonomy.list (err,taxonomies) =>
			if not err
				submenu = []
				for taxonomy in taxonomies
					submenu.push({label:taxonomy.name,enabled:false})
				@menu.taxonomies = { label: 'Taxonomies', enabled: false, submenu:submenu }

	roles: ->
		@wp.role.list (err,roles) =>
			if not err
				submenu = []
				for role in roles
					submenu.push({label:role.name,enabled:false})
				@menu.roles = { label: 'Roles', enabled: false, submenu:submenu }

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Site', submenu: [], created: (-> @submenu = atom.wordpressSuite.getSelectedSite().wpcli.info.getMenu()), shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.hasInfo())}] }] }

	getMenu: ->
		return Object.keys(@menu).map((key) => return @menu[key]).filter((n) => n)

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
			@menu = {
				name: null
				url: null
				version: null
				separator: { type:'separator' }
				posttypes: null
				taxonomies: null
				roles: null
			}