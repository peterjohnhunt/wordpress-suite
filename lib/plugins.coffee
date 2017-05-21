{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'

module.exports = class Plugins

	constructor: (wp,logger,namespace) ->
		@logger = logger
		@log    = @logger "site.#{namespace}.wpcli.plugins"
		@wp     = wp

		@directory = null
		@menu = []

		@emitter = new Emitter

		@subscriptions = new CompositeDisposable

		@wp.plugin.path (err,pluginPath) =>
			if not err
				@directory = new Directory(pluginPath.trim())
				@setup()

		new Disposable()

	refresh: ->
		@subscriptions?.dispose()
		@menu = []
		@subscriptions = new CompositeDisposable
		@setup()

	setup: ->
		@wp.plugin.list (err,plugins) =>
			if not err
				for plugin in plugins
					@subscriptions.add atom.commands.add ".project-root",
						"wordpress-suite:site:plugin:add-folder:#{plugin.name}": (event) =>
							name = event.type.split(':').pop()
							atom.project.addPath(@directory.getSubdirectory(name).getPath())
						"wordpress-suite:site:plugin:activate:#{plugin.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.activate(name)
						"wordpress-suite:site:plugin:deactivate:#{plugin.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.deactivate(name)
						"wordpress-suite:site:plugin:update:#{plugin.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.update(name)
						"wordpress-suite:site:plugin:delete:#{plugin.name}": (event) =>
							name = event.type.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.delete(name)

					submenu = []

					submenu.push({ label: 'Add Folder', command: "wordpress-suite:site:plugin:add-folder:#{plugin.name}", shouldDisplay: ->
						name = @command.split(':').pop()
						site = atom.wordpressSuite.getSelectedSite()
						plugin = site.wpcli.plugins.directory.getSubdirectory(name)
						return not site.hasPath("#{plugin.getPath()}")
					})

					if plugin.status is 'inactive'
						submenu.push({ label: 'Activate', command: "wordpress-suite:site:plugin:activate:#{plugin.name}" })

					if plugin.status is 'active'
						submenu.push({ label: 'Deactivate', command: "wordpress-suite:site:plugin:deactivate:#{plugin.name}" })

					if plugin.update is 'available'
						submenu.push({ label: 'Update', command: "wordpress-suite:site:plugin:update:#{plugin.name}" })

					submenu.push({ label: 'Delete', command: "wordpress-suite:site:plugin:delete:#{plugin.name}" })
					submenu.push({ type: 'separator' })
					submenu.push({ label: "Version: #{plugin.version}", enabled: false })
					submenu.push({ label: "Status: #{plugin.status}", enabled: false })
					submenu.push({ label: "Update: #{plugin.update}", enabled: false })

					@menu.push({ label: plugin.name, submenu: submenu })

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Plugins', submenu: [], created: (-> @submenu = atom.wordpressSuite.getSelectedSite().wpcli.plugins.getMenu()), shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.hasPlugins())}] }] }

	getMenu: ->
		return @menu

	activate: (name) ->
		@emitter.emit 'notification', [ "Activating #{name}", 'info' ]
		@wp.plugin.activate name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Activating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Activated", 'success', message ]
				@refresh()

	deactivate: (name) ->
		@emitter.emit 'notification', [ "Deactivating #{name}", 'info' ]
		@wp.plugin.deactivate name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Deactivating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Deactivated", 'success', message ]
				@refresh()

	update: (name) ->
		@emitter.emit 'notification', [ "Updating #{name}", 'info' ]
		@wp.plugin.update name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Updating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Updated", 'success', message ]
				@refresh()

	delete: (name) ->
		@emitter.emit 'notification', [ "Deleting #{name}", 'info' ]
		@wp.plugin.delete name, (err,message) =>
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