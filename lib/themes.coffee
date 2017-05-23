{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'

module.exports = class Themes

	constructor: (wp,logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.wpcli.themes"
		@wp     = wp

		@directory = null
		@menu = []

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

	setup: ->
		@wp.theme.list (err,themes) =>
			if not err
				for theme in themes
					@subscriptions.add atom.commands.add ".project-root",
						"wordpress-suite:site:theme:add-folder:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							atom.project.addPath(@directory.getSubdirectory(name).getPath())
						"wordpress-suite:site:theme:activate:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.themes.activate(name)
						"wordpress-suite:site:theme:update:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.themes.update(name)
						"wordpress-suite:site:theme:delete:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.themes.delete(name)

					submenu = []

					submenu.push({ label: 'Add Folder', command: "wordpress-suite:site:theme:add-folder:#{theme.name}", shouldDisplay: ->
						name = @command.split(':').pop()
						site = atom.wordpressSuite.getSelectedSite()
						theme = site.wpcli.themes.directory.getSubdirectory(name)
						return not site.hasPath("#{theme.getPath()}")
					})

					if theme.status is 'inactive'
						submenu.push({ label: 'Activate', command: "wordpress-suite:site:theme:activate:#{theme.name}" })
						submenu.push({ label: 'Delete', command: "wordpress-suite:site:theme:delete:#{theme.name}" })

					if theme.update is 'available'
						submenu.push({ label: 'Update', command: "wordpress-suite:site:theme:update:#{theme.name}" })

					submenu.push({ type: 'separator' })
					submenu.push({ label: "Version: #{theme.version}", enabled: false })
					submenu.push({ label: "Status: #{theme.status}", enabled: false })
					submenu.push({ label: "Update: #{theme.update}", enabled: false })

					@menu.push({ label: theme.name, submenu: submenu })

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Themes', submenu: [], created: (-> @submenu = atom.wordpressSuite.getSelectedSite().wpcli.themes.getMenu()), shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.hasThemes())}] }] }

	getMenu: ->
		return @menu

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
				@emitter.emit 'message', [ "#{name} Updated", 'success', message ]
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