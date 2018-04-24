{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'
ThemesListView = require '../views/themes-list'

module.exports = class Themes

	constructor: (wp,logger,namespace) ->
		@namespace = namespace
		@logger = logger
		@log    = @logger "site.#{@namespace}.wpcli.themes"
		@wp     = wp

		@directory = null
		@menu = []
		@enabled = atom.config.get('wordpress-suite.features.themes')

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@wp.theme.path (err,themePath) =>
			if not err
				@directory = new Directory(themePath.trim())
				@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@menu = []
		@subscriptions = new CompositeDisposable
		@setup()

	enable: ->
		@enabled = true
		@emitter.emit 'notification', [ 'WP-CLI Plugins Enabled', 'success' ]
		@refresh()

	disable: ->
		@enabled = false
		@emitter.emit 'notification', [ 'WP-CLI Plugins Disabled', 'warning' ]
		@refresh()

	setup: ->
		if @enabled
			@wp.theme.list (err,themes) =>
				if not err
					@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:theme:add:#{@namespace}": (event) => themesList = new ThemesListView
					@menu.push({ label: 'Add Theme', command: "wordpress-suite:site:theme:add:#{@namespace}" })
					@menu.push({ type:'separator' })

					for theme in themes
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:theme:add-folder:#{@namespace}:#{theme.name}": (event) =>
								name = event.type.split(':').pop()
								atom.project.addPath(@directory.getSubdirectory(name).getPath())
							"wordpress-suite:site:theme:activate:#{@namespace}:#{theme.name}": (event) =>
								name = event.type.split(':').pop()
								site = atom.wordpressSuite.getSelectedSite().wpcli.themes.activate(name)
							"wordpress-suite:site:theme:update:#{@namespace}:#{theme.name}": (event) =>
								name = event.type.split(':').pop()
								site = atom.wordpressSuite.getSelectedSite().wpcli.themes.update(name)
							"wordpress-suite:site:theme:delete:#{@namespace}:#{theme.name}": (event) =>
								name = event.type.split(':').pop()
								site = atom.wordpressSuite.getSelectedSite().wpcli.themes.delete(name)

						submenu = []

						submenu.push({ label: 'Add Folder', command: "wordpress-suite:site:theme:add-folder:#{@namespace}:#{theme.name}", shouldDisplay: ->
							name = @command.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite()
							theme = site.wpcli.themes.directory.getSubdirectory(name)
							return not site.hasPath("#{theme.getPath()}")
						})

						if theme.status is 'inactive'
							submenu.push({ label: 'Activate', command: "wordpress-suite:site:theme:activate:#{@namespace}:#{theme.name}" })
							submenu.push({ label: 'Delete', command: "wordpress-suite:site:theme:delete:#{@namespace}:#{theme.name}" })

						if theme.update is 'available'
							submenu.push({ label: 'Update', command: "wordpress-suite:site:theme:update:#{@namespace}:#{theme.name}" })

						submenu.push({ type: 'separator' })
						submenu.push({ label: "Version: #{theme.version}", enabled: false })
						submenu.push({ label: "Status: #{theme.status}", enabled: false })
						submenu.push({ label: "Update: #{theme.update}", enabled: false })

						@menu.push({ label: theme.name, submenu: submenu })

					@menu.push({ type:'separator' })
					submenu = []

					if themes.filter((p) -> return p.update is 'available').length > 0
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:theme:update-all:#{@namespace}": (event) => atom.wordpressSuite.getSelectedSite().wpcli.themes.update_all()
						submenu.push({ label: 'Update', command: "wordpress-suite:site:theme:update-all:#{@namespace}" })

					@menu.push({ label: 'All Themes', submenu: submenu })
				@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:themes:disable:#{@namespace}": (event) => site = atom.wordpressSuite.getSelectedSite().wpcli.themes.disable()
				@menu.push({ label: 'Disable', command: "wordpress-suite:site:themes:disable:#{@namespace}" })
		else
			@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:themes:enable:#{@namespace}": (event) => site = atom.wordpressSuite.getSelectedSite().wpcli.themes.enable()
			@menu.push({ label: 'Enable', command: "wordpress-suite:site:themes:enable:#{@namespace}" })

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Themes', submenu: [], created: (-> @submenu = atom.wordpressSuite.getSelectedSite().wpcli.themes.getMenu()), shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.themes)}] }] }

	getMenu: ->
		if @menu.length > 0
			return @menu
		return [{ label: "Loading...", enabled: false }]

	activate: (name) ->
		@emitter.emit 'notification', [ "Activating #{name}", 'info' ]
		@wp.theme.activate name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Activating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Activated", 'success', message ]
				@refresh()

	update: (name) ->
		@emitter.emit 'notification', [ "Updating #{name}", 'info' ]
		@wp.theme.update name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Updating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Updated", 'success', "Theme '#{name}' updated.\nSuccess: Updated 1 of 1 themes." ]
				@refresh()

	update_all: ->
		@emitter.emit 'notification', [ "Updating All Themes", 'info' ]
		@wp.theme.update {all:true}, (err,themes) =>
			if err
				@emitter.emit 'message', [ "Error Updating All Themes", 'error', err ]
			else
				names = themes.map((t) => return t.name)
				@emitter.emit 'message', [ "All Themes Updated", 'success', "Themes '#{names.join(', ')}' updated.\nSuccess: Updated #{names.length} of #{names.length} themes." ]
				@refresh()

	delete: (name) ->
		@emitter.emit 'notification', [ "Deleting #{name}", 'info' ]
		@wp.theme.delete name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Deleting #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Deleted", 'success', message ]
				@refresh()

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
			@enabled = null