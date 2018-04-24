{CompositeDisposable, Emitter, Disposable, Directory} = require 'atom'
PluginsListView = require '../views/plugins-list'

module.exports = class Plugins

	constructor: (wp,logger,namespace) ->
		@namespace = namespace
		@logger = logger
		@log    = @logger "site.#{@namespace}.wpcli.plugins"
		@wp     = wp

		@directory = null
		@menu = []
		@enabled = atom.config.get('wordpress-suite.features.plugins')

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
			@wp.plugin.list (err,plugins) =>
				if not err
					@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:plugin:add:#{@namespace}": (event) => pluginsList = new PluginsListView
					@menu.push({ label: 'Add Plugin', command: "wordpress-suite:site:plugin:add:#{@namespace}" })
					@menu.push({ type:'separator' })

					for plugin in plugins
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:plugin:add-folder:#{@namespace}:#{plugin.name}": (event) =>
								name = event.type.split(':').pop()
								atom.project.addPath(@directory.getSubdirectory(name).getPath())
							"wordpress-suite:site:plugin:activate:#{@namespace}:#{plugin.name}": (event) =>
								name = event.type.split(':').pop()
								atom.wordpressSuite.getSelectedSite().wpcli.plugins.activate(name)
							"wordpress-suite:site:plugin:deactivate:#{@namespace}:#{plugin.name}": (event) =>
								name = event.type.split(':').pop()
								atom.wordpressSuite.getSelectedSite().wpcli.plugins.deactivate(name)
							"wordpress-suite:site:plugin:update:#{@namespace}:#{plugin.name}": (event) =>
								name = event.type.split(':').pop()
								atom.wordpressSuite.getSelectedSite().wpcli.plugins.update(name)
							"wordpress-suite:site:plugin:delete:#{@namespace}:#{plugin.name}": (event) =>
								name = event.type.split(':').pop()
								atom.wordpressSuite.getSelectedSite().wpcli.plugins.delete(name)

						submenu = []

						submenu.push({ label: 'Add Folder', command: "wordpress-suite:site:plugin:add-folder:#{@namespace}:#{plugin.name}", shouldDisplay: ->
							name = @command.split(':').pop()
							site = atom.wordpressSuite.getSelectedSite()
							plugin = site.wpcli.plugins.directory.getSubdirectory(name)
							return not site.hasPath("#{plugin.getPath()}")
						})

						if plugin.status is 'inactive'
							submenu.push({ label: 'Activate', command: "wordpress-suite:site:plugin:activate:#{@namespace}:#{plugin.name}" })

						if plugin.status is 'active'
							submenu.push({ label: 'Deactivate', command: "wordpress-suite:site:plugin:deactivate:#{@namespace}:#{plugin.name}" })

						if plugin.update is 'available'
							submenu.push({ label: 'Update', command: "wordpress-suite:site:plugin:update:#{@namespace}:#{plugin.name}" })

						submenu.push({ label: 'Delete', command: "wordpress-suite:site:plugin:delete:#{@namespace}:#{plugin.name}" })
						submenu.push({ type: 'separator' })
						submenu.push({ label: "Version: #{plugin.version}", enabled: false })
						submenu.push({ label: "Status: #{plugin.status}", enabled: false })
						submenu.push({ label: "Update: #{plugin.update}", enabled: false })

						@menu.push({ label: plugin.name, submenu: submenu })

					@menu.push({ type:'separator' })
					submenu = []

					if plugins.filter((p) -> return p.update is 'available').length > 0
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:plugin:update-all:#{@namespace}": (event) => atom.wordpressSuite.getSelectedSite().wpcli.plugins.update_all()
						submenu.push({ label: 'Update', command: "wordpress-suite:site:plugin:update-all:#{@namespace}" })

					if plugins.filter((p) -> return p.status is 'inactive').length > 0
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:plugin:activate-all:#{@namespace}": (event) => atom.wordpressSuite.getSelectedSite().wpcli.plugins.activate_all()
						submenu.push({ label: 'Activate', command: "wordpress-suite:site:plugin:activate-all:#{@namespace}" })

					if plugins.filter((p) -> return p.status is 'active').length > 0
						@subscriptions.add atom.commands.add ".project-root",
							"wordpress-suite:site:plugin:deactivate-all:#{@namespace}": (event) => atom.wordpressSuite.getSelectedSite().wpcli.plugins.deactivate_all()
						submenu.push({ label: 'Deactivate', command: "wordpress-suite:site:plugin:deactivate-all:#{@namespace}" })

					@menu.push({ label: 'All Plugins', submenu: submenu })

				@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:plugins:disable:#{@namespace}": (event) => site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.disable()
				@menu.push({ label: 'Disable', command: "wordpress-suite:site:plugins:disable:#{@namespace}" })
		else
			@subscriptions.add atom.commands.add ".project-root", "wordpress-suite:site:plugins:enable:#{@namespace}": (event) => site = atom.wordpressSuite.getSelectedSite().wpcli.plugins.enable()
			@menu.push({ label: 'Enable', command: "wordpress-suite:site:plugins:enable:#{@namespace}" })

		@subscriptions.add atom.contextMenu.add { ".project-root": [{ label: 'Wordpress Suite', submenu: [{ label: 'Plugins', submenu: [], created: (-> @submenu = atom.wordpressSuite.getSelectedSite().wpcli.plugins.getMenu()), shouldDisplay: (-> atom.wordpressSuite.getSelectedSite().wpcli.plugins)}] }] }

	getMenu: ->
		if @menu.length > 0
			return @menu
		return [{ label: "Loading...", enabled: false }]

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
		@wp.plugin.update name, (err,plugin) =>
			if err
				@emitter.emit 'message', [ "Error Updating #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Updated", 'success', "Plugin '#{name}' updated.\nSuccess: Updated 1 of 1 plugins." ]
				@refresh()

	install: (name) ->
		@emitter.emit 'notification', [ "Installing #{name}", 'info' ]
		@wp.plugin.install name, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Installing #{name}", 'error', err ]
			else
				@emitter.emit 'message', [ "#{name} Installed", 'success', message ]
				@refresh()

	update_all: ->
		@emitter.emit 'notification', [ "Updating All Plugins", 'info' ]
		@wp.plugin.update {all:true}, (err,plugins) =>
			if err
				@emitter.emit 'message', [ "Error Updating All Plugins", 'error', err ]
			else
				names = plugins.map((p) => return p.name)
				@emitter.emit 'message', [ "All Plugins Updated", 'success', "Plugins '#{names.join(', ')}' updated.\nSuccess: Updated #{names.length} of #{names.length} plugins." ]
				@refresh()

	activate_all: ->
		@emitter.emit 'notification', [ "Activating All Plugins", 'info' ]
		@wp.plugin.activate {all:true}, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Activating All Plugins", 'error', err ]
			else
				@emitter.emit 'message', [ "All Plugins Activated", 'success', message ]
				@refresh()

	deactivate_all: ->
		@emitter.emit 'notification', [ "Deactivating All Plugins", 'info' ]
		@wp.plugin.deactivate {all:true}, (err,message) =>
			if err
				@emitter.emit 'message', [ "Error Deactivating All Plugins", 'error', err ]
			else
				@emitter.emit 'message', [ "All Plugins Deactivated", 'success', message ]
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
			@enabled = null