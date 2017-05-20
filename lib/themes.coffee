{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'

module.exports = class Themes

	constructor: (wp,logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.wpcli.themes"
		@wp     = wp

		@directory = null
		@themes = []

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@wp.theme.path (err,themePath) =>
			if not err
				@directory = new Directory(themePath.trim())
				@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@themes = []
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		@wp.theme.list (err,themes) =>
			if not err
				@themes = themes

				menu = []
				for theme in @themes

					@subscriptions.add atom.commands.add ".project-root",
						"wordpress-suite:site:theme:add-folder:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							atom.project.addPath(@directory.getSubdirectory(name).getPath())
						"wordpress-suite:site:theme:activate:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.themes.activate(name)
						"wordpress-suite:site:theme:deactivate:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.themes.deactivate(name)
						"wordpress-suite:site:theme:update:#{theme.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.themes.update(name)

					menu.push({ label: theme.name, submenu: [
						{ label: 'Add Folder', command: "wordpress-suite:site:theme:add-folder:#{theme.name}", shouldDisplay: ->
							name = @command.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite()
							theme = site.wpcli.themes.directory.getSubdirectory(name)
							return not site.hasPath("#{theme.getPath()}")
						}
						{ label: 'Activate', command: "wordpress-suite:site:theme:activate:#{theme.name}", shouldDisplay: ->
							name = @command.split(':').pop()
							return atom.wordpressSuite.getSelectedSite().wpcli.themes.get(name).status is 'inactive'
						}
						{ label: 'Deactivate', command: "wordpress-suite:site:theme:deactivate:#{theme.name}", shouldDisplay: ->
							name = @command.split(':').pop()
							return atom.wordpressSuite.getSelectedSite().wpcli.themes.get(name).status is 'active'
						}
						{ label: 'Update', command: "wordpress-suite:site:theme:update:#{theme.name}", shouldDisplay: ->
							name = @command.split(':').pop()
							return atom.wordpressSuite.getSelectedSite().wpcli.themes.get(name).update is 'available'
						}
					], shouldDisplay: -> atom.wordpressSuite.getSelectedSite().wpcli.themes.get(@label) })

				@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Themes', submenu: menu, shouldDisplay: -> atom.wordpressSuite.getSelectedSite().wpcli.hasThemes() }] }] }

	activate: (name) ->
		@emitter.emit 'notification', [ "Activating #{name}", 'info' ]
		@wp.theme.activate name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Activating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Activated", 'success', message ]
				@refresh()

	deactivate: (name) ->
		@emitter.emit 'notification', [ "Deactivating #{name}", 'info' ]
		@wp.theme.deactivate name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Deactivating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Deactivated", 'success', message ]
				@refresh()

	update: (name) ->
		@emitter.emit 'notification', [ "Updating #{name}", 'info' ]
		@wp.theme.update name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Updating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Updated", 'success', message ]
				@refresh()

	get: (name) ->
		for theme in @themes
			if theme.name is name
				return theme

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
			@themes = null